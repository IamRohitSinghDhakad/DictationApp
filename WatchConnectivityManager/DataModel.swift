//
//  DataModel.swift
//  DictationApp
//
//  Created by Dhakad on 09/06/23.
//

import Foundation

struct UserAudioData:Codable {
    
    let fileName:String
    let fileExtension:String
    let audioData:Data
    
    func encodeIt() -> Data {
        let data = try! PropertyListEncoder.init().encode(self)
            return data
    }
    
    static func decodeIt(_ data:Data) -> UserAudioData {
        let user = try! PropertyListDecoder.init().decode(UserAudioData.self, from: data)
        return user
    }
    
}
