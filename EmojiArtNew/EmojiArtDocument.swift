//
//  EmojiArtDocument.swift
//  EmojiArtNew
//
//  Created by Chen Weiru on 18/03/2018.
//  Copyright © 2018 ChenWeiru. All rights reserved.
//

import UIKit

class EmojiArtDocument: UIDocument {
    
    override func contents(forType typeName: String) throws -> Any {
        // Encode your document with an instance of NSData or NSFileWrapper
        return Data()
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        // Load your document from contents
    }
}

