//
//  IPManager.swift
//  One-to-one-call-demo
//
//  Created by Asif Ayub on 6/17/21.
//

import Foundation

struct IPManager {
    
    func getMyLocalIP() -> String {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }

                guard let interface = ptr?.pointee else { return "" }
                let addrFamily = interface.ifa_addr.pointee.sa_family
                if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {

                    // wifi = ["en0"]
                    // wired = ["en2", "en3", "en4"]
                    // cellular = ["pdp_ip0","pdp_ip1","pdp_ip2","pdp_ip3"]

                    let name: String = String(cString: (interface.ifa_name))
                    if  name == "en0" || name == "en2" || name == "en3" || name == "en4" || name == "pdp_ip0" || name == "pdp_ip1" || name == "pdp_ip2" || name == "pdp_ip3" {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface.ifa_addr, socklen_t((interface.ifa_addr.pointee.sa_len)), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                        address = String(cString: hostname)
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        return address ?? ""
    }
    
    
    func getMyPublicIP() -> String? {
        let ips = [URL(string:"http://whatismyip.akamai.com")!,
                   URL(string:"https://wgetip.com")!,
                   URL(string:"https://eth0.me")!,
                   URL(string:"https://ifconfig.me")!]
        for ip in ips {
            if let myIp = getMyPublicIP(url: ip) {
                return myIp
            }
        }
        return nil
    }
    
    private func getMyPublicIP(url: URL) -> String? {
        do {
            var publicIP = ""
            try publicIP = String(contentsOf: url, encoding: String.Encoding.utf8)
            publicIP = publicIP.trimmingCharacters(in: CharacterSet.whitespaces)
            return publicIP
        }
        catch {
            print("Error: \(error)")
            return nil
        }
    }
}
