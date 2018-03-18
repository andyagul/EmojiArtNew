//
//  EmojiArt.swift
//  EmojiArt
//
//  Created by Chen Weiru on 17/03/2018.
//  Copyright © 2018 ChenWeiru. All rights reserved.
//

import Foundation

struct EmojiArt: Codable {
    var url:URL
    var emojis = [EmojiInfo]()
    
    struct EmojiInfo:Codable {
        let x: Int
        let y: Int
        let text: String
        let size: Int
    }
    
    var json:Data?{
        return try? JSONEncoder().encode(self)
    }
    
    init? (json:Data){
        if let newVaule = try? JSONDecoder().decode(EmojiArt.self, from: json){
            self = newVaule
        }else{
            return nil
        }
        
    }
    
    init(url: URL, emojis:[EmojiInfo]) {
        self.url = url
        self.emojis = emojis
    }
}
