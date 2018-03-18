//
//  EmojiViewController.swift
//  EmojiArt
//
//  Created by Chen Weiru on 11/03/2018.
//  Copyright © 2018 ChenWeiru. All rights reserved.
//

import UIKit


extension EmojiArt.EmojiInfo{
    init?(label: UILabel) {
        if let attributeText = label.attributedText, let font = attributeText.font{
            x = Int(label.center.x)
            y = Int(label.center.y)
            text = attributeText.string
            size = Int(font.pointSize)
        }else{
            return nil
        }
    }
}




class EmojiViewController: UIViewController,UIDropInteractionDelegate,UIScrollViewDelegate,UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout, UICollectionViewDragDelegate, UICollectionViewDropDelegate  {
    
    //MARK: - Model
    
    var emojiArt: EmojiArt?{
        get{
            if let url = emojiArtBackgoundImage.url{
                let emojis = emojiArtView.subviews.flatMap { $0 as? UILabel }.flatMap { EmojiArt.EmojiInfo(label: $0) }
                return EmojiArt(url: url, emojis: emojis)
            }
            return nil
        }
        set{
            emojiArtBackgoundImage = (nil, nil)
            emojiArtView.subviews.flatMap{$0 as? UILabel}.forEach{$0.removeFromSuperview() }
            if let url = newValue?.url{
                imageFetcher = ImageFetcher(fetch:url){ (url, image) in
                    DispatchQueue.main.async {
                        self.emojiArtBackgoundImage = (url, image)
                        newValue?.emojis.forEach {
                            let attributedText = $0.text.attributedString(withTextStyle: .body, ofSize: CGFloat($0.size))
                            self.emojiArtView.addLabel(with:attributedText, centeredAt: CGPoint(x: $0.x, y: $0.y))
                        }
                        
                    }
                }
            }
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let url = try? FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
            ).appendingPathComponent("Untitled.json"){
            if let jsonData = try? Data(contentsOf:url){
                emojiArt = EmojiArt(json:jsonData)
            }
            
            
        }
    }
    
    
    @IBAction func save(_ sender: UIBarButtonItem) {
        if let json = emojiArt?.json {
            if let url = try? FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            ).appendingPathComponent("Untitled.json"){
                do {
                    try  json.write(to: url)
                    print("save successfully")
                }catch let error{
                    print("Couldn't save \(error)")
                }
            }
        }
    }
    //
    
    private var addingEmoji = false
    
    
    @IBAction func addEmoji(_ sender: UIButton) {
        addingEmoji = true
        emojiCollectionView.reloadSections(IndexSet(integer:0))
    }
    
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // return emojis.count
        switch section {
        case 0: return 1
        case 1: return emojis.count
        default: return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        //        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCell", for: indexPath)
        //        if let emojiCell = cell as? EmojiCollectionViewCell{
        //            let text = NSAttributedString(string: emojis[indexPath.item], attributes: [.font:font])
        //            emojiCell.label.attributedText = text
        //        }
        //        return cell
        
        if indexPath.section == 1{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCell", for: indexPath)
            if let emojiCell = cell as? EmojiCollectionViewCell {
                let text = NSAttributedString(string:emojis[indexPath.item], attributes:[.font:font])
                emojiCell.label.attributedText = text
            }
            return cell
        }else if addingEmoji{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiInputCell", for: indexPath)
            if let inputCell = cell as? TextFieldCollectionViewCell {
                inputCell.reginationHandler = { [weak self, unowned inputCell] in
                    if let text = inputCell.textField.text{
                        self?.emojis = ( text.map{String($0)} + self!.emojis).uniquified
                    }
                    self?.addingEmoji = false
                    self?.emojiCollectionView.reloadData() 
                }
            }
            return cell
        }else{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddEmojiButtonCell", for: indexPath)
            return cell
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if addingEmoji && indexPath.section == 0{
            return CGSize(width:300, height:80)
        }else{
            return CGSize(width:80, height:80)
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let inputCell = cell as? TextFieldCollectionViewCell{
            inputCell.textField.becomeFirstResponder()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item:0, section:0)
        for item in coordinator.items{
            if let sourceIndexPath = item.sourceIndexPath{
                if let attributedString = item.dragItem.localObject as? NSAttributedString{
                    collectionView.performBatchUpdates({
                        emojis.remove(at: sourceIndexPath.item)
                        emojis.insert(attributedString.string, at:destinationIndexPath.item)
                        collectionView.deleteItems(at: [sourceIndexPath])
                        collectionView.insertItems(at: [destinationIndexPath])
                    }, completion: nil)
                    coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
                }
            }else{
                let placeholderContext = coordinator.drop(
                    item.dragItem,
                    to: UICollectionViewDropPlaceholder(insertionIndexPath: destinationIndexPath, reuseIdentifier: "DropPlaceholderCell")
                )
                item.dragItem.itemProvider.loadObject(ofClass: NSAttributedString.self){
                    (provider, error) in
                    DispatchQueue.main.async {
                        if let attributedString = provider as? NSAttributedString{
                            placeholderContext.commitInsertion(dataSourceUpdates: {insertionIndexPath in 
                                self.emojis.insert(attributedString.string, at: insertionIndexPath.item)
                            })
                        }else{
                            placeholderContext.deletePlaceholder()
                        }
                        
                    }
                    
                    
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSAttributedString.self)
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        session.localContext = collectionView
        return drapItem(at:indexPath)
    }
    
    
    
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if let indexPath = destinationIndexPath, indexPath.section == 1{
            let isSelf = (session.localDragSession?.localContext as? UICollectionView)  == collectionView
            return UICollectionViewDropProposal(operation: isSelf ? .move : .copy, intent: .insertAtDestinationIndexPath)
        }else{
            return UICollectionViewDropProposal(operation: .cancel)
        }
        
    }
    
    
    
    
    private func drapItem(at indexPath:IndexPath) -> [UIDragItem]{
        //        if let attributeString = ((emojiCollectionView.cellForItem(at: indexPath)) as? EmojiCollectionViewCell)?.label.attributedText
        //        {
        //            let dragItem = UIDragItem(itemProvider: NSItemProvider(object:attributeString))
        //            dragItem.localObject = attributeString
        //            return [dragItem]
        //        }else{
        //            return []
        //        }
        if !addingEmoji, let attributeString = (emojiCollectionView.cellForItem(at: indexPath) as?
            EmojiCollectionViewCell)?.label.attributedText{
            let dragItem = UIDragItem(itemProvider:NSItemProvider(object:attributeString))
            dragItem.localObject = attributeString
            return [dragItem]
        }else{
            return []
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        return drapItem(at:indexPath)
    }
    
    
    @IBOutlet weak var dropZone: UIView!{
        didSet{
            dropZone.addInteraction(UIDropInteraction(delegate: self))
        }
        
    }
    
    var emojiArtView =  EmojiArtView()
    
    @IBOutlet weak var scrollView: UIScrollView!{
        didSet{
            scrollView.minimumZoomScale = 0.1
            scrollView.maximumZoomScale = 5.0
            scrollView.delegate = self
            scrollView.addSubview(emojiArtView)
        }
    }
    
    @IBOutlet weak var scrollViewWidth: NSLayoutConstraint!
    
    @IBOutlet weak var scrollViewHeight: NSLayoutConstraint!
    
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        scrollViewHeight.constant = scrollView.contentSize.height
        scrollViewWidth.constant = scrollView.contentSize.width
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return emojiArtView
    }
    
    
    private var _emojiArtBackgroundImageURL:URL?
    
    var emojiArtBackgoundImage:(url:URL?, image:UIImage?){
        get{
            return  (_emojiArtBackgroundImageURL, emojiArtView.backgourdImage)
        }
        set{
            _emojiArtBackgroundImageURL = newValue.url
            scrollView?.zoomScale = 1.0
            emojiArtView.backgourdImage = newValue.image
            let size = newValue.image?.size ?? CGSize.zero
            emojiArtView.frame = CGRect(origin:CGPoint.zero, size:size)
            scrollView?.contentSize = size
            scrollViewHeight?.constant = size.height
            scrollViewWidth?.constant = size.width
            if let dropZone = self.dropZone, size.width > 0, size.height > 0{
                scrollView?.zoomScale = max(dropZone.bounds.size.width / size.width, dropZone.bounds.size.height / size.height)
                
            }
            
            
            
        }
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSURL.self) && session.canLoadObjects(ofClass: UIImage.self)
    }
    
    
    
    @IBOutlet weak var emojiCollectionView: UICollectionView!{
        didSet{
            emojiCollectionView.dataSource = self
            emojiCollectionView.delegate = self
            emojiCollectionView.dragDelegate = self
            emojiCollectionView.dropDelegate = self
        }
    }
    
    var emojis =  "😀😎👀🐬🐱🌹🌸🌈🛴✈️🌂⚽️🚗❤️🍉🍈🍎".map { String($0)}
    
    
    
    
    
    
    private var font:UIFont{
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(64.0))
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation:.copy)
    }
    
    var imageFetcher:ImageFetcher!
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        
        imageFetcher = ImageFetcher(){(url, image) in
            DispatchQueue.main.async {
                self.emojiArtBackgoundImage  = (url,image)
            }
            
        }
        
        session.loadObjects(ofClass: NSURL.self){ nsurls in
            
            if let url = nsurls.first as? URL{
                self.imageFetcher.fetch(url)
            }}
        session.loadObjects(ofClass: UIImage.self){ images in
            if let image = images.first as? UIImage{
                self.imageFetcher.backup = image
                
            }
        }
        
    }
    
    
    
    
    
    
    
}

