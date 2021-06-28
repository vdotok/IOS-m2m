//
//  SystemDataUsage.swift
//  One-to-one-call-demo
//
//  Created by Asif Ayub on 6/16/21.
//

import UIKit


extension SystemDataUsage {

    public static var wifiCompelete: UInt64 {
        return SystemDataUsage.getDataUsage().wifiSent + SystemDataUsage.getDataUsage().wifiReceived
    }

    public static var wwanCompelete: UInt64 {
        return SystemDataUsage.getDataUsage().wirelessWanDataSent + SystemDataUsage.getDataUsage().wirelessWanDataReceived
    }

}

class SystemDataUsage {

    private static let wwanInterfacePrefix = "pdp_ip"
    private static let wifiInterfacePrefix = "en"
    private static var recordStartDataUsage: (up: UInt64, down: UInt64, startTime: Double) = (0, 0, 0)
    private static var recentDataUsage: (up: UInt64, down: UInt64) = (0, 0)
    
    private enum SignalType {
        case wifi
        case cellular
        
        var iOS13: String {
            switch self {
            case .wifi:
                return "wifiEntry"
            case .cellular:
                return "cellularEntry"
            }
        }
    }
    
    class func getRecentDataUsage() -> (up: Int, down: Int) {
        
        let dataUsage = SystemDataUsage.getDataUsage()
        let up = dataUsage.wifiSent + dataUsage.wirelessWanDataSent - SystemDataUsage.recordStartDataUsage.up
        let down = dataUsage.wifiReceived + dataUsage.wirelessWanDataReceived - SystemDataUsage.recordStartDataUsage.down
        let lastData = (up: abs(Int(up) - Int(SystemDataUsage.recentDataUsage.up)), down: abs(Int(down) - Int(SystemDataUsage.recentDataUsage.down)))
        SystemDataUsage.recentDataUsage = (up, down)
        
        
        return lastData
    }
    
    class func saveStartDataUsage() {
        let dataUsage = SystemDataUsage.getDataUsage()
        let up = dataUsage.wifiSent + dataUsage.wirelessWanDataSent
        let down = dataUsage.wifiReceived + dataUsage.wirelessWanDataReceived
        SystemDataUsage.recordStartDataUsage = (up, down, Date().timeIntervalSince1970)
    }
    
    class func getEndDataUsage() -> (up: UInt64, down: UInt64, startTime: Double) {
        
        let dataUsage = SystemDataUsage.getDataUsage()
        let up = dataUsage.wifiSent + dataUsage.wirelessWanDataSent - SystemDataUsage.recordStartDataUsage.up
        let down = dataUsage.wifiReceived + dataUsage.wirelessWanDataReceived - SystemDataUsage.recordStartDataUsage.down
        let startTimeIntervals = SystemDataUsage.recordStartDataUsage.startTime
        
        // reset start data usage
        SystemDataUsage.recordStartDataUsage = (0, 0, 0)
        
        return (up, down, startTimeIntervals)
        
    }

    class func getDataUsage() -> DataUsageInfo {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        var dataUsageInfo = DataUsageInfo()

        guard getifaddrs(&ifaddr) == 0 else { return dataUsageInfo }
        while let addr = ifaddr {
            guard var info = getDataUsageInfo(from: addr) else {
                ifaddr = addr.pointee.ifa_next
                continue
            }
            info.wifiSignals = getSignalStrength(type: .wifi)
            info.cellularSignals = getSignalStrength(type: .cellular)
            dataUsageInfo.updateInfoByAdding(info)
            ifaddr = addr.pointee.ifa_next
        }

        freeifaddrs(ifaddr)

        return dataUsageInfo
    }
    
    private class func getSignalStrength(type: SignalType) -> UInt64? {
        if #available(iOS 13.0, *) {
            if let statusBarManager = UIApplication.shared.windows.first?.windowScene?.statusBarManager,
                    let localStatusBar = statusBarManager.value(forKey: "createLocalStatusBar") as? NSObject,
                    let statusBar = localStatusBar.value(forKey: "statusBar") as? NSObject,
                    let _statusBar = statusBar.value(forKey: "_statusBar") as? UIView,
                    let currentData = _statusBar.value(forKey: "currentData") as? NSObject,
                    let celluar = currentData.value(forKey: type.iOS13) as? NSObject,
                    let signalStrength = celluar.value(forKey: "displayValue") as? Int {
                    return UInt64(signalStrength)
                } else {
                    return nil
                }
            }
            return nil
    }
    

    private class func getDataUsageInfo(from infoPointer: UnsafeMutablePointer<ifaddrs>) -> DataUsageInfo? {
        let pointer = infoPointer
        let name: String! = String(cString: pointer.pointee.ifa_name)
        let addr = pointer.pointee.ifa_addr.pointee
        guard addr.sa_family == UInt8(AF_LINK) else { return nil }

        return dataUsageInfo(from: pointer, name: name)
    }

    private class func dataUsageInfo(from pointer: UnsafeMutablePointer<ifaddrs>, name: String) -> DataUsageInfo {
        var networkData: UnsafeMutablePointer<if_data>?
        var dataUsageInfo = DataUsageInfo()

        if name.hasPrefix(wifiInterfacePrefix) {
            networkData = unsafeBitCast(pointer.pointee.ifa_data, to: UnsafeMutablePointer<if_data>.self)
            if let data = networkData {
                dataUsageInfo.wifiSent += UInt64(data.pointee.ifi_obytes)
                dataUsageInfo.wifiReceived += UInt64(data.pointee.ifi_ibytes)
            }

        } else if name.hasPrefix(wwanInterfacePrefix) {
            networkData = unsafeBitCast(pointer.pointee.ifa_data, to: UnsafeMutablePointer<if_data>.self)
            if let data = networkData {
                dataUsageInfo.wirelessWanDataSent += UInt64(data.pointee.ifi_obytes)
                dataUsageInfo.wirelessWanDataReceived += UInt64(data.pointee.ifi_ibytes)
            }
        }
        return dataUsageInfo
    }
}

struct DataUsageInfo {
    var wifiReceived: UInt64 = 0
    var wifiSent: UInt64 = 0
    var wirelessWanDataReceived: UInt64 = 0
    var wirelessWanDataSent: UInt64 = 0
    var cellularSignals: UInt64? = nil
    var wifiSignals: UInt64? = nil

    mutating func updateInfoByAdding(_ info: DataUsageInfo) {
        wifiSent += info.wifiSent
        wifiReceived += info.wifiReceived
        wirelessWanDataSent += info.wirelessWanDataSent
        wirelessWanDataReceived += info.wirelessWanDataReceived
        cellularSignals = info.cellularSignals
        wifiSignals = info.wifiSignals
    }
}
