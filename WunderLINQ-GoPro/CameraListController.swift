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

import UIKit
import CoreBluetooth

class CameraListController: UITableViewController {
    
    @IBOutlet weak var cameraListTableView: UITableView!
    
    var scanner = CentralManager()
    private var peripheral: Peripheral?
    
    private let notificationCenter = NotificationCenter.default
    
    var itemRow = 0

    override func viewDidLoad() {
        NSLog("IN viewDidLoad()")
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        if let peripheral = peripheral {
            NSLog("Disconnecting to \(peripheral.name)..")
            peripheral.disconnect()
        }
        //NSLog("Scanning for GoPro cameras..")
        //scanner.start(withServices: [CBUUID(string: "FEA6")])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NSLog("IN viewWillAppear()")
        super.viewWillAppear(animated)
        
        NSLog("Scanning for GoPro cameras..")
        scanner.start(withServices: [CBUUID(string: "FEA6")])
        notificationCenter.addObserver(self, selector:#selector(updateDisplay), name: NSNotification.Name("GoProFound"), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NSLog("IN viewWillDisappear()")
        super.viewWillDisappear(animated)
        notificationCenter.removeObserver(self)
        scanner.stop()
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    // Create a standard header that includes the returned text.
    /*
    override func tableView(_ tableView: UITableView, titleForHeaderInSection
                                section: Int) -> String? {
       return "Discovered Cameras"
    }
     */
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        
        return scanner.peripherals.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
     
        let cell = tableView.dequeueReusableCell(withIdentifier: "CameraListViewCell", for: indexPath)
        
        let labelText = scanner.peripherals[indexPath.row].name
        NSLog(labelText)
        cell.textLabel?.text = labelText

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        itemRow = indexPath.row
        enterKey()
    }
    
    @objc func updateDisplay(){
        if self.viewIfLoaded?.window != nil {
            cameraListTableView.reloadData()
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
        let selected: Peripheral = scanner.peripherals[itemRow]
        selected.connect { error in
            if error != nil {
                NSLog("Error connecting to \(selected.name)")
                return
            }
            NSLog("Connected to \(selected.name)!")
            self.peripheral = selected
            // Create an instance of PlayerTableViewController and pass the variable
            let destinationVC = CameraViewController()
            destinationVC.peripheral = selected

            // Let's assume that the segue name is called playerSegue
            // This will perform the segue and pre-load the variable for you to use
            self.performSegue(withIdentifier: "cameraListToCameraView", sender: self)
        }
    }
    @objc func upKey() {
        if (itemRow == 0){
            let nextRow = scanner.peripherals.count - 1
            self.cameraListTableView.cellForRow(at: IndexPath(row: itemRow, section: 0) as IndexPath)?.contentView.backgroundColor = UIColor.black
            self.cameraListTableView.cellForRow(at: IndexPath(row: itemRow, section: 0) as IndexPath)?.textLabel?.backgroundColor = UIColor.black
            self.cameraListTableView.cellForRow(at: IndexPath(row: itemRow, section: 0) as IndexPath)?.textLabel?.textColor = UIColor.white
            cameraListTableView.reloadData()
            self.cameraListTableView.cellForRow(at: IndexPath(row: nextRow, section: 0) as IndexPath)?.contentView.backgroundColor = UIColor.white
            self.cameraListTableView.cellForRow(at: IndexPath(row: nextRow, section: 0) as IndexPath)?.textLabel?.backgroundColor = UIColor.white
            self.cameraListTableView.cellForRow(at: IndexPath(row: nextRow, section: 0) as IndexPath)?.textLabel?.textColor = UIColor.black
            self.cameraListTableView.scrollToRow(at: IndexPath(row: nextRow, section: 0), at: .middle, animated: true)
            itemRow = nextRow
        } else if (itemRow < scanner.peripherals.count){
            let nextRow = itemRow - 1
            self.cameraListTableView.cellForRow(at: IndexPath(row: itemRow, section: 0) as IndexPath)?.contentView.backgroundColor = UIColor.black
            self.cameraListTableView.cellForRow(at: IndexPath(row: itemRow, section: 0) as IndexPath)?.textLabel?.backgroundColor = UIColor.black
            self.cameraListTableView.cellForRow(at: IndexPath(row: itemRow, section: 0) as IndexPath)?.textLabel?.textColor = UIColor.white
            cameraListTableView.reloadData()
            self.cameraListTableView.cellForRow(at: IndexPath(row: nextRow, section: 0) as IndexPath)?.contentView.backgroundColor = UIColor.white
            self.cameraListTableView.cellForRow(at: IndexPath(row: nextRow, section: 0) as IndexPath)?.textLabel?.backgroundColor = UIColor.white
            self.cameraListTableView.cellForRow(at: IndexPath(row: nextRow, section: 0) as IndexPath)?.textLabel?.textColor = UIColor.black
            self.cameraListTableView.scrollToRow(at: IndexPath(row: nextRow, section: 0), at: .middle, animated: true)
            itemRow = nextRow
        }
    }
    @objc func downKey() {
        if (itemRow == (scanner.peripherals.count - 1)){
            let nextRow = 0
            self.cameraListTableView.cellForRow(at: IndexPath(row: itemRow, section: 0) as IndexPath)?.contentView.backgroundColor = UIColor.black
            self.cameraListTableView.cellForRow(at: IndexPath(row: itemRow, section: 0) as IndexPath)?.textLabel?.backgroundColor = UIColor.black
            self.cameraListTableView.cellForRow(at: IndexPath(row: itemRow, section: 0) as IndexPath)?.textLabel?.textColor = UIColor.white
            cameraListTableView.reloadData()
            self.cameraListTableView.cellForRow(at: IndexPath(row: nextRow, section: 0) as IndexPath)?.contentView.backgroundColor = UIColor.white
            self.cameraListTableView.cellForRow(at: IndexPath(row: nextRow, section: 0) as IndexPath)?.textLabel?.backgroundColor = UIColor.white
            self.cameraListTableView.cellForRow(at: IndexPath(row: nextRow, section: 0) as IndexPath)?.textLabel?.textColor = UIColor.black
            self.cameraListTableView.scrollToRow(at: IndexPath(row: nextRow, section: 0), at: .middle, animated: true)
            itemRow = nextRow
        } else if (itemRow < scanner.peripherals.count ){
            let nextRow = itemRow + 1
            self.cameraListTableView.cellForRow(at: IndexPath(row: itemRow, section: 0) as IndexPath)?.contentView.backgroundColor = UIColor.black
            self.cameraListTableView.cellForRow(at: IndexPath(row: itemRow, section: 0) as IndexPath)?.textLabel?.backgroundColor = UIColor.black
            self.cameraListTableView.cellForRow(at: IndexPath(row: itemRow, section: 0) as IndexPath)?.textLabel?.textColor = UIColor.white
            cameraListTableView.reloadData()
            self.cameraListTableView.cellForRow(at: IndexPath(row: nextRow, section: 0) as IndexPath)?.contentView.backgroundColor = UIColor.white
            self.cameraListTableView.cellForRow(at: IndexPath(row: nextRow, section: 0) as IndexPath)?.textLabel?.backgroundColor = UIColor.white
            self.cameraListTableView.cellForRow(at: IndexPath(row: nextRow, section: 0) as IndexPath)?.textLabel?.textColor = UIColor.black
            self.cameraListTableView.scrollToRow(at: IndexPath(row: nextRow, section: 0), at: .middle, animated: true)
            itemRow = nextRow
        }
    }
    @objc func leftKey() {
        
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

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "cameraListToCameraView") {
            let vc = segue.destination as! CameraViewController
            vc.peripheral = self.peripheral
        }
    }

}

