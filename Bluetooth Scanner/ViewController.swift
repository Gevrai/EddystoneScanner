//
//  ViewController.swift
//  Bluetooth Scanner
//
//  Created by iosdev Cdrv on 2018-06-10.
//  Copyright © 2018 Cdrv. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController {
    
    @IBOutlet weak var startStopScan_btn: UIButton!
    @IBOutlet weak var devicesTableView: UITableView!
    
    var cbCentralManager : CBCentralManager?
    var beacons = [(Date,EddystoneBeacon)]()
    var currentSelectedBeacon : EddystoneBeacon?
    var refreshTimer : Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        cbCentralManager = CBCentralManager(delegate: self, queue: nil)
        devicesTableView.dataSource = self
    }
    
    func refreshInterface() {
        startStopScan_btn.setTitle(
            cbCentralManager!.isScanning
                ? "Stop Scanning"
                : "Start Scanning"
            , for: .normal)
    }
    
    @IBAction func startStopScan() {
        if cbCentralManager!.isScanning {
            cbCentralManager?.stopScan()
            refreshTimer?.invalidate()
        } else {
            beacons.removeAll()
            currentSelectedBeacon = nil
            devicesTableView.reloadData()
            cbCentralManager?.scanForPeripherals(
                withServices: [EddystoneBeacon.EddystoneUUID],
                options: [CBCentralManagerScanOptionAllowDuplicatesKey:true])
            refreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) {
                [weak self] timer in
                guard self != nil else {
                    timer.invalidate()
                    return
                }
                self!.organizeBeaconList()

            }
        }
        refreshInterface()
    }
    
    // Cleanup, sort and put selected beacon first
    func organizeBeaconList() {
        let now = Date()
        self.beacons = self.beacons
            .filter { now.timeIntervalSince($0.0) < 10.0 }
            .map {
                if now.timeIntervalSince($0.0) > 4.0 { $0.1.RSSI -= 5 }
                return $0
            }
            .sorted {
                // Selected beacon in first position
                self.currentSelectedBeacon != nil ? $0.1.isSame(beacon: self.currentSelectedBeacon!) : false
                    // Sort biggest to smallest rssi
                    || $0.1.RSSI > $1.1.RSSI
        }
        self.devicesTableView.reloadData()
    }
    
}

extension ViewController: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            startStopScan()
        }
    }
   
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        guard -100...20 ~= Int(truncating: RSSI),
            let eddystoneBeacon = EddystoneBeacon(fromAdvertisementData: advertisementData, withRssi: RSSI)
            else { return }
        
        if let old = beacons.removeFirst(where: {
            $0.1.instanceID == eddystoneBeacon.instanceID
                && $0.1.namespace == eddystoneBeacon.namespace }) {
            eddystoneBeacon.RSSI = Int8(Double(old.1.RSSI)*0.3 + Double(eddystoneBeacon.RSSI)*0.7)
        }
        beacons.append((Date(),eddystoneBeacon))
    }
    
}

extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? beacons.count : 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCell.ReuseID, for: indexPath) as! TableViewCell
        cell.beacon = beacons[indexPath.row].1
        cell.didSelectBeacon = {
            [weak self] in
            self?.currentSelectedBeacon = $0
            self?.organizeBeaconList()
        }
        if let b = currentSelectedBeacon {
            cell.backgroundColor = (cell.beacon?.isSame(beacon: b) ?? false) ? UIColor.lightGray : UIColor.clear
        }
        return cell
    }
    
}

extension Array {
    mutating public func removeFirst(where cond: @escaping (Element) -> Bool) -> Element? {
        guard let i = self.index(where: cond) else { return nil }
        return self.remove(at: i)
    }
}
