//
//  Utility.swift
//  Chime.IO-Client-Swift
//
//  Created by JmeHsieh on 4/19/16.
//  Copyright © 2016 JmeHsieh. All rights reserved.
//

import Foundation

struct Utility {
    // ex: 2016-04-13T09:59:20.466Z
    static let dateFormatter: NSDateFormatter = {
        let instance = NSDateFormatter()
        instance.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        instance.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        instance.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSS'Z'"
        return instance
    }()
}
