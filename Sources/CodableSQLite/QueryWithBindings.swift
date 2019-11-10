//
//  QueryWithBindings.swift
//  devoniandatabase
//
//  Created by Thomas L Moore on 10/13/18.
//

import Foundation

public class QueryWithBinding: QueryProtocol, QueryBindable {
    public let sql: String
    public let bindings: [Any]

    public init(sql: String, bindings: [Any]) {
        self.sql = sql
        self.bindings = bindings
    }
}
