//  
//  ChannelBuilder.swift
//  Many-to-many-call
//
//  Created by usama farooq on 13/06/2021.
//  Copyright © 2021 VDOTOK. All rights reserved.
//

import Foundation
import UIKit

class ChannelBuilder {

    func build(with navigationController: UINavigationController?) -> UIViewController {
        
        let storyboard = UIStoryboard(name: "Channel", bundle: Bundle(for: ChannelBuilder.self))
        let viewController = storyboard.instantiateViewController(withIdentifier: "ChannelViewController") as! ChannelViewController
        let coordinator = ChannelRouter(navigationController: navigationController)
        let viewModel = ChannelViewModelImpl(router: coordinator)

        viewController.viewModel = viewModel
        
        return viewController
    }
}


