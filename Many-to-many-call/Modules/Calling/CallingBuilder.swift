//  
//  CallingBuilder.swift
//  Many-to-many-call
//
//  Created by usama farooq on 15/06/2021.
//

import Foundation
import UIKit
import VdoTokSDK

enum ScreenType {
    case videoView
    case audioView
    case incomingCall
}

class CallingBuilder {

    func build(with navigationController: UINavigationController?, vtokSdk: VTokSDK, participants: [Participant]?, screenType: ScreenType, session: VTokBaseSession? = nil, contact: [User]? = nil) -> UIViewController {
        
        let storyboard = UIStoryboard(name: "Calling", bundle: Bundle(for: CallingBuilder.self))
        let viewController = storyboard.instantiateViewController(withIdentifier: "CallingViewController") as! CallingViewController
        let coordinator = CallingRouter(navigationController: navigationController)
        let viewModel = CallingViewModelImpl(router: coordinator, vtokSdk: vtokSdk, participants: participants, screenType: screenType, session: session, users: contact)

        viewController.viewModel = viewModel
        
        return viewController
    }
}


