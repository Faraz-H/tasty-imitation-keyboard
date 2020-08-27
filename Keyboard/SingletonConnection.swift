//
//  SingletonConnection.swift
//  Keyboard
//
//  Created by Randall Meadows on 2/19/18.
//  Copyright © 2018 Apple. All rights reserved.
//

import Foundation
import SQLite

enum ConnectionError : Error
{
   case couldNotConnect(reason: String)
}

final class SingletonConnection
{
   static let sharedInstance : SingletonConnection = SingletonConnection()
      
   private init() { }
   
   func connection(_ dbPath : String) throws -> Connection {
      let dbConnection : Connection
         do {
            dbConnection = try Connection(dbPath)
            dbConnection.busyTimeout = 1 // Timeout before retrying
            dbConnection.busyHandler({ (tries) -> Bool in
               return tries <= 10 // Attempts to retry before failing
            })
         }
         catch (let exception) {
            print ("\n***** Unable to connect to database \"\(dbPath)\"")
            throw ConnectionError.couldNotConnect(reason: "Error: \(exception.localizedDescription); DB Path: \(dbPath)")
         }
         
      
      
      return dbConnection
   }
}
