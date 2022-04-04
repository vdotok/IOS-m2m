//
//  GroupCell.swift
//  Many-to-many-call
//
//  Created by usama farooq on 14/06/2021.
//  Copyright © 2021 VDOTOK. All rights reserved.
//

import UIKit

protocol GroupCallDelegate: AnyObject {
    func didTapAudio(group: Group)
    func didTapVideo(group: Group)
}

class GroupCell: UITableViewCell {
    
    @IBOutlet weak var groupTitle: UILabel!
    weak var delegate: GroupCallDelegate?
    var group: Group?

    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    @IBAction func didTapAudio(_ sender: UIButton) {
        guard let group = group else {return}
        delegate?.didTapAudio(group: group)
    }
    
    @IBAction func didTapVideo(_ sender: UIButton) {
        guard let group = group else {return}
        delegate?.didTapVideo(group: group)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configure(with group: Group, delegate: GroupCallDelegate) {
        self.group = group
        groupTitle.text = group.groupTitle
        self.delegate = delegate
    }
}


