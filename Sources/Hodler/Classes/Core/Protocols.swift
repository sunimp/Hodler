//
//  Protocols.swift
//  Hodler
//
//  Created by Sun on 2024/8/21.
//

import Foundation

import BitcoinCore

public protocol IHodlerAddressConverter {
    func convert(lockingScriptPayload: Data, type: ScriptType) throws -> Address
}

public protocol IHodlerPublicKeyStorage {
    func publicKey(hashP2pkh hash: Data) -> PublicKey?
}

public protocol IHodlerBlockMedianTimeHelper {
    var medianTimePast: Int? { get }
}
