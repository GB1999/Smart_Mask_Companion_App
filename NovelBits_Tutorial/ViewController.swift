//
//  ViewController.swift
//  NovelBits_Tutorial
//
//  Created by gbdev on 10/3/21.
//

import UIKit
import CoreBluetooth
let CharacterUserDescriptionCharacteristicUUID = CBUUID(string: "2901")

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate{
    // ! used to check for null-safety at a later point
    var centralManager: CBCentralManager!
    var myPeripheral: CBPeripheral!
    
    // check hardware status of bluetooth device
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == CBManagerState.poweredOn{
            //scan for peripherals
            //with services allows you to filter devices based on their UUID
            central.scanForPeripherals(withServices: nil, options: nil)
            print("BLE powered on")
        }
        else{
            print("Something wrong with BLE")
        }
    }
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // check whether peripheral has a name (nullability check)
        
        if let pname = peripheral.name{
            //check if peripheral is raspberrypi (name being advertised by the pi)
            print(peripheral);
            print(pname)
            if pname == "raspberrypi"{
                self.centralManager.stopScan()
                self.myPeripheral = peripheral
                self.myPeripheral.delegate = self
                self.centralManager.connect(peripheral, options: nil)
                print("Attempting to connect to \(pname)")
            }
        }
    }
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        let pname = peripheral.name
        print("Successfully Connected to \(pname ?? "NA")")
        self.myPeripheral.discoverServices([CharacterUserDescriptionCharacteristicUUID])
    }
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if ((error) != nil){
            print(error ?? "An error occured while connecting")
        }
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        //initialize central Manager
        centralManager = CBCentralManager(delegate: self, queue: nil)
        // Do any additional setup after loading the view.
    }


}

