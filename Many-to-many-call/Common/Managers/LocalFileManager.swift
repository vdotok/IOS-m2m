//
//  LocalFileManager.swift
//  One-to-one-call-demo
//
//  Created by Asif Ayub on 6/16/21.
//

import Foundation


class DirectoryHelper {
    
    let fileManager = FileManager.default
    let documentsPath: String = "\(NSHomeDirectory())/Documents"
    
    
    @discardableResult func touch(directory: String) -> Bool {
        guard !fileManager.fileExists(atPath: directory) else { return true}
        do {
            try fileManager.createDirectory(atPath: directory, withIntermediateDirectories: true, attributes: nil)
            return true
        } catch {
            return false
        }
    }
}

class LocalFileManager: DirectoryHelper {
    
    private var dirPath: String { documentsPath.appending("/VDOtok") }
    
    func touchConversationDirectory() {
        touch(directory: dirPath)
    }
    
    func save(record: String) {
        touchConversationDirectory()
        do {
            let data = record.data(using: .utf8) ?? Data()
            let filePath = dirPath + "/CallingData.text"
            if fileManager.fileExists(atPath: filePath) == false {
                fileManager.createFile(atPath: filePath, contents: data, attributes: nil)
            } else {
                if let fileHandle = FileHandle(forWritingAtPath: filePath) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                } else {
                    try data.write(to: URL(string: filePath)!)
                }
            }
        } catch {
            print(error)
        }
    }
}
