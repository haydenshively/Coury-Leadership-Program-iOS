//
//  ImageViewCell.swift
//  Coury Leadership Program
//
//  Created by Hayden Shively on 2/8/19.
//  Copyright © 2019 USC Marshall School of Business. All rights reserved.
//

import UIKit

class ImageCell: AUITableViewCell, FeedViewCell {

    public static let HEIGHT: CGFloat = 386
    public static let REUSE_ID: String = "ImageCell"

    @IBOutlet weak var insetView: UIView!
    @IBOutlet weak var squareImage: UIImageView!
    @IBOutlet weak var favoriteHeart: UIButton!
    @IBOutlet weak var saveImageButton: UIButton!
    
    override internal var data: TableableCellData? {
        didSet {
            (data as? Posts.Image)?.downloadImage {image in
                self.squareImage.image = image
            }
        }
    }
    
    var isSaved: Bool = false {
        didSet {favoriteHeart.isSelected = isSaved}
    }
    func setSaved(to: Bool) {
        isSaved = to
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        contentView.layer.masksToBounds = false
        insetView.layer.cornerRadius = 8
        insetView.layer.masksToBounds = false

        squareImage.layer.cornerRadius = 8
        squareImage.layer.masksToBounds = true
        
        if #available(iOS 13.0, *) {
            saveImageButton.layer.borderColor = UIColor.label.cgColor
        } else {
            // Fallback on earlier versions
            saveImageButton.layer.borderColor = UIColor.black.cgColor
            
            favoriteHeart.setImage(#imageLiteral(resourceName: "Heart"), for: .normal)
            favoriteHeart.setImage(#imageLiteral(resourceName: "HeartFilled"), for: [.highlighted, .selected])
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        configureShadow()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        squareImage.image = nil
    }
    
    @IBAction func onHeartTap(_ sender: UIButton) {
        CLPProfile.shared.toggleLike(data as! Posts.Post, sync: true)
        isSaved = !isSaved
    }
    
    @IBAction func onSaveImageTap(_ sender: UIButton) {
        let alert = UIAlertController(title: "Do you want to save this wallpaper to your Camera Roll?", message: "You can also long press on the image to bookmark it within the app.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default) {_ in
            guard let imageToSave = self.squareImage.image else {return}
            UIImageWriteToSavedPhotosAlbum(imageToSave, nil, nil, nil)
        })
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        
        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true)
    }
    
    func onTap(inContext vc: UIViewController, _ sender: UITapGestureRecognizer) {}
    func onLongPress(began: Bool) {}
}
