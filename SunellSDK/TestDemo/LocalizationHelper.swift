//
//  LocalizationHelper.swift
//  SunellSDKDemo
//
//  Created by Sunell on 2026/3/17.
//

import Foundation

/// Thin wrapper for `NSLocalizedString`; pass the key only.
/// Keys in Localizable.strings use the `TK_` prefix.
func TKLocalizedString(_ key: String) -> String {
    return NSLocalizedString(key, comment: "")
}
