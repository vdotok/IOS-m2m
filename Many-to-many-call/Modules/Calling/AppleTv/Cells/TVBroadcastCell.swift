//
//  TVBroadcastCell.swift
//  Many-to-many-call
//
//  Created by usama farooq on 23/08/2021.
//

import UIKit
import iOSSDKStreaming

class TVBroadcastCell: UICollectionViewCell {

    @IBOutlet weak var remoteView: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func configureCell(with stream: UserStream) {
        for view in remoteView.subviews {
            view.removeFromSuperview()
        }
       
        let frame = AVMakeRect(aspectRatio: stream.renderer.frame.size, insideRect: self.remoteView.frame)
        stream.renderer.frame = frame
        remoteView.addSubview(stream.renderer)

        stream.renderer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stream.renderer.leadingAnchor.constraint(equalTo: self.remoteView.leadingAnchor),
            stream.renderer.trailingAnchor.constraint(equalTo:self.remoteView.trailingAnchor),
            stream.renderer.topAnchor.constraint(equalTo: self.remoteView.topAnchor),
            stream.renderer.bottomAnchor.constraint(equalTo: self.remoteView.bottomAnchor)
//            stream.renderer.heightAnchor.constraint(equalToConstant: stream.renderer.frame.height),
//            stream.renderer.widthAnchor.constraint(equalToConstant: stream.renderer.frame.width)
        ])
        stream.renderer.fixInMiddleOfSuperView()
    }

}
