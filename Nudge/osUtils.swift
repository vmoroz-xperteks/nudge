//
//  osUtils.swift
//  Nudge
//
//  Created by Erik Gomez on 2/5/21.
//

import AppKit
import Foundation
import SystemConfiguration

struct osUtils {
    func getCurrentDate() -> Date {
        Date()
    }
    
    func getCutOffDate() -> Date {
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "yyyy-MM-dd-HH:mm:ss"
        let nudge_prefs = nudgePrefs().loadNudgePrefs()
        let cutOffString = nudge_prefs?.cut_off_date!
        return dateFormatterGet.date(from: cutOffString!)!
    }
    
    func pastCutOffDate() -> Bool {
        return getCurrentDate() > getCutOffDate()
    }
    
    func requireDualCloseButtons() -> Bool {
        let nudge_prefs = nudgePrefs().loadNudgePrefs()
        let cutOffStringWarning = nudge_prefs?.dual_close_trigger_threshold!
        return cutOffStringWarning! >= numberOfDaysBetween()
    }
    
    func numberOfDaysBetween() -> Int {
       let currentCal = Calendar.current
       let fromDate = currentCal.startOfDay(for: getCurrentDate())
       let toDate = currentCal.startOfDay(for: getCutOffDate())
       let numberOfDays = currentCal.dateComponents([.day], from: fromDate, to: toDate)
       return numberOfDays.day!
   }

    // https://gist.github.com/joncardasis/2c46c062f8450b96bb1e571950b26bf7
    func getSystemConsoleUsername() -> String {
        var uid: uid_t = 0
        var gid: gid_t = 0
        return SCDynamicStoreCopyConsoleUser(nil, &uid, &gid) as String? ?? ""
    }

    // https://ourcodeworld.com/articles/read/1113/how-to-retrieve-the-serial-number-of-a-mac-with-swift
    func getSerialNumber() -> String {
        var serialNumber: String? {
            let platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice") )
            
            guard platformExpert > 0 else {
                return nil
            }
            
            guard let serialNumber = (IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformSerialNumberKey as CFString, kCFAllocatorDefault, 0).takeUnretainedValue() as? String)?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) else {
                return nil
            }
            
            IOObjectRelease(platformExpert)

            return serialNumber
        }
        
        return serialNumber ?? ""
    }

    func getMajorOSVersion() -> Int {
        return ProcessInfo().operatingSystemVersion.majorVersion
    }

    func getMinorOSVersion() -> Int {
        return ProcessInfo().operatingSystemVersion.minorVersion
    }

    func getPatchOSVersion() -> Int {
        return ProcessInfo().operatingSystemVersion.patchVersion
    }
    
    func getMajorRequiredNudgeOSVersion() -> Int {
        let nudge_prefs = nudgePrefs().loadNudgePrefs()
        let parts = nudge_prefs?.minimum_os_version!.split(separator: ".", omittingEmptySubsequences: false)
        return Int(parts![0])!
    }

    // Why is there not a combined String for this?
    func getOSVersion() -> String {
        return String(getMajorOSVersion()) + "." + String(getMinorOSVersion()) + "." + String(getPatchOSVersion())
    }

    // Adapted from https://stackoverflow.com/a/25453654
    func versionEqual(current_version: String, new_version: String) -> Bool {
        return current_version.compare(new_version, options: .numeric) == .orderedSame
    }
    func versionGreaterThan(current_version: String, new_version: String) -> Bool {
        return current_version.compare(new_version, options: .numeric) == .orderedDescending
    }
    func versionGreaterThanOrEqual(current_version: String, new_version: String) -> Bool {
        return current_version.compare(new_version, options: .numeric) != .orderedAscending
    }
    func versionLessThan(current_version: String, new_version: String) -> Bool {
        return current_version.compare(new_version, options: .numeric) == .orderedAscending
    }
    func versionLessThanOrEqual(current_version: String, new_version: String) -> Bool {
        return current_version.compare(new_version, options: .numeric) != .orderedDescending
    }
    
    // Bring it front
    func bringNudgeToFront() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.mainWindow?.makeKeyAndOrderFront(self)
    }
    
    // https://stackoverflow.com/a/63539782
    func getCPUTypeInt() -> Int {
        var cputype = UInt32(0)
        var size = cputype.byteWidth
        let result = sysctlbyname("hw.cputype", &cputype, &size, nil, 0)
        if result == -1 {
            if (errno == ENOENT){
                return 0
            }
            return -1
        }
        return Int(cputype)
    }

    func getCPUTypeString() -> String {
        let type: Int = getCPUTypeInt()
        if type == -1 {
            return "error in CPU type"
        }
        
        let cpu_arch = type & 0xff // mask for architecture bits
        if cpu_arch == cpu_type_t(7){
            return "Intel"
        }
        if cpu_arch == cpu_type_t(12){
            return "Apple Silicon"
        }
        return "unknown"
    }
}

// https://stackoverflow.com/a/63539782
extension FixedWidthInteger {
    var byteWidth:Int {
        return self.bitWidth/UInt8.bitWidth
    }
    static var byteWidth:Int {
        return Self.bitWidth/UInt8.bitWidth
    }
}