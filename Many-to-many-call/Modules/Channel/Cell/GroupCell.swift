//
//  GroupCell.swift
//  Many-to-many-call
//
//  Created by usama farooq on 14/06/2021.
//

import UIKit

protocol GroupCallDelegate: class {
    func didTapAudio(participants: [Participant])
    func didTapVideo(participants: [Participant])
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
        delegate?.didTapAudio(participants: group.participants)
    }
    
    @IBAction func didTapVideo(_ sender: UIButton) {
        guard let group = group else {return}
        delegate?.didTapVideo(participants: group.participants)
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


