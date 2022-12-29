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

class CameraViewController: UIViewController {
    
    @IBOutlet weak var cameraPreview: UIView!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var modeImageView: UIImageView!
    
    var peripheral: Peripheral?
    var cameraStatus: CameraStatus?
   
    let child = SpinnerViewController()
    var mediaPlayer = VLCMediaPlayer()
    
    let streamURL = URL(string: "udp://@0.0.0.0:8554")
    
    @IBAction func didTapImageView(_ sender: UITapGestureRecognizer) {
        enableWifi()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        swipeUp.direction = .up
        self.view.addGestureRecognizer(swipeUp)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        swipeDown.direction = .down
        self.view.addGestureRecognizer(swipeDown)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        swipeRight.direction = .right
        self.view.addGestureRecognizer(swipeRight)
        
        recordButton.addTarget(self, action: #selector(toggleShutter), for: .touchUpInside)
        print(peripheral?.name ?? "?")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getCameraStatus()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let peripheral = peripheral {
            NSLog("Disconnecting to \(peripheral.name)..")
            peripheral.disconnect()
        }
    }
    
    @objc func handleGesture(gesture: UISwipeGestureRecognizer) -> Void {
        if gesture.direction == UISwipeGestureRecognizer.Direction.right {
            leftKey()
        }
        else if gesture.direction == UISwipeGestureRecognizer.Direction.left {
            rightKey()
        }
        else if gesture.direction == UISwipeGestureRecognizer.Direction.up {
            upKey()
        }
        else if gesture.direction == UISwipeGestureRecognizer.Direction.down {
            downKey()
        }
    }
    
    func updateDisplay() {
        switch cameraStatus!.mode {
        case 0xE8:
            //Video
            print("Video")
            self.modeImageView.image = UIImage(systemName:"video")
            if (cameraStatus!.busy) {
                self.recordButton.setTitle("Stop Recording", for: .normal)
            } else {
                self.recordButton.setTitle("Start Recording", for: .normal)
            }
        case 0xE9:
            //Photo
            print("Photo")
            self.modeImageView.image = UIImage(systemName:"camera")
            self.recordButton.setTitle("Take Photo", for: .normal)
        case 0xEA:
            //Timelapse
            print("Timelapse")
            self.modeImageView.image = UIImage(systemName:"timelapse")
            if (cameraStatus!.busy) {
                self.recordButton.setTitle("Stop Recording", for: .normal)
            } else {
                self.recordButton.setTitle("Start Recording", for: .normal)
            }
        default:
            //Unknown
            print("Unknown")
            self.modeImageView.image = nil
        }
        
    }
    
    @objc func toggleShutter() {
        NSLog("toggleShutter()")
        if (cameraStatus!.busy){
            NSLog("toggleShutter() - Off")
            peripheral?.setCommand(command: Data([0x01, 0x01, 0x00])) { error in
                if error != nil {
                    print("\(error!)")
                    self.getCameraStatus()
                    return
                } else {
                    self.cameraStatus?.busy.toggle()
                }
                return
            }
        } else {
            NSLog("toggleShutter() - On")
            peripheral?.setCommand(command: Data([0x01, 0x01, 0x01])) { error in
                if error != nil {
                    print("\(error!)")
                    self.getCameraStatus()
                    return
                } else {
                    self.cameraStatus?.busy.toggle()
                }
                return
            }
        }
    }
    
    func enableWifi() {
        NSLog("Enabling WiFi...")
        self.peripheral?.setCommand(command: Data([0x17, 0x01, 0x01])) { error in
            if error != nil {
                print("\(error!)")
                return
            }
            
            NSLog("Requesting WiFi settings...")
            self.peripheral?.requestWiFiSettings { result in
                switch result {
                case .success(let wifiSettings):
                    print("WiFi settings: \(wifiSettings)")
                    self.joinWiFi(with: wifiSettings.SSID, password: wifiSettings.password)
                case .failure(let error):
                    print("\(error)")
                }
            }
            return
        }
    }
    
    func getCameraStatus() {
        peripheral?.requestCameraStatus() { result in
            switch result {
            case .success(let status):
                print("Mode Value: \(status)")
                self.cameraStatus = status
                self.updateDisplay()
            case .failure(let error):
                print("\(error)")
            }
        }
    }
    
 
    override var keyCommands: [UIKeyCommand]? {
        let commands = [
            UIKeyCommand(input: "\u{d}", modifierFlags:[], action: #selector(enterKey)),
            UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags:[], action: #selector(upKey)),
            UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags:[], action: #selector(downKey)),
            UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags:[], action: #selector(leftKey)),
            UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags:[], action: #selector(leftKey)),
            UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags:[], action: #selector(escapeKey))
        ]
        if #available(iOS 15, *) {
            commands.forEach { $0.wantsPriorityOverSystemBehavior = true }
        }
        return commands
    }
    
    @objc func enterKey() {
        toggleShutter()
    }
    
    @objc func upKey() {
        if (cameraStatus?.mode == 0x00) {
            getCameraStatus()
        } else if (cameraStatus?.mode == 0xEA) {
            cameraStatus?.mode = 0xE8
            peripheral?.setCommand(command: Data([0x3E,0x02,0x03,cameraStatus!.mode])) { error in
                if error != nil {
                    print("\(error!)")
                    return
                } else {
                    self.getCameraStatus()
                }
            }
        } else {
            let mode = cameraStatus?.mode
            cameraStatus?.mode = mode! + 1
            peripheral?.setCommand(command: Data([0x3E,0x02,0x03,cameraStatus!.mode])) { error in
                if error != nil {
                    print("\(error!)")
                    return
                } else {
                    self.getCameraStatus()
                }
            }
        }
    }
    
    @objc func downKey() {
        if (cameraStatus?.mode == 0x00) {
            getCameraStatus()
        } else if (cameraStatus?.mode == 0xE8) {
            cameraStatus?.mode = 0xEA
            peripheral?.setCommand(command: Data([0x3E,0x02,0x03,cameraStatus!.mode])) { error in
                if error != nil {
                    print("\(error!)")
                    return
                } else {
                    self.getCameraStatus()
                }
            }
        } else {
            let mode = cameraStatus?.mode
            cameraStatus?.mode = mode! - 1
            peripheral?.setCommand(command: Data([0x3E,0x02,0x03,cameraStatus!.mode])) { error in
                if error != nil {
                    print("\(error!)")
                    return
                } else {
                    self.getCameraStatus()
                }
            }
        }
    }
    
    @objc func leftKey() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func rightKey() {}
    
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
    
    private func startPreview() {
        mediaPlayer.delegate = self
        mediaPlayer.drawable = cameraPreview
        mediaPlayer.media = VLCMedia(url: streamURL!)
        
        let child = SpinnerViewController()
        // add the spinner view controller
        addChild(child)
        child.view.frame = view.frame
        
        let config = URLSessionConfiguration.ephemeral
        config.waitsForConnectivity = true
        let sesh = URLSession(configuration: config)
        let startURL = URL(string: "http://10.5.5.9:8080/gopro/camera/stream/start")!
        var request = URLRequest(url: startURL)
        sesh.dataTask(with: request) { (data, response, error) in
            print("HTTP: Response:\(response)")

            var messageHexString = ""
            for i in 0 ..< data!.count {
                messageHexString += String(format: "%02X", data![i])
            }
            NSLog(messageHexString)
            self.getCameraStatus()
            self.mediaPlayer.play()
        }.resume()
        print("after request")
    }
    
    private func joinWiFi(with SSID: String, password: String) {
        NSLog("Joining WiFi \(SSID)...")
        let configuration = NEHotspotConfiguration(ssid: SSID, passphrase: password, isWEP: false)
        NEHotspotConfigurationManager.shared.removeConfiguration(forSSID: SSID)
        configuration.joinOnce = false
        NEHotspotConfigurationManager.shared.apply(configuration) { error in
            guard let error = error else { NSLog("Joining WiFi succeeded"); self.startPreview(); return }
            NSLog("Joining WiFi failed: \(error)")
        }
    }
}

extension CameraViewController: VLCMediaPlayerDelegate {

    func mediaPlayerStateChanged(_ aNotification: Notification) {
        print("State: \(mediaPlayer.state)")

        child.willMove(toParent: nil)
        child.view.removeFromSuperview()
        child.removeFromParent()
        
        if mediaPlayer.state == .stopped {
            
        }
    }
}
