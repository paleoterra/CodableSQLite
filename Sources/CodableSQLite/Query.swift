//
//  Query.swift
//  devoniandatabase
//
//  Created by Thomas L Moore on 10/12/18.
//

import Foundation

class Query: QueryProtocol {
    let sql: String

    init(sql: String) {
        self.sql = sql
    }
}
