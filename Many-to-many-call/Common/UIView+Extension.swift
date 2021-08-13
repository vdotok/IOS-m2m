//
//  UIView+Extension.swift
//  Many-to-many-call
//
//  Created by Sohaib Hussain on 13/08/2021.
//

import Foundation
import UIKit

extension UIView{
    func fixInSuperView(){
        guard let _superView = self.superview else {
            return
        }
        
        NSLayoutConstraint.activate([
           self.leadingAnchor.constraint(equalTo: _superView.leadingAnchor),
            self.trailingAnchor.constraint(equalTo:_superView.trailingAnchor),
            self.topAnchor.constraint(equalTo: _superView.topAnchor),
            self.bottomAnchor.constraint(equalTo: _superView.bottomAnchor)
        ])
        
    }
    
    func fixInMiddleOfSuperView(){
        
        guard let _superView = self.superview else {
            return
        }
        
        NSLayoutConstraint.activate([
            self.centerXAnchor.constraint(equalTo: _superView.centerXAnchor),
            self.centerYAnchor.constraint(equalTo: _superView.centerYAnchor)
        ])
    }
    
}
