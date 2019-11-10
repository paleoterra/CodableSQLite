//
//  QueryWithBindings.swift
//  devoniandatabase
//
//  Created by Thomas L Moore on 10/13/18.
//

import Foundation

class QueryWithBinding: QueryProtocol, QueryBindable {
    let sql: String
    let bindings: [Any]

    init(sql: String, bindings: [Any]) {
        self.sql = sql
        self.bindings = bindings
    }
}
