//
//  HodlerOutputData.swift
//
//  Created by Sun on 2019/10/10.
//

import Foundation

import BitcoinCore

// MARK: - HodlerOutputData

public class HodlerOutputData: IPluginOutputData {
    // MARK: Properties

    public let lockTimeInterval: HodlerPlugin.LockTimeInterval
    public let addressString: String
    public var approximateUnlockTime: Int? = nil

    // MARK: Lifecycle

    init(lockTimeInterval: HodlerPlugin.LockTimeInterval, addressString: String) {
        self.lockTimeInterval = lockTimeInterval
        self.addressString = addressString
    }

    // MARK: Static Functions

    static func parse(serialized: String?) throws -> HodlerOutputData {
        guard let serialized else {
            throw HodlerPluginError.invalidData
        }

        let parts = serialized.split(separator: "|")

        guard parts.count == 2 else {
            throw HodlerPluginError.invalidData
        }

        let lockTimeIntervalStr = String(parts[0])
        let addressString = String(parts[1])

        guard
            let int16 = UInt16(lockTimeIntervalStr),
            let lockTimeInterval = HodlerPlugin.LockTimeInterval(rawValue: int16)
        else {
            throw HodlerPluginError.invalidData
        }

        return HodlerOutputData(lockTimeInterval: lockTimeInterval, addressString: addressString)
    }

    // MARK: Functions

    func toString() -> String {
        "\(lockTimeInterval.rawValue)|\(addressString)"
    }
}

// MARK: - HodlerData

public class HodlerData: IPluginData {
    // MARK: Properties

    let lockTimeInterval: HodlerPlugin.LockTimeInterval

    // MARK: Lifecycle

    public init(lockTimeInterval: HodlerPlugin.LockTimeInterval) {
        self.lockTimeInterval = lockTimeInterval
    }
}
