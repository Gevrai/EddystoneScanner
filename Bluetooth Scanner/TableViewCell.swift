//
//  TableViewCell.swift
//  Bluetooth Scanner
//
//  Created by iosdev Cdrv on 2018-06-10.
//  Copyright © 2018 Cdrv. All rights reserved.
//

import UIKit

class TableViewCell: UITableViewCell {
    
    static let ReuseID = "TableViewCell"

    @IBOutlet weak var namespace_lbl: UILabel!
    @IBOutlet weak var instanceID_lbl: UILabel!
    @IBOutlet weak var type_lbl: UILabel!
    @IBOutlet weak var tx_lbl: UILabel!
    @IBOutlet weak var rssi_lbl: UILabel!
    @IBOutlet weak var distance_lbl: UILabel!
    
    var beacon : EddystoneBeacon? {
        didSet {
            namespace_lbl.text = beacon?.namespace.hexString
            instanceID_lbl.text = beacon?.instanceID.hexString
            type_lbl.text = beacon?.type.str
            tx_lbl.text = "\(beacon?.txPower ?? 0)dB"
            rssi_lbl.text = "\(beacon?.RSSI ?? 0)dB"
            distance_lbl.text = String(format: "%.1f m", beacon?.estimatedDistance ?? 0.0)
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(false, animated: animated)
    }

}

extension Data {
    
    var hexString : String {
        let hexSym = ["0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"]
        return self.map { return hexSym[Int($0/16)] + hexSym[Int($0%16)] }.joined()
    }
    
}
