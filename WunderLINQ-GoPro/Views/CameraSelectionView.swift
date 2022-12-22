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
import CoreBluetooth

struct CameraSelectionView: View {
    @ObservedObject var scanner = CentralManager()
    @State private var peripheral: Peripheral?
    @State private var showCameraView = false
    var body: some View {
        NavigationView {
            VStack {
                NavigationLink(destination: CameraView(peripheral: peripheral), isActive: $showCameraView) { EmptyView() }
                List {
                    ForEach(scanner.peripherals, id: \.self) { peripheral in
                        ZStack {
                            HStack() {
                                Text(peripheral.name)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .renderingMode(.template)
                                    .foregroundColor(.gray)
                            }
                            Button(action: {
                                NSLog("Connecting to \(peripheral.name)..")
                                peripheral.connect { error in
                                    if error != nil {
                                        NSLog("Error connecting to \(peripheral.name)")
                                        return
                                    }
                                    NSLog("Connected to \(peripheral.name)!")
                                    showCameraView = true
                                    self.peripheral = peripheral
                                }
                            }, label: {
                                EmptyView()
                            })
                        }
                    }
                }
            }
            .onAppear {
                if let peripheral = peripheral {
                    NSLog("Disconnecting to \(peripheral.name)..")
                    peripheral.disconnect()
                }
                NSLog("Scanning for GoPro cameras..")
                scanner.start(withServices: [CBUUID(string: "FEA6")])
            }
            .onDisappear { scanner.stop() }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Select Camera").fontWeight(.bold)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}


struct CameraSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        CameraSelectionView()
    }
}
