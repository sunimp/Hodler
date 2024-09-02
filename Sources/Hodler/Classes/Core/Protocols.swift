//
//  Protocols.swift
//
//  Created by Sun on 2019/10/22.
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
