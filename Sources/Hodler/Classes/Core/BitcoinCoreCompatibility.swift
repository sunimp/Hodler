//
//  BitcoinCoreCompatibility.swift
//  Hodler
//
//  Created by Sun on 2024/8/21.
//

import Foundation

import BitcoinCore

extension AddressConverterChain: IHodlerAddressConverter {}
extension GrdbStorage: IHodlerPublicKeyStorage {}
extension BlockMedianTimeHelper: IHodlerBlockMedianTimeHelper {}
