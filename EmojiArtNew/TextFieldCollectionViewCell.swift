 //
//  TextFieldCollectionViewCell.swift
//  EmojiArt
//
//  Created by Chen Weiru on 16/03/2018.
//  Copyright © 2018 ChenWeiru. All rights reserved.
//

import UIKit

class TextFieldCollectionViewCell: UICollectionViewCell, UITextFieldDelegate {
    
    @IBOutlet weak var textField: UITextField!{
        didSet{
            textField.delegate = self
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    var reginationHandler:(() -> Void)?
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        reginationHandler?()
    }

}
