/*
WunderLINQ Client Application
Copyright (C) 2020  Keith Conger, Black Box Embedded, LLC
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

import SwiftUI
import NetworkExtension

struct CameraView: View {
    var peripheral: Peripheral?
    var body: some View {
        Button(action: {
            NSLog("Enabling WiFi...")
            peripheral?.enableWiFi { error in
                if error != nil {
                    print("\(error!)")
                    return
                }

                NSLog("Requesting WiFi settings...")
                peripheral?.requestWiFiSettings { result in
                    switch result {
                    case .success(let wifiSettings):
                        joinWiFi(with: wifiSettings.SSID, password: wifiSettings.password)
                    case .failure(let error):
                        print("\(error)")
                    }
                }
            }
        }, label: {
            Text("Enable Wi-Fi")
        })
        Button(action: {
            NSLog("Shutter On...")
            peripheral?.setShutterOn { error in
                if error != nil {
                    print("\(error!)")
                    return
                }
            }
        }, label: {
            Text("Shutter On")
        })
        Button(action: {
            NSLog("Shutter Off...")
            peripheral?.setShutterOff { error in
                if error != nil {
                    print("\(error!)")
                    return
                }
            }
        }, label: {
            Text("Shutter Off")
        })
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(peripheral?.name ?? "").fontWeight(.bold)
            }
        }
        .withHostingWindow { window in
            window?.rootViewController = KeyController(rootView: CameraView())
        }
    }

    private func joinWiFi(with SSID: String, password: String) {
        NSLog("Joining WiFi \(SSID)...")
        let configuration = NEHotspotConfiguration(ssid: SSID, passphrase: password, isWEP: false)
        NEHotspotConfigurationManager.shared.removeConfiguration(forSSID: SSID)
        configuration.joinOnce = false
        NEHotspotConfigurationManager.shared.apply(configuration) { error in
            guard let error = error else { NSLog("Joining WiFi succeeded"); return }
            NSLog("Joining WiFi failed: \(error)")
        }
    }
}

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView()
    }
}

extension View {
    func withHostingWindow(_ callback: @escaping (UIWindow?) -> Void) -> some View {
        self.background(HostingWindowFinder(callback: callback))
    }
}

struct HostingWindowFinder: UIViewRepresentable {
    var callback: (UIWindow?) -> ()

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async { [weak view] in
            self.callback(view?.window)
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
    }
}
