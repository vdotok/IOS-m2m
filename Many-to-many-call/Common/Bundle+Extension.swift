//
//  Bundle+Extension.swift
//  Many-to-many-call
//
//  Created by usama farooq on 30/05/2022.
//  Copyright © 2022 VDOTOK. All rights reserved.
//

import Foundation
extension Bundle {
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
}
