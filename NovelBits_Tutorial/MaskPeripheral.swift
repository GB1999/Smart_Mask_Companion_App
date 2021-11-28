//
//  MaskPeripheral.swift
//  NovelBits_Tutorial
//
//  Created by gbdev on 10/14/21.7
import Foundation
import UIKit
import CoreBluetooth

class MaskPeripheral: NSObject{
    public static let companionServiceUUID = CBUUID.init(string: "3d66d508-2cb9-11ec-8d3d-0242ac130003")
    public static let airTempServiceUUID = CBUUID.init(string: "9A1AEFB1-3221-11EC-8D3D-0242AC130003")
    public static let airHumidityServiceUUID = CBUUID.init(string: "9A1AEFB2-3221-11EC-8D3D-0242AC130003")
    public static let speakerVolumeCharacteristicUUID = CBUUID.init(string: "989F22A4-48AC-11EC-81D3-0242AC130003")
    public static let fanCharacteristicUUID = CBUUID.init(string: "40146757-3237-11EC-8D3D-0242AC130003")
}
