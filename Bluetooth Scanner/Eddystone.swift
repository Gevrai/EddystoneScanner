//
//  Eddystone.swift
//  Bluetooth Scanner
//
//  Created by iosdev Cdrv on 2018-06-10.
//  Copyright © 2018 Cdrv. All rights reserved.
//

import Foundation

//
//  EddystoneBeacon.swift
//  SensorLogger
//
//  Created by iosdev Cdrv on 2018-06-08.
//  Copyright © 2018 Cdrv. All rights reserved.
//

import Foundation
import CoreBluetooth

public enum EddystoneFrameType {
    case UID
    case URL
    case TLM
    case EID
    
    init?(fromByte byte: UInt8) {
        switch byte {
        case 0x00: self = .UID
        case 0x10: self = .URL
        case 0x20: self = .TLM
        case 0x30: self = .EID
        default: return nil
        }
    }
    
    var str : String {
        switch self {
        case .UID: return "UID"
        case .URL: return "URL"
        case .TLM: return "TLM"
        case .EID: return "EID"
        }
    }
}

public class EddystoneBeacon {
    
    static let EddystoneUUID = CBUUID(string: "FEAA")
    
    let type : EddystoneFrameType
    let namespace : Data
    let instanceID : Data
    let txPower : Int8
    var RSSI : Int8
    
    init?(fromAdvertisementData advData: [String:Any], withRssi rssi: NSNumber) {
        
        // Eddystone UID unpacking, see protocol definition for more info
        // https://github.com/google/eddystone/tree/master/eddystone-uid
        
        // EddystoneUUID : 1B
        // TxPower at 0 meter : 1B
        // Namespace : 10B
        // InstanceID : 6B
        let kMinEddystoneDataCount = 1 + 1 + 10 + 6
        
        // Check if it is indeed an eddystone advertisement
        guard
            let frameData = advData[CBAdvertisementDataServiceDataKey] as? [CBUUID:Data],
            let eddystoneData = frameData[EddystoneBeacon.EddystoneUUID],
            eddystoneData.count >= kMinEddystoneDataCount
            else { return nil }
        
        // We only support Eddystone UID frames (for now at least), discard others
        guard let frameTypeByte = eddystoneData.first,
            let frameType = EddystoneFrameType(fromByte: frameTypeByte), frameType == .UID
            else { return nil }
        type = frameType
        // Tx power is calculated a 0 meters in Eddystone
        // txPower at 1 meter ≈ this value - 41dB
        txPower = Int8(bitPattern: eddystoneData.subdata(in: 1..<2).first!)
        RSSI = Int8(truncating: rssi)
        namespace = eddystoneData.subdata(in: 2..<12)
        instanceID = eddystoneData.subdata(in: 12..<18)
        
    }
    
    var estimatedDistance : Double {
        return 0.89976*pow(Double(RSSI)/Double(txPower-41),7.7095) + 0.111
    }
    
}
