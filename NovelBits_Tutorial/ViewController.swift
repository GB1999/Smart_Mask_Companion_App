//
//  ViewController.swift
//  NovelBits_Tutorial
//
//  Created by gbdev on 10/3/21.
//

import UIKit
import CoreBluetooth

extension String {
    func image(pointSize: CGFloat = UIFont.systemFontSize) -> UIImage? {
        let nsString = self as NSString
        let font = UIFont.systemFont(ofSize: pointSize)

        let size = nsString.size(withAttributes: [.font: font])
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let rect = CGRect(origin: .zero, size: size)
        nsString.draw(in: rect, withAttributes: [.font: font])
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

let CharacterUserDescriptionCharacteristicUUID = CBUUID(string: "2901")

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate{
    // ! used to check for null-safety at a later point
    var centralManager: CBCentralManager!
    var myPeripheral: CBPeripheral!
    var notifyNum: Int = 0
    // Sliders
    @IBOutlet weak var fanSpeedSlider: UISlider!
    @IBOutlet weak var speakerVolumeSlider: UISlider!
    @IBOutlet weak var dictationThresholdSlider: UISlider!
    
    @IBOutlet weak var languageSelectionButton: UIButton!
    @IBOutlet weak var languageSelectionMenu: UIMenu!
    @IBOutlet weak var fanToggleSwitch: UISwitch!
    
    @IBOutlet weak var consoleLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    
    // Characteristics
    private var speakerVolume: CBCharacteristic?
    private var fontSize: CBCharacteristic?
    private var fanToggle: CBCharacteristic?
    private var languageSelection: CBCharacteristic?
    private var savePrintOut: Bool = false
    
    let frenchEmoji = "π«π·".image()
    let spanishEmoji = "πͺπΈ".image()
    let englishEmoji = "πΊπΈ".image()
    
    var demoMenu: UIMenu {
        return UIMenu(title: "My menu", image: nil, identifier: nil, options: [], children: menuItems)
    }
    var menuItems: [UIAction] {
        return [
            UIAction(title: "French", image: frenchEmoji, handler: {
                [unowned self]_ in
                writeValueToCharacteristic(withCharacteristic: languageSelection!, withValue: Data(Array("fr".utf8)))}),
            UIAction(title: "Spanish", image: spanishEmoji, handler: {
                [unowned self]_ in
                writeValueToCharacteristic(withCharacteristic: languageSelection!, withValue: Data(Array("es".utf8)))}),
            UIAction(title: "English (default)", image: englishEmoji, handler: {
                [unowned self]_ in
                writeValueToCharacteristic(withCharacteristic: languageSelection!, withValue: Data(Array("en".utf8)))}),
        ]
    }

    private func setupLanguageSelectionButton(){
        
        languageSelectionButton.menu = demoMenu
        languageSelectionButton.showsMenuAsPrimaryAction = true
    }
    
    // check hardware status of bluetooth device
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == CBManagerState.poweredOn{
            //scan for peripherals
            //with services allows you to filter devices based on their UUID
            central.scanForPeripherals(withServices: nil, options: nil)
            print("BLE powered on")
            displayConsoleText(text: "BLE Powered On")
        }
        else{
            print("Something wrong with BLE")
            displayConsoleText(text: "Error occured with BLE")
            
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
                displayConsoleText(text: "Attempting to connect to \(pname)")
            }
        }
    }
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        let pname = peripheral.name
        print("Successfully Connected to \(pname ?? "NA")")
        displayConsoleText(text: "Successfully connected to \(pname)")
        if (savePrintOut){
            writeToFile();
        }
        
        self.myPeripheral.discoverServices(nil)
    }
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        // if this error occurs, forget device and try restarting the application
        if ((error) != nil){
            print(error ?? "An error occured while connecting")
        }
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {return}
        
        for service in services{
            //print(service)
            //print(service.characteristics ?? "characteristics are nil")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else {return}
        
        for characteristic in characteristics {
            if characteristic.properties.contains(.read){
                //print("\(characteristic.uuid): properties contains .read")
                peripheral.readValue(for: characteristic)
            }
            if characteristic.properties.contains(.notify){
                //print("\(characteristic.uuid): properties contains .notify")
                peripheral.setNotifyValue(true, for: characteristic)
            }
            
            switch characteristic.uuid{
            case MaskPeripheral.airHumidityServiceUUID:
                print("Getting Air Humidity Information")
            case MaskPeripheral.fanCharacteristicUUID:
                print("Fan Toggle Characteristic Identified")
                fanToggle = characteristic
                fanToggleSwitch.isEnabled = true
            case MaskPeripheral.speakerVolumeCharacteristicUUID:
                print("Speaker Volume Characteristic Identified")
                speakerVolume = characteristic
                speakerVolumeSlider.isEnabled = true
            case MaskPeripheral.languageSelectionChacteristicUUID:
                print("Language Selection Characteristic Identified")
                languageSelection = characteristic
            default:
                print("\(characteristic.uuid): not recognized")
            }
    }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        //print("characteristic: \(characteristic)")
        switch characteristic.uuid{
        case MaskPeripheral.airTempServiceUUID:
            print("Getting Air Temp Information")
            let tempVal = tempConversion(from: characteristic)
            updateTempLabel(text: tempVal)
        case MaskPeripheral.airHumidityServiceUUID:
            print("Getting Air Humidity Information")
            let humidityVal = humidityConversion(from: characteristic)
            updateHumidityLabel(text: humidityVal)
        default:
            print("\(characteristic.uuid): not recognized")
            tempConversion(from: characteristic)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        print("Services Modified")
    }
    
    private func humidityConversion(from characteristic: CBCharacteristic) -> String{
        guard let characteristicData = characteristic.value else {return ""}
        let byteArray = [UInt8](characteristicData)
        let humidityString = String(bytes: byteArray, encoding: .utf8);
        notifyNum+=1
        print("Recieved  notify value \(notifyNum) at \(currentTime()): \(humidityString)");
        return humidityString ?? "TEMP NOT FOUND"
    }
    
    private func tempConversion(from characteristic: CBCharacteristic) -> String{
        guard let characteristicData = characteristic.value else {return ""}
        let byteArray = [UInt8](characteristicData)
        let tempString = String(bytes: byteArray, encoding: .utf8);
        notifyNum+=1
        print("Recieved  notify value \(notifyNum) at \(currentTime()): \(tempString)");
        return tempString ?? "TEMP NOT FOUND"
    }
    
    private func writeValueToCharacteristic( withCharacteristic characteristic: CBCharacteristic, withValue value: Data){
        if  myPeripheral != nil{
            myPeripheral.writeValue(value, for: characteristic, type: .withoutResponse)
        }
    }
    
    private func displayConsoleText(text: String){
        self.consoleLabel.text = text;
    }
    
    private func updateHumidityLabel(text: String){
        self.humidityLabel.text = text;
    }
    
    private func updateTempLabel(text: String){
        self.temperatureLabel.text = text;
    }
    
    private func writeToFile(){
        let docDirectory: NSString =	 NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0] as NSString
        let logpath = docDirectory.appendingPathComponent("Mask_Console_Log.txt")
        freopen(logpath.cString(using: String.Encoding.ascii)!, "a+", stdout)
    }
    
    private func currentTime() -> String{
        let date = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        let seconds = calendar.component(.second, from: date)
        return "\(hour):\(minutes):\(seconds)"
    }
    
    @IBAction func toggleLanguageSelectionButton(_ sender: Any) {
        languageSelectionButton.menu = languageSelectionMenu
        languageSelectionButton.showsMenuAsPrimaryAction = true
    }
    
    

    @IBAction func fanToggleChanged(_ sender: Any) {
        let toggleInt:UInt8 = UInt8(fanToggleSwitch.isOn ? 1 : 0)
        print(toggleInt)
        writeValueToCharacteristic(withCharacteristic: fanToggle!, withValue: Data([toggleInt]))
    }
    
    @IBAction func speakerVolumeChanged(_ sender: Any) {
        
        let slider:UInt8 = UInt8(speakerVolumeSlider.value)
        writeValueToCharacteristic(withCharacteristic: speakerVolume!, withValue: Data([slider]))
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLanguageSelectionButton()
        
        //initialize central Manager
        centralManager = CBCentralManager(delegate: self, queue: nil)
        // Do any additional setup after loading the view.
    }


}

