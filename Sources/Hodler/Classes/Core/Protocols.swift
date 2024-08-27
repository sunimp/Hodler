//
//  Protocols.swift
//  Hodler
//
//  Created by Sun on 2024/8/21.
//

import Foundation

import BitcoinCore

// MARK: - IHodlerAddressConverter

public protocol IHodlerAddressConverter {
    func convert(lockingScriptPayload: Data, type: ScriptType) throws -> Address
}

// MARK: - IHodlerPublicKeyStorage

public protocol IHodlerPublicKeyStorage {
    func publicKey(hashP2pkh hash: Data) -> PublicKey?
}

// MARK: - IHodlerBlockMedianTimeHelper

public protocol IHodlerBlockMedianTimeHelper {
    var medianTimePast: Int? { get }
}
