//
//  BitcoinCoreCompatibility.swift
//  Hodler
//
//  Created by Sun on 2024/8/15.
//

import Foundation

import BitcoinCore

// MARK: - AddressConverterChain + IHodlerAddressConverter

extension AddressConverterChain: IHodlerAddressConverter { }

// MARK: - GrdbStorage + IHodlerPublicKeyStorage

extension GrdbStorage: IHodlerPublicKeyStorage { }

// MARK: - BlockMedianTimeHelper + IHodlerBlockMedianTimeHelper

extension BlockMedianTimeHelper: IHodlerBlockMedianTimeHelper { }
