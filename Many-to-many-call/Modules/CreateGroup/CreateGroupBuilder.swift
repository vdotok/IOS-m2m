//  
//  CreateGroupBuilder.swift
//  Many-to-many-call
//
//  Created by usama farooq on 14/06/2021.
//

import Foundation
import UIKit

class CreateGroupBuilder {

    func build(with navigationController: UINavigationController?, delegate: CreateGroupDelegate) -> UIViewController {
        
        let storyboard = UIStoryboard(name: "CreateGroup", bundle: Bundle(for: CreateGroupBuilder.self))
        let viewController = storyboard.instantiateViewController(withIdentifier: "CreateGroupViewController") as! CreateGroupViewController
        let coordinator = CreateGroupRouter(navigationController: navigationController)
        let viewModel = CreateGroupViewModelImpl(router: coordinator, delegate: delegate)

        viewController.viewModel = viewModel
        
        return viewController
    }
}


