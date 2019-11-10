//
//  Query.swift
//  devoniandatabase
//
//  Created by Thomas L Moore on 10/12/18.
//

import Foundation

public class Query: QueryProtocol {
    public let sql: String

    public init(sql: String) {
        self.sql = sql
    }
}
