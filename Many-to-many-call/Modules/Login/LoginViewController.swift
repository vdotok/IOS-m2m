//  
//  LoginViewController.swift
//  Many-to-many-call
//
//  Created by usama farooq on 13/06/2021.
//

import UIKit

public class LoginViewController: UIViewController {
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var singupButton: UIButton!
    
    var viewModel: LoginViewModel!
    let navigationController2 = UINavigationController()
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        configureAppearance()
        bindViewModel()
        viewModel.viewModelDidLoad()
    }
    
    @IBAction func didTapLogin(_ sender: UIButton) {
        guard let userName = email.text, let password = password.text else {return }
        viewModel.loginUser(with: userName, password)
    }
    
    @IBAction func didTapRegister(_ sender: UIButton) {
        let builder = SignUpBuilder().build(with: UINavigationController())
        builder.modalPresentationStyle = .fullScreen
        builder.modalTransitionStyle = .crossDissolve
        self.present(builder, animated: true, completion: nil)
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.viewModelWillAppear()
    }
    
    fileprivate func bindViewModel() {
        
        viewModel.output = { [unowned self] output in
            //handle all your bindings here
            switch output {
            case .showProgress:
                ProgressHud.show(viewController: self)
            case .hideProgress:
                ProgressHud.hide()
            case .failure(let message):
                DispatchQueue.main.async {
                    ProgressHud.showError(message: message, viewController: self)
                }
               
            case .success:
                DispatchQueue.main.async {
                    let navigationControlr = UINavigationController()
                    navigationControlr.modalPresentationStyle = .fullScreen
                    let viewController = ChannelBuilder().build(with: navigationControlr)
                    viewController.modalPresentationStyle = .fullScreen
                    navigationControlr.setViewControllers([viewController], animated: true)
                    present(navigationControlr, animated: true, completion: nil)
                }
            default:
                break
            }
        }
    }
}

extension LoginViewController {
    func configureAppearance() {
        containerView.layer.cornerRadius = 20
//        self.navigationController?.navigationBar.isHidden = true
        singupButton.setTitleColor(UIColor(named: "AppIndigoColor"), for: .normal)
    }
}
