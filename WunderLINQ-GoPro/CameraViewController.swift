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

class CameraViewController: UIViewController {
    
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var modeImageView: UIImageView!
    
    var peripheral: Peripheral?
    
    var cameraStatus: CameraStatus?
    
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
        
        getCameraStatus()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
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
    
    @objc func toggleShutter() {
        NSLog("toggleShutter()")
        if (cameraStatus!.busy){
            peripheral?.setShutterOff { error in
                if error != nil {
                    print("\(error!)")
                    return
                }
            }
            cameraStatus?.busy = false
        } else {
            peripheral?.setShutterOn { error in
                if error != nil {
                    print("\(error!)")
                    return
                }
            }
            cameraStatus?.busy = true
        }
        
    }
    
    @objc func getCameraStatus() {
        peripheral?.requestCameraStatus() { result in
            switch result {
            case .success(let status):
                print("Mode Value: \(status)")
                self.cameraStatus = status
                switch status.mode {
                case 0xE8:
                    //Video
                    print("Video")
                    self.modeImageView.image = UIImage(systemName:"video")
                case 0xE9:
                    //Photo
                    print("Photo")
                    self.modeImageView.image = UIImage(systemName:"camera")
                case 0xEA:
                    //Timelapse
                    print("Timelapse")
                    self.modeImageView.image = UIImage(systemName:"timelapse")
                default:
                    //Unknown
                    print("Unknown")
                    self.modeImageView.image = nil
                }
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
            peripheral?.setGroup(mode: cameraStatus!.mode) { error in
                if error != nil {
                    print("\(error!)")
                    return
                }
            }
        } else {
            cameraStatus?.mode = cameraStatus!.mode + 1
            peripheral?.setGroup(mode: cameraStatus!.mode) { error in
                if error != nil {
                    print("\(error!)")
                    return
                }
            }
        }
    }
    @objc func downKey() {
        if (cameraStatus?.mode == 0x00) {
            getCameraStatus()
        } else if (cameraStatus?.mode == 0xE8) {
            cameraStatus?.mode = 0xEA
            peripheral?.setGroup(mode: cameraStatus!.mode) { error in
                if error != nil {
                    print("\(error!)")
                    return
                }
            }
        } else {
            cameraStatus?.mode = cameraStatus!.mode - 1
            peripheral?.setGroup(mode: cameraStatus!.mode) { error in
                if error != nil {
                    print("\(error!)")
                    return
                }
            }
        }
    }
    @objc func leftKey() {
        self.dismiss(animated: true, completion: nil)
    }
    @objc func rightKey() {
        
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
}
