//
//  QueryProtocol.swift
//  devoniandatabase
//
//  Created by Thomas L Moore on 10/12/18.
//

import Foundation

public protocol QueryProtocol {
    var sql: String { get }
}

public protocol QueryBindable {
    var bindings: [Any] { get }
}
