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
    var lastCommand: Data?
   
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
        recordButton.isHidden = true
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
        print("updateDisplay()")
        switch cameraStatus!.mode {
        case 0xE8:
            //Video
            self.modeImageView.image = UIImage(systemName:"video")
            if (cameraStatus!.busy) {
                self.recordButton.setTitle("Stop Recording", for: .normal)
            } else {
                self.recordButton.setTitle("Start Recording", for: .normal)
            }
            self.recordButton.isHidden = false
        case 0xE9:
            //Photo
            self.modeImageView.image = UIImage(systemName:"camera")
            self.recordButton.setTitle("Take Photo", for: .normal)
            self.recordButton.isHidden = false
        case 0xEA:
            //Timelapse
            self.modeImageView.image = UIImage(systemName:"timelapse")
            if (cameraStatus!.busy) {
                self.recordButton.setTitle("Stop Recording", for: .normal)
            } else {
                self.recordButton.setTitle("Start Recording", for: .normal)
            }
            self.recordButton.isHidden = false
        default:
            //Unknown
            self.modeImageView.image = nil
            self.recordButton.setTitle("Status Unknown", for: .normal)
            self.recordButton.isHidden = false
        }
    }
    
    @objc func toggleShutter() {
        NSLog("toggleShutter()")
        if (cameraStatus!.busy){
            NSLog("toggleShutter() - Off")
            sendCameraCommand(command: Data([0x01, 0x01, 0x00]))
        } else {
            NSLog("toggleShutter() - On")
            sendCameraCommand(command: Data([0x01, 0x01, 0x01]))
        }
    }
    
    func enableWifi() {
        NSLog("Enabling WiFi...")
        sendCameraCommand(command: Data([0x17, 0x01, 0x01]))
        /*
        if (!(cameraStatus?.wifiEnabled ?? false)){
            sendCameraCommand(command: Data([0x17, 0x01, 0x01]))
        } else {
            requestWiFiSettngs()
        }*/
    }
    
    func sendCameraCommand(command: Data){
        self.lastCommand = command
        self.peripheral?.setCommand(command: command) { result in
            switch result {
            case .success(let response):
                NSLog("Command Response: \(response)")
                //Check command/response and do something
                let commandResponse: CommandResponse = response
                var messageHexString = ""
                for i in 0 ..< commandResponse.command.count {
                    messageHexString += String(format: "%02X", commandResponse.command[i])
                }
                NSLog("Command: \(messageHexString)")
                if ((self.lastCommand![0] == 0x01) && (commandResponse.response[1] == 0x01)){
                    //Shutter Command
                    if (self.lastCommand![2] == 0x01){
                        NSLog("Set cameraStatus!.busy = true")
                        self.cameraStatus!.busy = true
                    } else {
                        NSLog("Set cameraStatus!.busy = false")
                        self.cameraStatus!.busy = false
                    }
                } else if (commandResponse.response[1] == 0x17){
                    if (commandResponse.response[2] == 0x00){
                        //Enable WiFi Command
                        self.requestWiFiSettngs()
                    }
                }
                //self.getCameraStatus()
                self.updateDisplay()
            case .failure(let error):
                NSLog("\(error)")
                self.getCameraStatus()
            }
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
                self.getCameraStatus()
            }
        }
    }
    
    func requestWiFiSettngs() {
        NSLog("Requesting WiFi settings...")
        self.peripheral?.requestWiFiSettings { result in
            switch result {
            case .success(let wifiSettings):
                NSLog("WiFi settings: \(wifiSettings)")
                self.joinWiFi(with: wifiSettings.SSID, password: wifiSettings.password)
            case .failure(let error):
                NSLog("\(error)")
            }
        }
    }
    
    @objc func enterKey() {
        toggleShutter()
    }
    
    @objc func upKey() {
        if (cameraStatus?.mode == 0x00) {
            getCameraStatus()
        } else if (cameraStatus?.mode == 0xEA) {
            cameraStatus?.mode = 0xE8
        } else {
            let mode = cameraStatus?.mode
            cameraStatus?.mode = mode! + 1
        }
        if((0xE8...0xEA).contains(cameraStatus!.mode)){
            sendCameraCommand(command: Data([0x3E,0x02,0x03,cameraStatus!.mode]))
        }
    }
    
    @objc func downKey() {
        if (cameraStatus?.mode == 0x00) {
            getCameraStatus()
        } else if (cameraStatus?.mode == 0xE8) {
            cameraStatus?.mode = 0xEA
        } else {
            let mode = cameraStatus?.mode
            cameraStatus?.mode = mode! - 1
        }
        if((0xE8...0xEA).contains(cameraStatus!.mode)){
            sendCameraCommand(command: Data([0x3E,0x02,0x03,cameraStatus!.mode]))
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
    
    private func joinWiFi(with SSID: String, password: String) {
        NSLog("Joining WiFi \(SSID)...")
        let configuration = NEHotspotConfiguration(ssid: SSID, passphrase: password, isWEP: false)
        NEHotspotNetwork.fetchCurrent { network in
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
        let request = URLRequest(url: startURL)
        sesh.dataTask(with: request) { (data, response, error) in
            NSLog("HTTP: Response:\(response)")
            self.getCameraStatus()
            self.mediaPlayer.play()
        }.resume()
    }

}

extension CameraViewController: VLCMediaPlayerDelegate {

    func mediaPlayerStateChanged(_ aNotification: Notification) {
        NSLog("State: \(mediaPlayer.state)")

        child.willMove(toParent: nil)
        child.view.removeFromSuperview()
        child.removeFromParent()
        
        if mediaPlayer.state == .stopped {
            
        }
    }
}
