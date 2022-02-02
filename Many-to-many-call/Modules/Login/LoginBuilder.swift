//  
//  LoginBuilder.swift
//  Many-to-many-call
//
//  Created by usama farooq on 13/06/2021.
//  Copyright © 2021 VDOTOK. All rights reserved.
//

import Foundation
import UIKit

class LoginBuilder {

    func build(with navigationController: UINavigationController?) -> UIViewController {
        
        let storyboard = UIStoryboard(name: "Login", bundle: Bundle(for: LoginBuilder.self))
        let viewController = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
        let coordinator = LoginRouter(navigationController: navigationController)
        let viewModel = LoginViewModelImpl(router: coordinator)

        viewController.viewModel = viewModel
        
        return viewController
    }
}


