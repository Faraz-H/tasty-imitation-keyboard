//
//  WordList.swift
//  TastyImitationKeyboard
//
//  Created by Zack Burns on 10/16/16.
//  Copyright © 2016 Apple. All rights reserved.
//

import UIKit
import SQLite


class WordList: NSObject {
    
    override init() {
        
        do {
            let db_path = NSSearchPathForDirectoriesInDomains(
                        .documentDirectory, .userDomainMask, true).first!
            let pathToWords = Bundle.main.path(forResource: "google-10000", ofType: "txt")
            let content = try String(contentsOfFile:pathToWords!, encoding: String.Encoding.utf8)
            let allWords = content.components(separatedBy: "\n")
            
            let db = try Connection("\(db_path)/db.sqlite3")

            // Create Ngrams table
            let ngrams = Table("Ngrams")
            let gram = Expression<String>("gram")
            let n = Expression<Int>("n")
            
            try? db.run(ngrams.create(ifNotExists: true) { t in
                t.column(gram, primaryKey: true)
                t.column(n)
            })
            
            // Create Profiles table
            let profiles = Table("Profiles")
            
            //try? db.run(profiles.delete())
            
            let profileId = Expression<Int64>("profileId")
            let name = Expression<String>("name")
            let linksTo = Expression<Int64>("linksTo")
            
            try? db.run(profiles.create(ifNotExists: true) { t in
                t.column(profileId, primaryKey: .autoincrement)
                t.column(name)
                t.column(linksTo, defaultValue: 0)
            })
            
            // Insert the Default profile into the Profiles table if it doesn't exist
            if (try db.scalar(profiles.filter(name == "Default").count)) == 0 {
                let insert = profiles.insert(name <- "Default")
                _ = try? db.run(insert)
            }
            
            // Create Containers table (pairing of profile and ngram)
            let containers = Table("Containers")
            let containerId = Expression<Int64>("containerId")
            let profile = Expression<String>("profile")
            let ngram = Expression<String>("ngram")
            let frequency = Expression<Int64>("frequency")
            let lastused = Expression<Date>("lastused")
            
            try? db.run(containers.create(ifNotExists: true) { t in
                t.column(containerId, primaryKey: .autoincrement)
                t.column(profile)
                t.column(ngram)
                t.column(frequency, defaultValue: 0)
                t.column(lastused, defaultValue: Date())
            })
            
            // Check to make sure the number of words in Default matches the number
            //   of words in google-10000.txt --- there were duplicates that I deleted,
            //   so there are only 9989 unique words, not 10000
            // If not, then insert the missing words
            if (try db.scalar(containers.filter(profile == "Default").count) < 9989) {
                // Populate the Ngrams table and Container table with words
                for word in allWords {
                    // check if word is in Ngrams, and insert it if it's not
                    let result = try? db.scalar(ngrams.filter(gram == word).count)
                    if result! == 0 {
                        let insert = ngrams.insert(gram <- word, n <- 1)
                        _ = try? db.run(insert)
                    }
                    else if result! > 1{
                        print("There's a duplicate word in the db!")
                    }
                    
                    // check if word is paired with Default profile in Containers table, insert if not
                    let containerResult = try? db.scalar(containers.filter(profile == "Default")
                                            .filter(ngram == word).count)
                    if containerResult == 0 {
                        let insert = containers.insert(profile <- "Default", ngram <- word)
                        _ = try? db.run(insert)
                    }
                }
            }
        }
        catch {
            print("uh oh")
        }
        
    }
    
    func addProfile(profileName:String){
        do {
            let db_path = NSSearchPathForDirectoriesInDomains(
                .documentDirectory, .userDomainMask, true).first!
            let db = try Connection("\(db_path)/db.sqlite3")
            
            let profiles = Table("Profiles")
            let profileId = Expression<Int64>("profileId")
            let name = Expression<String>("name")
            let linksTo = Expression<Int64>("linksTo")
            if (try db.scalar(profiles.filter(name == profileName).count)) == 0 {
                let insert = profiles.insert(name <- profileName)
                _ = try? db.run(insert)
            }

        }
        catch {
            
        }
    }
    
    func recommendWords(input: String)->[String]{
        var resultSet = [String]()
        do {
            let db_path = NSSearchPathForDirectoriesInDomains(
                .documentDirectory, .userDomainMask, true).first!
            let db = try Connection("\(db_path)/db.sqlite3")
            
            let containers = Table("Containers")
            let profile = Expression<String>("profile")
            let ngram = Expression<String>("ngram")
            let frequency = Expression<Int64>("frequency")
            let userProfile = UserDefaults.standard.value(forKey: "profile")
            for row in try db.prepare(containers.filter(profile == userProfile as! String)
                                                .filter(ngram.like("\(input)%"))
                                                .order(frequency.desc, ngram)) {
                resultSet.append(row[ngram])
            }
        }
        catch {
            print("There was an error while fetching recommendations")
        }
        return resultSet
    }
    
}
