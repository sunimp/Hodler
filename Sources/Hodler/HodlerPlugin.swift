//
//  HodlerPlugin.swift
//  Hodler
//
//  Created by Sun on 2024/8/15.
//

import Foundation

import BitcoinCore
import SWCryptoKit

// MARK: - HodlerPluginError

public enum HodlerPluginError: Error {
    case unsupportedAddress
    case addressNotGiven
    case invalidData
}

// MARK: - HodlerPlugin

public class HodlerPlugin {
    // MARK: Nested Types

    public enum LockTimeInterval: UInt16, CaseIterable, Codable {
        case hour = 7 //  60 * 60 / 512
        case month = 5063 //  30 * 24 * 60 * 60 / 512
        case halfYear = 30881 // 183 * 24 * 60 * 60 / 512
        case year = 61593 // 365 * 24 * 60 * 60 / 512

        // MARK: Static Properties

        private static let sequenceTimeSecondsGranularity = 512
        private static let relativeLockTimeLockMask: UInt32 = 0x400000 // (1 << 22)

        // MARK: Computed Properties

        public var valueInSeconds: Int {
            Int(rawValue) * LockTimeInterval.sequenceTimeSecondsGranularity
        }

        var sequenceNumber: UInt32 {
            LockTimeInterval.relativeLockTimeLockMask | UInt32(rawValue)
        }

        var valueInTwoBytes: Data {
            Data(from: rawValue)
        }

        var valueInThreeBytes: Data {
            Data(from: sequenceNumber).subdata(in: 0 ..< 3)
        }
    }

    // MARK: Static Properties

    public static let id: UInt8 = OpCode.push(1)[0]

    // MARK: Properties

    private let addressConverter: IHodlerAddressConverter
    private let blockMedianTimeHelper: IHodlerBlockMedianTimeHelper
    private let publicKeyStorage: IHodlerPublicKeyStorage

    // MARK: Computed Properties

    public var id: UInt8 { HodlerPlugin.id }
    public var maxSpendLimit: Int? { nil }

    // MARK: Lifecycle

    public init(
        addressConverter: IHodlerAddressConverter,
        blockMedianTimeHelper: IHodlerBlockMedianTimeHelper,
        publicKeyStorage: IHodlerPublicKeyStorage
    ) {
        self.addressConverter = addressConverter
        self.blockMedianTimeHelper = blockMedianTimeHelper
        self.publicKeyStorage = publicKeyStorage
    }

    // MARK: Functions

    private func lockTimeIntervalFrom(data lockTimeIntervalData: Data) -> LockTimeInterval? {
        guard lockTimeIntervalData.count == 2 else {
            return nil
        }

        let int16 = lockTimeIntervalData
            .withUnsafeBytes { $0.baseAddress!.assumingMemoryBound(to: UInt16.self).pointee }
        return LockTimeInterval(rawValue: int16)
    }

    private func lockTimeIntervalFrom(output: Output) throws -> LockTimeInterval {
        try HodlerOutputData.parse(serialized: output.pluginData).lockTimeInterval
    }

    private func inputLockTime(unspentOutput: UnspentOutput) throws -> Int {
        // Use (an approximate medianTimePast of a block in which given transaction is included) PLUS ~1 hour.
        // This is not an accurate medianTimePast, it is always a timestamp nearly 7 blocks ahead.
        // But this is quite enough in our case since we're setting relative time-locks for at least 1 month
        let previousOutputMedianTime = unspentOutput.transaction.timestamp

        return try previousOutputMedianTime + lockTimeIntervalFrom(output: unspentOutput.output).valueInSeconds
    }

    private func csvRedeemScript(lockTimeInterval: LockTimeInterval, publicKeyHash: Data) -> Data {
        OpCode.push(lockTimeInterval.valueInThreeBytes) + Data([OpCode.checkSequenceVerify, OpCode.drop]) + OpCode
            .p2pkhStart + OpCode.push(publicKeyHash) + OpCode.p2pkhFinish
    }
}

// MARK: IPlugin

extension HodlerPlugin: IPlugin {
    public func validate(address: Address) throws {
        if address.scriptType != .p2pkh {
            throw HodlerPluginError.unsupportedAddress
        }
    }

    /// Changes a recipient address of `mutableTransaction` to a P2SH address and adds a hint about time-lock script
    /// to pluginData, that's later added to the transaction in the form of OP_RETURN output.
    public func processOutputs(
        mutableTransaction: MutableTransaction,
        pluginData: IPluginData,
        skipChecks: Bool = false
    ) throws {
        guard let hodlerData = pluginData as? HodlerData else {
            throw HodlerPluginError.invalidData
        }

        guard let recipientAddress = mutableTransaction.recipientAddress else {
            throw HodlerPluginError.addressNotGiven
        }

        if !skipChecks {
            guard recipientAddress.scriptType == .p2pkh else {
                throw HodlerPluginError.unsupportedAddress
            }
        }

        let redeemScript = csvRedeemScript(
            lockTimeInterval: hodlerData.lockTimeInterval,
            publicKeyHash: recipientAddress.lockingScriptPayload
        )
        let scriptHash = Crypto.ripeMd160Sha256(redeemScript)
        let newAddress = try addressConverter.convert(lockingScriptPayload: scriptHash, type: .p2sh)

        mutableTransaction.recipientAddress = newAddress
        mutableTransaction.add(
            pluginData: OpCode.push(hodlerData.lockTimeInterval.valueInTwoBytes) + OpCode
                .push(recipientAddress.lockingScriptPayload),
            pluginID: id
        )
    }

    /// Detects a time-locked output by parsing a hint in the transaction's OP_RETURN data
    /// and matching it with the user's public keys
    public func processTransactionWithNullData(
        transaction: FullTransaction,
        nullDataChunks: inout IndexingIterator<[Chunk]>
    ) throws {
        guard
            let lockTimeIntervalData = nullDataChunks.next()?.data, let publicKeyHash = nullDataChunks.next()?.data,
            let lockTimeInterval = lockTimeIntervalFrom(data: lockTimeIntervalData)
        else {
            throw HodlerPluginError.invalidData
        }

        let redeemScript = csvRedeemScript(lockTimeInterval: lockTimeInterval, publicKeyHash: publicKeyHash)
        let redeemScriptHash = Crypto.ripeMd160Sha256(redeemScript)

        guard let output = transaction.outputs.first(where: { $0.lockingScriptPayload == redeemScriptHash }) else {
            return
        }

        output.pluginID = id
        output.pluginData = try HodlerOutputData(
            lockTimeInterval: lockTimeInterval,
            addressString: addressConverter.convert(lockingScriptPayload: publicKeyHash, type: .p2pkh).stringValue
        ).toString()

        if let publicKey = publicKeyStorage.publicKey(hashP2pkh: publicKeyHash) {
            output.redeemScript = redeemScript
            output.set(publicKey: publicKey)
        }
    }

    public func isSpendable(unspentOutput: UnspentOutput) throws -> Bool {
        guard let lastBlockMedianTime = blockMedianTimeHelper.medianTimePast else {
            return false
        }

        return try inputLockTime(unspentOutput: unspentOutput) < lastBlockMedianTime
    }

    public func inputSequenceNumber(output: Output) throws -> Int {
        try Int(lockTimeIntervalFrom(output: output).sequenceNumber)
    }

    /// Parses a pluginData string to an instance of HodlerOutputData
    /// and evalutes approximate time when this output can be unlocked
    public func parsePluginData(from pluginData: String, transactionTimestamp: Int) throws -> IPluginOutputData {
        let hodlerOutputData = try HodlerOutputData.parse(serialized: pluginData)

        // When checking if UTXO is spendable we use the best block median time.
        // The median time is 6 blocks earlier which is approximately equal to 1 hour.
        // Here we add 1 hour to show the time when this UTXO will be spendable
        hodlerOutputData.approximateUnlockTime = transactionTimestamp + hodlerOutputData.lockTimeInterval
            .valueInSeconds + 3600

        return hodlerOutputData
    }

    public func keysForApiRestore(publicKey: PublicKey) -> [String] {
        LockTimeInterval.allCases.compactMap { lockTimeInterval in
            let redeemScript = csvRedeemScript(lockTimeInterval: lockTimeInterval, publicKeyHash: publicKey.hashP2pkh)
            let redeemScriptHash = Crypto.ripeMd160Sha256(redeemScript)

            return try? addressConverter.convert(lockingScriptPayload: redeemScriptHash, type: .p2sh).stringValue
        }
    }

    public func incrementSequence(sequence: Int) -> Int {
        let maxInc = 0x7F800000
        let currentInc = sequence & maxInc
        let newInc = min(currentInc + (1 << 23), maxInc)
        let zeroIncSequence = (0xFFFFFFFF - maxInc) & sequence
        return zeroIncSequence | newInc
    }
}
