//
//  BitcoinCoreCompatibility.swift
//
//  Created by Sun on 2019/10/22.
//

import Foundation

import BitcoinCore

// MARK: - AddressConverterChain + IHodlerAddressConverter

extension AddressConverterChain: IHodlerAddressConverter { }

// MARK: - GrdbStorage + IHodlerPublicKeyStorage

extension GrdbStorage: IHodlerPublicKeyStorage { }

// MARK: - BlockMedianTimeHelper + IHodlerBlockMedianTimeHelper

extension BlockMedianTimeHelper: IHodlerBlockMedianTimeHelper { }
