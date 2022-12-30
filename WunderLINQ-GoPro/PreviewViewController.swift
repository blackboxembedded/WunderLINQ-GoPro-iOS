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

import Foundation
import UIKit
import NetworkExtension
import CoreLocation

class PreviewViewController: UIViewController {
    @IBOutlet weak var previewView: UIView!
    
    var peripheral: Peripheral?
    var wifiSettings: WiFiSettings?
    
    var child = SpinnerViewController()
    var mediaPlayer = VLCMediaPlayer()
    var locationManager = CLLocationManager()
    
    let startURL = URL(string: "http://10.5.5.9:8080/gopro/camera/stream/start")!
    let streamURL = URL(string: "udp://@0.0.0.0:8554")
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        swipeRight.direction = .right
        self.view.addGestureRecognizer(swipeRight)
        
        mediaPlayer.delegate = self
        mediaPlayer.drawable = previewView
        mediaPlayer.media = VLCMedia(url: streamURL!)
        
        self.child = SpinnerViewController()
        addChild(child)
        child.view.frame = view.frame
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.joinWiFi(with: wifiSettings!.SSID, password: wifiSettings!.password)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override var keyCommands: [UIKeyCommand]? {
        let commands = [
            UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags:[], action: #selector(leftKey)),
            UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags:[], action: #selector(escapeKey))
        ]
        if #available(iOS 15, *) {
            commands.forEach { $0.wantsPriorityOverSystemBehavior = true }
        }
        return commands
    }
    
    @objc func leftKey() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func escapeKey() {
        guard let url = URL(string: "wunderlinq://") else {
            return
        }
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    @objc func handleGesture(gesture: UISwipeGestureRecognizer) -> Void {
        if gesture.direction == UISwipeGestureRecognizer.Direction.right {
            leftKey()
        }
    }
    
    private func joinWiFi(with SSID: String, password: String) {
        NSLog("Joining WiFi \(SSID)...")
        self.locationManager.requestWhenInUseAuthorization()
        let configuration = NEHotspotConfiguration(ssid: SSID, passphrase: password, isWEP: false)
        NEHotspotNetwork.fetchCurrent { network in
            print("Current SSID: \(network?.ssid)")
              if network?.ssid == configuration.ssid {
                  NSLog("Already connected to WiFi \(SSID)...")
                  self.startPreview()
              } else {
                  NEHotspotConfigurationManager.shared.removeConfiguration(forSSID: SSID)
                  configuration.joinOnce = false
                  NEHotspotConfigurationManager.shared.apply(configuration) { error in
                      guard let error = error else { NSLog("Joining WiFi succeeded"); self.startPreview(); return }
                      NSLog("Joining WiFi failed: \(error)")
                  }
              }
        }
    }
    
    private func startPreview() {
        let config = URLSessionConfiguration.ephemeral
        config.waitsForConnectivity = true
        let sesh = URLSession(configuration: config)
        let request = URLRequest(url: startURL)
        sesh.dataTask(with: request) { (data, response, error) in
            NSLog("HTTP: Response:\(response)")
            self.mediaPlayer.play()
        }.resume()
    }
}

extension PreviewViewController: VLCMediaPlayerDelegate {

    func mediaPlayerStateChanged(_ aNotification: Notification) {
        NSLog("State: \(mediaPlayer.state)")

        child.willMove(toParent: nil)
        child.view.removeFromSuperview()
        child.removeFromParent()
        
        if mediaPlayer.state == .stopped {
            
        }
    }
}