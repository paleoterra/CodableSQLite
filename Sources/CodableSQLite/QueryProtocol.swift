//
//  QueryProtocol.swift
//  devoniandatabase
//
//  Created by Thomas L Moore on 10/12/18.
//

import Foundation

protocol QueryProtocol {
    var sql: String { get }
}

protocol QueryBindable {
    var bindings: [Any]  { get }
}
