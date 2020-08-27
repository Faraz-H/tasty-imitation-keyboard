//
////
////  Database.swift
////  TastyImitationKeyboard
////
////  Created by Zack Burns on 10/16/16.
////  Copyright © 2016 Apple. All rights reserved.
////
//import UIKit
//import SQLite
//
//
//class dbObjects {
//    
//    static func db_path_func() -> String {
//        if let dbpath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
//            return dbpath
//        } else {
//            return ""
//        }
//    }
//    
//    struct Ngrams {
//        let table = Table("Ngrams")
//        let gram = Expression<String>("gram")
//        let n = Expression<Int>("n")
//        let frequency = Expression<Float64>("frequency")
//    }
//    
//    struct Profiles {
//        let table = Table("Profiles")
//        let profileId = Expression<Int64>("profileId")
//        let name = Expression<String>("name")
//        let linksTo = Expression<Int64>("linksTo")
//        let order = Expression<Int>("order")
//    }
//    
//    struct Containers {
//        let table = Table("Containers")
//        let containerId = Expression<Int64>("containerId")
//        let profile = Expression<String>("profile")
//        let ngram = Expression<String>("ngram")
//        let n = Expression<Int>("n")
//        let dataSource = Expression<String>("dataSource")
//        let frequency = Expression<Float64>("frequency")
//        let lastused = Expression<Date>("lastused")
//    }
//    
//    struct Phrases {
//        let table = Table("Phrases")
//        let phraseId = Expression<Int64>("id")
//        let phrase = Expression<String>("phrase")
//        let order = Expression<Int>("order")
//    }
//    
//    struct DataSources {
//        let table = Table("DataSources")
//        let profile = Expression<String>("profile")
//        let title = Expression<String>("title")
//        let source = Expression<String>("source")
//    }
//    
//}
//
//class Database: NSObject {
//    
//    var dbCreated = false
//    var progressBar:UIProgressView? = nil
//    var numElements = 30000
//    var unigramDict = [String: Int]()
//    var counter:Int = 0 {
//        didSet {
//            let progress = Float(counter) / Float(self.numElements)
//            let animated = counter != 0
//            if self.progressBar != nil {
//                self.progressBar?.setProgress(progress, animated: animated)
//            }
//        }
//    }
//    
//    func arrayFromContentsOfFileWithName(file: String) {
//        let path = Bundle.main.path(forResource: "1grams", ofType: "txt")
//        
//        //reading
//        if let pathUnwrapped = path {
//            do {
//                let text = try String(contentsOfFile:pathUnwrapped, encoding: String.Encoding.utf8).components(separatedBy: "\n")
//                var i = 0
//                for val in text{
//                    i = i+1
//                    if i>1000{
//                        break
//                    }
//                    let keyValPair = val.components(separatedBy: " ")
//                    unigramDict[keyValPair[1]] = Int(keyValPair[0])
//                }
//            } catch {
//                // TODO need catch statement (at very least)
//            }
//        }
//    }
//    
//    override init() {
//        super.init()
//    }
//    
//    init(progressView:UIProgressView, numElements:Int) {
//        super.init()
//        self.numElements = numElements
//        self.progressBar = progressView
//        //self.resetDatabase()
//        do {
//            let db_path = dbObjects.db_path_func()
//            let db = try SingletonConnection.sharedInstance.connection("\(db_path)/db.sqlite3")
//            
//            // Database object references
//            let ngrams = dbObjects.Ngrams()
//            let profiles = dbObjects.Profiles()
//            let containers = dbObjects.Containers()
//            let phrases = dbObjects.Phrases()
//            let data_sources = dbObjects.DataSources()
//            
//            // Create Ngrams table
//            _ = try? db.run(ngrams.table.create(ifNotExists: true) { t in
//                t.column(ngrams.gram, primaryKey: true)
//                t.column(ngrams.n)
//                t.column(ngrams.frequency)
//            })
//            
//            // Create Profiles table
//            _ = try? db.run(profiles.table.create(ifNotExists: true) { t in
//                t.column(profiles.profileId, primaryKey: .autoincrement)
//                t.column(profiles.name)
//                t.column(profiles.order)
//                t.column(profiles.linksTo, defaultValue: 0)
//            })
//            
//            // Insert the Default profile into the Profiles table if it doesn't exist
//            
//            if (try db.scalar(profiles.table.filter(profiles.name == "Default").count)) == 0 {
//                let insert = profiles.table.insert(profiles.name <- "Default", profiles.order <- 0)
//                _ = try? db.run(insert)
//            }
//            
//            // Create Containers table (pairing of profile and ngram)
//            _ = try? db.run(containers.table.create(ifNotExists: true) { t in
//                t.column(containers.containerId, primaryKey: .autoincrement)
//                t.column(containers.profile)
//                t.column(containers.ngram)
//                t.column(containers.n)
//                t.column(containers.dataSource, defaultValue: "")
//                t.column(containers.frequency, defaultValue: 0)
//                t.column(containers.lastused, defaultValue: Date())
//                // - - - - - - - - - - - -
//                t.unique(containers.profile, containers.ngram)
//            })
//            
//            // Create Phrases table so user can store pre-defined phrases
//            _ = try? db.run(phrases.table.create(ifNotExists: true) { t in
//                t.column(phrases.phraseId, primaryKey: .autoincrement)
//                t.column(phrases.order)
//                t.column(phrases.phrase)
//            })
//            
//            // Create DataSource table
//            _ = try? db.run(data_sources.table.create(ifNotExists: true) { t in
//                t.column(data_sources.profile)
//                t.column(data_sources.title)
//                t.column(data_sources.source)
//            })
//            
//            var pathToWords: String = ""
//            if let bundlePathUnwrapped = Bundle.main.path(forResource: "1grams", ofType: "txt") {
//                pathToWords = bundlePathUnwrapped
//            } else {
//                pathToWords = ""
//            }
//            
//            let wordsContent = try String(contentsOfFile:pathToWords, encoding: String.Encoding.utf8)
//            let allWords = wordsContent.components(separatedBy: "\n")
//            
//            var pathToTwoGrams: String = ""
//            if let pathToTwoGramsUnwrapped = Bundle.main.path(forResource: "2grams-10000", ofType: "txt") {
//                pathToTwoGrams = pathToTwoGramsUnwrapped
//            } else {
//                pathToTwoGrams = ""
//            }
//            let twoGramsContent = try String(contentsOfFile:pathToTwoGrams,
//                                             encoding: String.Encoding.utf8)
//            // The format of the items in allTwoGrams is: <freq>\t<word1>\t<word2>
//            let allTwoGrams = twoGramsContent.components(separatedBy: "\r\n")
//            
//            var pathToThreeGrams: String = ""
//            if let pathToThreeGramsUnwrapped = Bundle.main.path(forResource: "3grams-10000", ofType: "txt") {
//                pathToThreeGrams = pathToThreeGramsUnwrapped
//            } else {
//                pathToThreeGrams = ""
//            }
//            let threeGramsContent = try String(contentsOfFile:pathToThreeGrams, encoding: String.Encoding.utf8)
//            // The format of the items in allThreeGrams is: <freq>\t<word1>\t<word2>\t<word3>
//            let allThreeGrams = threeGramsContent.components(separatedBy: "\r\n")
//            
//            self.counter = 0
//            
//            // Check to make sure Database has been created
//            //if self.dbCreated == true {
//            if (try db.scalar(containers.table.count)) != 0 {
//                return
//            }
//                
//                // If not, then insert the missing words
//            else {
//                var ngrams_added = Set<String>()
//                let bulk_ngrams_insert = "INSERT INTO Ngrams (gram, n, frequency) VALUES "
//                let bulk_containers_insert = "INSERT INTO Containers (profile, ngram, n, frequency) VALUES "
//                
//                var ngrams = [String]()
//                var containers = [String]()
//                
//                // Populate the Ngrams table and Container table with words
//                for word in allWords {
//                    if word == "" || word == " " {
//                        break
//                    }
//                    let wordComponents = word.components(separatedBy: " ")
//                    let frequency:Float64 = Float64(wordComponents[0]) ?? 0.0
//                    let oneGram = wordComponents[1]
//                    
//                    ngrams.append("(\"\(oneGram)\",1,\(frequency)), ")
//                    containers.append("(\"Default\",\"\(oneGram)\",1,\(frequency)), ")
//                    
//                    ngrams_added.insert(oneGram)
//                    
//                    DispatchQueue.main.async {
//                        self.counter += 1
//                        return
//                    }
//                }
//                self.counter = 9735
//                
//                for twoGram in allTwoGrams {
//                    if twoGram == "" {
//                        break
//                    }
//                    let twoGramComponents = twoGram.components(separatedBy: "\t")
//                    var insertNgram = ""
//                    var insert_n = Int()
//                    let freq:Float64 = Float64(twoGramComponents[0]) ?? 0.0
//                    // if the word2 is "n't" then combine word1 and word2 and insert with n=1
//                    if twoGramComponents[2] == "n't" {
//                        insertNgram = twoGramComponents[1]+twoGramComponents[2]
//                        insert_n = 1
//                    }
//                        // else insert with n=2
//                    else {
//                        insertNgram = twoGramComponents[1]+" "+twoGramComponents[2]
//                        insert_n = 2
//                    }
//                    
//                    if !ngrams_added.contains(insertNgram) {//result! == 0 {
//                        ngrams.append("(\"\(insertNgram)\",\(insert_n),\(freq)), ")
//                        containers.append("(\"Default\",\"\(insertNgram)\",\(insert_n),\(freq)), ")
//                        
//                        ngrams_added.insert(insertNgram)
//                    }
//                    
//                    DispatchQueue.main.async {
//                        self.counter += 1
//                        return
//                    }
//                }
//                self.counter = 20000
//                
//                for threeGram in allThreeGrams {
//                    if threeGram == "" {
//                        break
//                    }
//                    let threeGramComponents = threeGram.components(separatedBy: "\t")
//                    var word1 = threeGramComponents[1]
//                    let word2 = threeGramComponents[2]
//                    let word3 = threeGramComponents[3]
//                    var insertNgram = ""
//                    var insert_n = Int()
//                    let freq:Float64 = Float64(threeGramComponents[0]) ?? 0.0
//                    // handle different cases of 3grams like we did with 2grams
//                    if word1 == "n't" {
//                        word1 = "not"
//                    }
//                    if word2 == "n't" {
//                        insertNgram = word1+word2+" "+word3
//                        insert_n = 2
//                    }
//                    else if word3 == "n't" {
//                        insertNgram = word1+" "+word2+word3
//                        insert_n = 2
//                    }
//                    else {
//                        insertNgram = word1+" "+word2+" "+word3
//                        insert_n = 3
//                    }
//                    
//                    if !ngrams_added.contains(insertNgram) {//result! == 0 {
//                        ngrams.append("(\"\(insertNgram)\",\(insert_n),\(freq)), ")
//                        containers.append("(\"Default\",\"\(insertNgram)\",\(insert_n),\(freq)), ")
//                        
//                        ngrams_added.insert(insertNgram)
//                    }
//                    
//                    DispatchQueue.main.async {
//                        self.counter += 1
//                        return
//                    }
//                }
//                self.counter = 30000
//                // --------------------------
//                var ngrams_query = bulk_ngrams_insert
//                for i in 0..<ngrams.count {
//                    ngrams_query.append(ngrams[i])
//                    
//                    if(i % 1000 == 0) {
//                        ngrams_query = String(ngrams_query.dropLast(2))+";"
//                        _ = try db.run(ngrams_query)
//                        ngrams_query = bulk_ngrams_insert
//                    }
//                }
//                
//                var containers_query = bulk_containers_insert
//                for i in 0..<containers.count {
//                    containers_query.append(containers[i])
//                    
//                    if(i % 1000 == 0) {
//                        containers_query = String(containers_query.dropLast(2))+";"
//                        _ = try db.run(containers_query)
//                        containers_query = bulk_containers_insert
//                    }
//                }
//                // --------------------------
//                self.dbCreated = true
//            }
//        }
//        catch {
//            print("Error: \(error)")
//        }
//    }
//    
//    func insertIntoNgrams(input_ngram: String, n: Int) {
//        do {
//            let db_path = dbObjects.db_path_func()
//            let db = try SingletonConnection.sharedInstance.connection("\(db_path)/db.sqlite3")
//            
//            let ngrams = dbObjects.Ngrams()
//            let insert = ngrams.table.insert(ngrams.gram <- input_ngram, ngrams.n <- n)
//            _ = try? db.run(insert)
//        } catch {}
//    }
//    
//    func insertAndIncrement(ngram: String, n: Int, new_freq: Float64 = -1.0) {
//        do {
//            let db_path = dbObjects.db_path_func()
//            let db = try SingletonConnection.sharedInstance.connection("\(db_path)/db.sqlite3")
//            let containers = dbObjects.Containers()
//            let currentProfile = UserDefaults.standard.value(forKey: "profile") as! String
//            
//            // if ngram notExists in database
//            /*let exists_in_profile = try db.scalar(containers.table
//             .filter(containers.ngram == ngram)
//             .filter(containers.profile == currentProfile)
//             .count) > 0
//             let exists_in_default = try db.scalar(containers.table
//             .filter(containers.ngram == ngram)
//             .filter(containers.profile == "Default")
//             .count) > 0*/
//            if true { //(!exists_in_profile) {
//                // insert ngram into profile
//                let insert = containers.table.insert(containers.ngram <- ngram,
//                                                     containers.profile <- currentProfile,
//                                                     containers.n <- n)
//                _ = try? db.run(insert)
//            }
//            if true {//(!exists_in_default) {
//                // insert ngram into Default
//                let insert = containers.table.insert(containers.ngram <- ngram,
//                                                     containers.profile <- "Default",
//                                                     containers.n <- n)
//                _ = try? db.run(insert)
//            }
//            
//            if new_freq == -1 {
//                // increment ngram in current_profile and default cases
//                _ = try db.run(containers.table.filter(containers.ngram == ngram)
//                    .filter(containers.profile == currentProfile)
//                    .update(containers.frequency += 1.0, containers.lastused <- Date()))
//                _ = try db.run(containers.table.filter(containers.ngram == ngram)
//                    .filter(containers.profile == "Default")
//                    .update(containers.frequency += 1.0, containers.lastused <- Date()))
//            }
//            else {
//                // set the frequency to the one provided
//                _ = try db.run(containers.table.filter(containers.ngram == ngram)
//                    .filter(containers.profile == currentProfile)
//                    .update(containers.frequency += new_freq, containers.lastused <- Date()))
//                _ = try db.run(containers.table.filter(containers.ngram == ngram)
//                    .filter(containers.profile == "Default")
//                    .update(containers.frequency += new_freq, containers.lastused <- Date()))
//            }
//        }
//        catch {
//            print("Something failed in insertAndIncrement()")
//            print("Error: \(error)")
//        }
//    }
//    
//    func typoList(word: String) -> Set<String> {
//        if word.isEmpty { return ["hello"] }
//        
//        var wordCombos = [(String,String)]()
//        
//        for index in 0...word.count-1 {
//            wordCombos.append((String(word.prefix(index)), String(word.suffix(word.count-index))))
//        }
//        
//        var removeLetters = [String]()
//        
//        wordCombos.forEach{str1,str2 in
//            let str2String = String(str2.dropFirst())
//            removeLetters.append("\(str1)\(str2String)")
//        }
//        
//        
//        let shifts: [String] = wordCombos.map { left, right in
//            if let fst = right.first {
//                let drop1 = right.dropFirst()
//                if let snd = drop1.first {
//                    let drop2 = drop1.dropFirst()
//                    return "\(String(describing: String(left)))\(String(snd))\(String(fst))\(String(drop2))"
//                }
//            }
//            return ""
//            }.filter { !$0.isEmpty }
//        
//        let letters = "abcdefghijklmnopqrstuvwxyz"
//        
//        let replaces = wordCombos.flatMap { left, right in
//            letters.map { "\(left)\(String($0))\(String(right.dropFirst()))" }
//        }
//        
//        let inserts = wordCombos.flatMap { left, right in
//            letters.map { "\(left)\($0)\(right)" }
//        }
//        
//        removeLetters.append(word)
//        
//        return Set(removeLetters + shifts + replaces + inserts)
//    }
//    
//    func arrayOfCommonElements <T, U> (lhs: T, rhs: U) -> [T.Iterator.Element] where T: Sequence, U: Sequence, T.Iterator.Element: Equatable, T.Iterator.Element == U.Iterator.Element {
//        var returnArray:[T.Iterator.Element] = []
//        for lhsItem in lhs {
//            for rhsItem in rhs {
//                if lhsItem == rhsItem {
//                    returnArray.append(lhsItem)
//                }
//            }
//        }
//        return returnArray
//    }
//    
//    
//    func recommendationQuery(user_profile: String, n: Int, pattern: String,
//                             words: [String], result_set: Set<String>, numResults:Int) -> Set<String> {
//        
//        if result_set.count >= numResults {
//            return result_set
//        }
//        
//        // Copy result_set into resultSet so we can manipulate resultSet
//        var resultSet = result_set
//        
//        let word1 = words[0]
//        let word2 = words[1]
//        let current_input = words[2]
//        
//        do {
//            let db_path = dbObjects.db_path_func()
//            let db = try SingletonConnection.sharedInstance.connection("\(db_path)/db.sqlite3")
//            let containers = dbObjects.Containers()
//            
//            for row in try db.prepare(containers.table
//                .filter(containers.profile == user_profile)
//                .filter(containers.ngram.like(pattern))
//                .filter(containers.ngram != current_input)
//                .filter(containers.ngram != "")
//                .filter(containers.n == n)
//                .order(containers.frequency.desc, containers.ngram)
//                .limit(numResults, offset: 0)) {
//                    // This wall have a different number of components for different patterns!
//                    let row_components = row[containers.ngram].components(separatedBy: " ")
//                    
//                    // POSSIBLE PATTERNS
//                    // 3:      "\(word1) \(word2) \(current_input)%"
//                    // 3:      "% \(word2) \(current_input)%"
//                    // 3 & 2:  "\(word2) \(current_input)%"
//                    // 2 & 1:  "\(current_input)%"
//                    
//                    if resultSet.count < numResults {
//                        if n == 3 {
//                            if pattern == "\(word1) \(word2) \(current_input)%" {
//                                resultSet.insert(row_components[2])
//                            }
//                            else if pattern == "\(word2) \(current_input)%" {
//                                resultSet.insert(row_components[1]+" "+row_components[2])
//                            }
//                        }
//                        else if n == 2 {
//                            if pattern == "\(word2) \(current_input)%" {
//                                resultSet.insert(row_components[1])
//                            }
//                            else if pattern == "\(current_input)%" {
//                                resultSet.insert(row_components[0]+" "+row_components[1])
//                            }
//                        }
//                        else /* n == 1 */ {
//                            resultSet.insert(row[containers.ngram])
//                        }
//                    }
//            }
//        } catch {
//            print("Something went wrong when fetching \(n)grams for input '\(current_input)' in \(user_profile)")
//            print("Error: \(error)")
//        }
//        return resultSet
//    }
//    
//    /*
//     enum ShiftState {
//     case disabled
//     case enabled
//     case locked
//     }
//     */
//    
//    func recommendWords(word1: String = "", word2: String = "", current_input: String,
//                        shift_state: ShiftState = ShiftState.disabled, numResults:Int)->Set<String>{
//        // POSSIBLE PATTERNS
//        // 3:      "\(word1) \(word2) \(current_input)%"
//        // 3:      "% \(word2) \(current_input)%" ********* <--- maybe not
//        // 3 & 2:  "\(word2) \(current_input)%"
//        // 2 & 1:  "\(current_input)%"
//        
//        var resultSet = Set<String>()
//        let userProfile = UserDefaults.standard.value(forKey: "profile") as! String
//        let words = [word1, word2, current_input]
//        
//        /*
//         .filter(containers.profile == user_profile)
//         .filter(containers.ngram.like(pattern))
//         .filter(containers.ngram != current_input)
//         .filter(containers.ngram != "")
//         .filter(containers.n == n)
//         .order(containers.frequency.desc, containers.ngram)*/
//        
//        /*let raw_SQL =   "SELECT * FROM Containers " +
//         "WHERE profile = \"\(userProfile)\" " +
//         "AND ngram LIKE \"\(current_input)%\" " +
//         "AND ngram != \"\(current_input)\" " +
//         "AND ngram != \"\" " +
//         "AND (n = 1 OR n = 2) " +
//         "UNION " + //////////
//         "SELECT * FROM Containers " +
//         "WHERE profile = \"\(userProfile)\" " +
//         "AND ngram LIKE \"\(word2) \(current_input)%\" " +
//         "AND ngram != \"\(current_input)\" " +
//         "AND ngram != \"\" " +
//         "AND (n = 2 OR n = 3) " +
//         "UNION " + //////////
//         "SELECT * FROM Containers " +
//         "WHERE profile = \"\(userProfile)\" " +
//         "AND ngram LIKE \"\(word1) \(word2) \(current_input)%\" " +
//         "AND ngram != \"\(current_input)\" " +
//         "AND ngram != \"\" " +
//         "AND n = 3 " +
//         "ORDER BY n DESC, frequency DESC; " ///////// */
//        /*let raw_SQL =   "SELECT * FROM Containers " +
//         "WHERE profile = \"\(userProfile)\" " +
//         "AND ngram != \"\(current_input)\" " +
//         "AND ngram != \"\" " +
//         "AND ((ngram LIKE \"\(current_input)%\" " +
//         "AND (n = 1 OR n = 2)) " +
//         "OR (ngram LIKE \"\(word2) \(current_input)%\" " +
//         "AND (n = 2 OR n = 3)) " +
//         "OR (ngram LIKE \"\(word1) \(word2) \(current_input)%\" " +
//         "AND n = 3)) " +
//         "ORDER BY n DESC, frequency DESC; " //////////
//         do {
//         let db_path = dbObjects.db_path_func()
//         let db = try SingletonConnection.sharedInstance.connection("\(db_path)/db.sqlite3")
//         let containers = dbObjects.Containers()
//         let statement = try db.prepare(raw_SQL)
//         for (a,s) in statement.columnNames.enumerated() {
//         if resultSet.count >= 15 {
//         break
//         }
//         //resultSet.insert(row[containers.ngram])
//         }
//         }
//         catch {
//         print("Error: \(error)")
//         }*/
//        
//        
//        
//        if word1 != "" && word2 != "" {
//            resultSet = recommendationQuery(user_profile: userProfile,
//                                            n: 3, pattern: "\(word1) \(word2) \(current_input)%",
//                words: words, result_set: resultSet, numResults: numResults)
//            for n in [2,3] {
//                resultSet = recommendationQuery(user_profile: userProfile,
//                                                n: n, pattern: "\(word2) \(current_input)%",
//                    words: words, result_set: resultSet, numResults: numResults)
//            }
//            for n in [1,2] {
//                resultSet = recommendationQuery(user_profile: userProfile,
//                                                n: n, pattern: "\(current_input)%",
//                    words: words, result_set: resultSet, numResults: numResults)
//            }
//        }
//            
//        else if word1 == "" && word2 != "" {
//            for n in [2,3] {
//                resultSet = recommendationQuery(user_profile: userProfile,
//                                                n: n, pattern: "\(word2) \(current_input)%",
//                    words: words, result_set: resultSet, numResults: numResults)
//            }
//            for n in [1,2] {
//                resultSet = recommendationQuery(user_profile: userProfile,
//                                                n: n, pattern: "\(current_input)%",
//                    words: words, result_set: resultSet, numResults: numResults)
//            }
//        }
//            
//        else /* word1 and word2 are empty */ {
//            resultSet = recommendationQuery(user_profile: userProfile,
//                                            n: 1, pattern: "\(current_input)%",
//                words: words, result_set: resultSet, numResults: numResults)
//        }
//        
//        
//        if resultSet.count < numResults {
//            let typoWords = self.typoList(word: current_input)
//            if self.unigramDict.count == 0 {
//                // Try to fix a possible crash by making sure the dictionary is valid; the thought is that
//                // there is a life cycle issue going on that's tearing down this object at some point, then
//                // trying to continue to use it (unprovoen, but suspected).
//                self.unigramDict = [String: Int]()
//                self.arrayFromContentsOfFileWithName(file: "Keyboard/1grams.txt")
//            }
//            let arrayKeys = Array(self.unigramDict.keys)
//            var typoList:[(word:String,value:Int)] = []
//            for word in typoWords{
//                var wordContained = false
//                var wordToAdd = ""
//                for tempWord in arrayKeys {
//                    if tempWord.hasPrefix(word) {
//                        wordContained = true
//                        wordToAdd = tempWord
//                        break
//                    }
//                }
//                if (wordContained){
//                    if let unigramDictWordToAdd = self.unigramDict[wordToAdd] {
//                        typoList.append((word:wordToAdd, value:unigramDictWordToAdd))
//                    }
//                }
//            }
//            typoList.sort {$0.value > $1.value}
//            for tuple in typoList {
//                if resultSet.count < numResults {
//                    resultSet.insert(tuple.word)
//                }
//            }
//            /*if typoList.count > 1{
//             resultSet.insert(typoList[0])
//             }
//             if typoList.count > 2{
//             resultSet.insert(typoList[1])
//             }*/
//        }
//        
//        // Fix resultSet based on the ShiftState
//        //  disabled: do nothing
//        //  enabled: capitalize the first letter
//        //  locked: make everything CAPS
//        for word in resultSet {
//            if shift_state == ShiftState.disabled {
//                break
//            }
//            else if shift_state == ShiftState.enabled {
//                let placeholder = word.capitalized
//                resultSet.remove(word)
//                resultSet.insert(placeholder)
//            }
//            else if shift_state == ShiftState.locked{
//                let placeholder = word.uppercased()
//                resultSet.remove(word)
//                resultSet.insert(placeholder)
//            }
//        }
//        
//        for word in resultSet {
//            if (current_input != "" && current_input == current_input.capitalized && shift_state == .disabled) {
//                let placeholder = word.capitalized
//                resultSet.remove(word)
//                resultSet.insert(placeholder)
//            }
//            else {
//                break
//            }
//        }
//        
//        return resultSet
//    }
//    
//    
//    func checkProfile(profile_name: String) ->Bool {
//        do {
//            let db_path = dbObjects.db_path_func()
//            let db = try SingletonConnection.sharedInstance.connection("\(db_path)/db.sqlite3")
//            let profiles = dbObjects.Profiles()
//            //let count = try db.scalar(profiles.table.count)
//            let count = try db.scalar(profiles.table.filter(profiles.name == profile_name).count)
//            if count > 0 {
//                return false
//            }
//            else {
//                return true
//            }
//        }
//        catch {
//            return false
//        }
//    }
//    
//    func addProfile(profile_name:String) -> Bool{
//        do {
//            let db_path = dbObjects.db_path_func()
//            let db = try SingletonConnection.sharedInstance.connection("\(db_path)/db.sqlite3")
//            
//            // Insert the new profile into the database
//            let profiles = dbObjects.Profiles()
//            let count = try db.scalar(profiles.table.count)
//            let insert = profiles.table.insert(profiles.name <- profile_name, profiles.order <- count)
//            _ = try? db.run(insert) // will throw error if profile already exists
//            
//            // Insert all of the original words into the new profile
//            let ngrams = dbObjects.Ngrams()
//            
//            self.counter = 0
//            var bulk_insert = "INSERT INTO Containers (profile, ngram, n, frequency) VALUES "
//            
//            for row in try db.prepare(ngrams.table) {
//                bulk_insert.append("(\"\(profile_name)\",\"\(row[ngrams.gram])\",\(row[ngrams.n]),\(row[ngrams.frequency])), ")
//                
//                DispatchQueue.main.async {
//                    self.counter += 1
//                    return
//                }
//            }
//            self.counter = 30000
//            
//            _ = try? db.run(String(bulk_insert.dropLast(2))+";")
//            print()
//            for p in try db.prepare(profiles.table) {
//                print("profile: \(p[profiles.name]), order: \(p[profiles.order]), id: \(p[profiles.profileId])")
//            }
//            print("--------")
//        } catch {
//            print("Something failed while trying to add new profile")
//            print("Error: \(error)")
//            return false
//        }
//        return true
//    }
//    
//    
//    // WARNING: NOT TESTED YET
//    func deleteProfile(profile_name: String) {
//        do {
//            let db_path = dbObjects.db_path_func()
//            let db = try SingletonConnection.sharedInstance.connection("\(db_path)/db.sqlite3")
//            let profiles = dbObjects.Profiles()
//            
//            //decrement the row order variable of all other profiles
//            var oldRowNum:Int?
//            //this for loop should only have one element, but I dont know how to do it without a loop
//            for row in try db.prepare(profiles.table.filter(profiles.name == profile_name)) {
//                oldRowNum = row[profiles.order]
//            }
//            if oldRowNum != nil {
//                if let oldRowNumUnwrapped = oldRowNum {
//                    _ = try db.run(profiles.table.filter(profiles.order > oldRowNumUnwrapped).update(profiles.order--))
//                }
//            }
//            
//            // Delete profile from Profiles
//            _ = try db.run(profiles.table.filter(profiles.name == profile_name).delete())
//            
//            // Delete all ngrams associated with profile from Containers
//            let containers = dbObjects.Containers()
//            _ = try db.run(containers.table.filter(containers.profile == profile_name).delete())
//            
//            // Delete all data sources associated with profile
//            let data_sources = dbObjects.DataSources()
//            _ = try db.run(data_sources.table.filter(data_sources.profile == profile_name).delete())
//            
//            print()
//            for p in try db.prepare(profiles.table) {
//                print("profile: \(p[profiles.name]), order: \(p[profiles.order]), id: \(p[profiles.profileId])")
//            }
//            print("--------")
//            
//        } catch {
//            print("Something failed while trying to delete profile")
//            print("Error: \(error)")
//        }
//    }
//    
//    // WARNING: NOT TESTED YET
//    func editProfileName(current_name: String, new_name: String) {
//        do {
//            let db_path = dbObjects.db_path_func()
//            let db = try SingletonConnection.sharedInstance.connection("\(db_path)/db.sqlite3")
//            
//            let profiles = dbObjects.Profiles()
//            let containers = dbObjects.Containers()
//            let data_sources = dbObjects.DataSources()
//            
//            _ = try db.run(profiles.table
//                .filter(profiles.name == current_name)
//                .update(profiles.name <- new_name))
//            _ = try db.run(containers.table
//                .filter(containers.profile == current_name)
//                .update(containers.profile <- new_name))
//            _ = try db.run(data_sources.table
//                .filter(data_sources.profile == current_name)
//                .update(data_sources.profile <- new_name))
//        } catch {
//            print("Something failed while editing profile name")
//            print("Error: \(error)")
//        }
//    }
//    
//    func reorderProfiles(profileName: String, newRowNum: Int) {
//        
//        let profiles = dbObjects.Profiles()
//        do {
//            let db_path = dbObjects.db_path_func()
//            let db = try SingletonConnection.sharedInstance.connection("\(db_path)/db.sqlite3")
//            print("---\(profileName), \(newRowNum)---")
//            for p in try db.prepare(profiles.table) {
//                print("phrase: \(p[profiles.name]), order: \(p[profiles.order]), id: \(p[profiles.profileId])")
//            }
//            var oldRowNum:Int?
//            //this for loop should only have one element, but I dont know how to do it without a loop
//            for row in try db.prepare(profiles.table.filter(profiles.name == profileName)) {
//                oldRowNum = row[profiles.order]
//            }
//            
//            if let oldRowNumUnwrapped = oldRowNum {
//                if oldRowNumUnwrapped > newRowNum {
//                    _ = try db.run(profiles.table.filter(profiles.order >= newRowNum && profiles.order < oldRowNumUnwrapped).update(profiles.order++))
//                }
//                else if newRowNum > oldRowNumUnwrapped {
//                    _ = try db.run(profiles.table.filter(profiles.order > oldRowNumUnwrapped && profiles.order <= newRowNum).update(profiles.order--))
//                }
//            }
//            
//            try db.run(profiles.table.filter(profiles.name == profileName)
//                .update(profiles.order <- newRowNum))
//            
//            print()
//            for p in try db.prepare(profiles.table) {
//                print("phrase: \(p[profiles.name]), order: \(p[profiles.order]), id: \(p[profiles.profileId])")
//            }
//            print("--------")
//        }
//        catch {
//            print("update failed: \(error)")
//        }
//    }
//    
//    // WARNING: NOT TESTED YET
//    func getProfiles() -> [String] {
//        var profiles_list: [String] = []
//        do {
//            let db_path = dbObjects.db_path_func()
//            let db = try SingletonConnection.sharedInstance.connection("\(db_path)/db.sqlite3")
//            
//            let profiles = dbObjects.Profiles()
//            for row in try db.prepare(profiles.table.order(profiles.order.asc)) {
//                print(profiles.name)
//                profiles_list.append(row[profiles.name])
//            }
//        } catch {
//            print("Something failed while getting list of profiles")
//            print("Error: \(error)")
//        }
//        return profiles_list
//    }
//    
//    func checkDataSource(targetProfile:String, dataSource: String) ->Bool {
//        do {
//            let db_path = dbObjects.db_path_func()
//            let db = try SingletonConnection.sharedInstance.connection("\(db_path)/db.sqlite3")
//            let dataSources = dbObjects.DataSources()
//            //let count = try db.scalar(profiles.table.count)
//            let count = try db.scalar(dataSources.table.filter(dataSources.source == dataSource && dataSources.profile == targetProfile).count)
//            if count > 0 {
//                return false
//            }
//            else {
//                return true
//            }
//        }
//        catch {
//            return false
//        }
//    }
//    
//    // WARNING: NOT TESTED YET
//    func addDataSource(target_profile: String, new_data_source: String, new_title: String) {
//        do {
//            let db_path = dbObjects.db_path_func()
//            let db = try SingletonConnection.sharedInstance.connection("\(db_path)/db.sqlite3")
//            
//            let data_sources = dbObjects.DataSources()
//            
//            let insert = data_sources.table.insert(data_sources.profile <- target_profile,
//                                                   data_sources.source <- new_data_source,
//                                                   data_sources.title <- new_title)
//            _ = try? db.run(insert)
//        } catch {
//            print("Something failed while trying to insert new data source")
//            print("Error: \(error)")
//        }
//    }
//    
//    // WARNING: NOT TESTED YET
//    // WARNING: only deletes the reference to the data source in the target profile,
//    //          DOES NOT delete all of the ngrams that were generated from that source
//    func removeDataSource(target_profile: String, data_source: String) {
//        do {
//            let db_path = dbObjects.db_path_func()
//            let db = try SingletonConnection.sharedInstance.connection("\(db_path)/db.sqlite3")
//            
//            let data_sources = dbObjects.DataSources()
//            let containers = dbObjects.Containers()
//            
//            _ = try db.run(data_sources.table.filter(data_sources.profile == target_profile)
//                .filter(data_sources.source == data_source).delete())
//            _ = try db.run(containers.table.filter(containers.profile == target_profile
//                || containers.profile == "Default")
//                .filter(containers.dataSource == data_source).delete())
//        } catch {
//            print("Something failed while removing data source")
//            print("Error: \(error)")
//        }
//    }
//    
//    // WARNING: NOT TESTED YET
//    func getDataSources(target_profile: String) -> [String] {
//        var data_sources_list: [String] = []
//        do {
//            let db_path = dbObjects.db_path_func()
//            let db = try SingletonConnection.sharedInstance.connection("\(db_path)/db.sqlite3")
//            
//            let data_sources = dbObjects.DataSources()
//            
//            for row in try db.prepare(data_sources.table
//                .filter(data_sources.profile == target_profile)) {
//                    data_sources_list.append(row[data_sources.source])
//            }
//        } catch {
//            print("Something failed while getting list of data sources")
//            print("Error: \(error)")
//        }
//        return data_sources_list
//    }
//    
//    func resetDatabase() {
//        let ngrams = dbObjects.Ngrams()
//        let profiles = dbObjects.Profiles()
//        let containers = dbObjects.Containers()
//        let phrases = dbObjects.Phrases()
//        let data_sources = dbObjects.DataSources()
//        do {
//            let db_path = dbObjects.db_path_func()
//            let db = try SingletonConnection.sharedInstance.connection("\(db_path)/db.sqlite3")
//            
//            _ = try? db.run(ngrams.table.drop(ifExists: true))
//            _ = try? db.run(profiles.table.drop(ifExists: true))
//            _ = try? db.run(containers.table.drop(ifExists: true))
//            _ = try? db.run(phrases.table.drop(ifExists: true))
//            _ = try? db.run(data_sources.table.drop(ifExists: true))
//            self.dbCreated = false
//        } catch {
//            print("reset failed")
//            print("Error: \(error)")
//        }
//    }
//    
//    func checkPhrase(phrase: String) ->Bool {
//        do {
//            let db_path = dbObjects.db_path_func()
//            let db = try SingletonConnection.sharedInstance.connection("\(db_path)/db.sqlite3")
//            let phrases = dbObjects.Phrases()
//            //let count = try db.scalar(profiles.table.count)
//            let count = try db.scalar(phrases.table.filter(phrases.phrase == phrase).count)
//            if count > 0 {
//                return false
//            }
//            else {
//                return true
//            }
//        }
//        catch {
//            return false
//        }
//    }
//    
//    func addPhrase(phrase: String) {
//        do {
//            let db_path = dbObjects.db_path_func()
//            let db = try SingletonConnection.sharedInstance.connection("\(db_path)/db.sqlite3")
//            
//            let phrases = dbObjects.Phrases()
//            let count = try db.scalar(phrases.table.count)
//            let insert = phrases.table.insert(phrases.phrase <- phrase, phrases.order <- count)
//            _ = try? db.run(insert)
//        }
//        catch {
//            print("Inserting a new phrase failed")
//            print("Error: \(error)")
//        }
//    }
//    
//    func editPhrase(old_phrase: String, new_phrase: String) {
//        do {
//            let db_path = dbObjects.db_path_func()
//            let db = try SingletonConnection.sharedInstance.connection("\(db_path)/db.sqlite3")
//            
//            let phrases = dbObjects.Phrases()
//            
//            _ = try db.run(phrases.table.filter(phrases.phrase == old_phrase)
//                .update(phrases.phrase <- new_phrase))
//        }
//        catch {
//            print("Editing a phrase failed")
//            print("Error: \(error)")
//        }
//    }
//    
//    func reorderPhrase(phrase: String, newRowNum: Int) {
//        
//        let phrases = dbObjects.Phrases()
//        do {
//            let db_path = dbObjects.db_path_func()
//            let db = try SingletonConnection.sharedInstance.connection("\(db_path)/db.sqlite3")
//            print("---\(phrase), \(newRowNum)---")
//            for p in try db.prepare(phrases.table) {
//                print("phrase: \(p[phrases.phrase]), order: \(p[phrases.order]), id: \(p[phrases.phraseId])")
//            }
//            var oldRowNum:Int?
//            //this for loop should only have one element, but I dont know how to do it without a loop
//            for row in try db.prepare(phrases.table.filter(phrases.phrase == phrase)) {
//                oldRowNum = row[phrases.order]
//            }
//            
//            if let oldRowNumUnwrapped = oldRowNum {
//                if oldRowNumUnwrapped > newRowNum {
//                    _ = try db.run(phrases.table.filter(phrases.order >= newRowNum && phrases.order < oldRowNumUnwrapped).update(phrases.order++))
//                }
//                else if newRowNum > oldRowNumUnwrapped {
//                    _ = try db.run(phrases.table.filter(phrases.order > oldRowNumUnwrapped && phrases.order <= newRowNum).update(phrases.order--))
//                }
//            }
//            
//            try db.run(phrases.table.filter(phrases.phrase == phrase)
//                .update(phrases.order <- newRowNum))
//            
//            print()
//            for p in try db.prepare(phrases.table) {
//                print("phrase: \(p[phrases.phrase]), order: \(p[phrases.order]), id: \(p[phrases.phraseId])")
//            }
//            print("--------")
//        }
//        catch {
//            print("update failed: \(error)")
//        }
//    }
//    
//    func deletePhrase(phrase: String) {
//        do {
//            let db_path = dbObjects.db_path_func()
//            let db = try SingletonConnection.sharedInstance.connection("\(db_path)/db.sqlite3")
//            
//            let phrases = dbObjects.Phrases()
//            var oldRowNum:Int?
//            //this for loop should only have one element, but I dont know how to do it without a loop
//            for row in try db.prepare(phrases.table.filter(phrases.phrase == phrase)) {
//                oldRowNum = row[phrases.order]
//            }
//            
//            if let oldRowNumUnwrapped = oldRowNum {
//                _ = try db.run(phrases.table.filter(phrases.order > oldRowNumUnwrapped).update(phrases.order--))
//            }
//            
//            _ = try db.run(phrases.table.filter(phrases.phrase == phrase).delete())
//        }
//        catch {
//            print("Deleting a phrase failed")
//            print("Error: \(error)")
//        }
//    }
//    
//    func getPhrases() -> [String] {
//        var phrase_list: [String] = []
//        do {
//            let db_path = dbObjects.db_path_func()
//            let db = try SingletonConnection.sharedInstance.connection("\(db_path)/db.sqlite3")
//            
//            let phrases = dbObjects.Phrases()
//            
//            for row in try db.prepare(phrases.table.order(phrases.order.asc)) {
//                phrase_list.append(row[phrases.phrase])
//            }
//        } catch {
//            print("Something failed while getting list of profiles")
//            print("Error: \(error)")
//        }
//        return phrase_list
//    }
//    
//    func getNgramsFromProfile(profile: String) -> Set<String> {
//        var resultSet = Set<String>()
//        do {
//            let db_path = dbObjects.db_path_func()
//            let db = try SingletonConnection.sharedInstance.connection("\(db_path)/db.sqlite3")
//            let containers = dbObjects.Containers()
//            
//            for row in try db.prepare(containers.table.filter(containers.profile == profile)) {
//                resultSet.insert(row[containers.ngram])
//            }
//        }
//        catch {
//            print("Error: \(error)")
//        }
//        return resultSet
//    }
//    
//}
//
