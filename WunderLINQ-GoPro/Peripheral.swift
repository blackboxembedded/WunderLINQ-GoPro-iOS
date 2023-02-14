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
import CoreBluetooth

/// A simple wrapper around CBPeripheral to handle CoreBluetooth Peripheral related tasks
final class Peripheral: NSObject {
    private let notificationCenter = NotificationCenter.default
    var identifier: String { return cbPeripheral.identifier.uuidString }
    var name: String = ""

    var onConnect: ((Error?) -> Void)?
    var onDisconnect: ((Error?) -> Void)?

    private var cbPeripheral: CBPeripheral!
    private weak var manager: CentralManager!

    private var discoveredServiceCallbacks: [((Error?) -> Void)] = []
    private var discoveredCharacteristicCallbacks: [((Error?) -> Void)] = []
    private var readCharacteristicCallbacks: [((Result<Data, Error>) -> Void)] = []
    private var writeCharacteristicCallbacks: [((Error?) -> Void)] = []
    private var notificationChangeCallbacks: [((Error?) -> Void)] = []
    private var characteristicObservers: [CBUUID: ((Data) -> ())] = [:]

    let queue = DispatchQueue(label: "com.gopro.ble.peripheral.queue", qos: .default)

    init(peripheral: CBPeripheral, localName: String, manager: CentralManager) {
        super.init()
        self.cbPeripheral = peripheral
        self.name = localName
        self.manager = manager
        self.cbPeripheral.delegate = self
    }

    deinit {
        cbPeripheral.delegate = nil
    }
}

// MARK: Connection/Disconnection

extension Peripheral {

    /// Connects to the peripheral
    /// - Parameter completion: The completion handler with an optional error invoked once the request completes.
    func connect(_ completion: ((Error?) -> Void)?) {
        queue.async { [unowned self] in
            guard let cbPeripheral = cbPeripheral else { return }
            onConnect = { error in DispatchQueue.main.async { completion?(error) } }
            manager.connectPeripheral(cbPeripheral)
        }
    }

    /// Disconnects from the peripheral
    func disconnect() {
        queue.async { [unowned self] in
            guard let cbPeripheral = cbPeripheral else { return }
            manager.disconnectPeripheral(cbPeripheral)
            discoveredServiceCallbacks = []
            discoveredCharacteristicCallbacks = []
            readCharacteristicCallbacks = []
            writeCharacteristicCallbacks = []
            notificationChangeCallbacks = []

            manager.disconnectPeripheral(self.cbPeripheral)
        }
    }
}

// MARK: Read/Write/Notification

extension Peripheral {

    /// Reads the characteristic value on a service
    /// - Parameters:
    ///   - characteristicUUID: The characteristic UUID
    ///   - serviceUUID: The service UUID
    ///   - completion: The completion handler with a result representing either a success or a failure.
    ///                 In the success case, the associated value is a buffer containing the peripheral response
    func readData(from characteristicUUID: CBUUID, serviceUUID: CBUUID, completion:((Result<Data, Error>) -> Void)?) {
        queue.async { [unowned self] in
            self.discoverCharacteristic(serviceUUID: serviceUUID, characteristicUUID: characteristicUUID) { result in
                switch result {
                case .success(let characteristic):
                    self.readCharacteristicCallbacks.append { response in completion?(response) }
                    self.cbPeripheral.readValue(for: characteristic)
                case .failure(let error):
                    completion?(.failure(error))
                }
            }
        }
    }

    /// Writes a value to a characteristic
    /// - Parameters:
    ///   - data: The value to write
    ///   - serviceUUID: The service UUID
    ///   - characteristicUUID: The characteristic UUID
    ///   - completion: The completion handler with an optional error invoked once the request completes.
    func write(data: Data, serviceUUID: CBUUID, characteristicUUID: CBUUID, completion:((Error?) -> Void)?) {
        queue.async { [unowned self] in
            self.discoverCharacteristic(serviceUUID: serviceUUID, characteristicUUID: characteristicUUID) { result in
                switch result {
                case .success(let characteristic):
                    let type: CBCharacteristicWriteType = completion != nil ? .withResponse : .withoutResponse
                    self.writeCharacteristicCallbacks.append { error in completion?(error) }
                    self.cbPeripheral.writeValue(data, for: characteristic, type: type)
                case .failure(let error):
                    completion?(error)
                }
            }
        }
    }

    /// Enables notification on a characteristic
    /// - Parameters:
    ///   - serviceUUID: The service UUID
    ///   - characteristicUUID: The characteristic UUID
    ///   - observer: A callback invoked when an update of the characteristic value is received
    ///   - completion: The completion handler with an optional error invoked once the request completes.
    func registerObserver(serviceUUID: CBUUID, characteristicUUID: CBUUID, observer: @escaping ((Data) -> ()), completion:((Error?) -> Void)?) {
        queue.async { [unowned self] in
            discoverCharacteristic(serviceUUID: serviceUUID, characteristicUUID: characteristicUUID) { result in
                switch result {
                case .success(let characteristic):
                    if characteristic.isNotifying { completion?(nil); return }
                    self.notificationChangeCallbacks.append { error in completion?(nil) }
                    self.characteristicObservers[characteristicUUID] = observer
                    self.cbPeripheral.setNotifyValue(true, for: characteristic)
                case .failure(let error):
                    completion?(error)
                }
            }
        }
    }
}

// MARK: CoreBluetooth Service

extension Peripheral {
    private func discoverService(UUID: CBUUID, completion:((Result<CBService, Error>) -> Void)?) {
        if let service = service(with: UUID) {
            completion?(.success(service))
            return
        }

        discoveredServiceCallbacks.append {[weak self] error in
            guard let service = self?.service(with: UUID) else {
                completion?(.failure(error != nil ? error! : CameraError.invalidRequest))
                return
            }
            completion?(.success(service))
        }

        cbPeripheral.discoverServices([UUID])
    }

    private func service(with UUID: CBUUID) -> CBService? {
        return cbPeripheral.services?.filter { $0.uuid == UUID }.first
    }
}

// MARK: CoreBluetooth Characteristic

extension Peripheral {
    private func discoverCharacteristic(serviceUUID: CBUUID, characteristicUUID: CBUUID, completion:((Result<CBCharacteristic, Error>) -> Void)?) {
        discoverService(UUID: serviceUUID) { [unowned self] result in
            switch result {
            case .success(let service):
                if let characteristic = self.characteristic(serviceUUID: service.uuid, UUID: characteristicUUID) {
                    completion?(.success(characteristic))
                    return
                }
                self.discoveredCharacteristicCallbacks.append { error in
                    guard let characteristic = self.characteristic(serviceUUID: service.uuid, UUID: characteristicUUID) else {
                        completion?(.failure(error != nil ? error! : CameraError.invalidRequest))
                        return
                    }

                    completion?(.success(characteristic))
                }

                self.cbPeripheral.discoverCharacteristics([characteristicUUID], for: service)
            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }

    private func characteristic(serviceUUID: CBUUID, UUID: CBUUID) -> CBCharacteristic? {
        return service(with: serviceUUID)?.characteristics?.filter { $0.uuid == UUID }.first
    }
}

// MARK: CoreBluetooh

extension Peripheral: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        queue.async { [weak self] in
            self?.discoveredServiceCallbacks.first?(error)
            _ = self?.discoveredServiceCallbacks.removeFirst()
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        queue.async { [weak self] in
            self?.discoveredCharacteristicCallbacks.first?(error)
        _ = self?.discoveredCharacteristicCallbacks.removeFirst()
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        queue.async { [weak self] in
            self?.writeCharacteristicCallbacks.first?(error)
            _ = self?.writeCharacteristicCallbacks.removeFirst()
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        queue.async { [weak self] in
            self?.notificationChangeCallbacks.first?(error)
            _ = self?.notificationChangeCallbacks.removeFirst()
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let data = characteristic.value {
            let dispatchData = Data(data)
            queue.async { [weak self] in
            if characteristic.isNotifying {
                let observer = self?.characteristicObservers[characteristic.uuid]
                observer?(dispatchData)
            } else {
                if error != nil {
                    self?.readCharacteristicCallbacks.first?(.failure(error!))
                } else {
                    self?.readCharacteristicCallbacks.first?(.success(dispatchData))
                }
                    _ = self?.readCharacteristicCallbacks.removeFirst()
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        queue.async { [weak self] in
            self?.onDisconnect?(CameraError.networkError)
        }
    }
}
