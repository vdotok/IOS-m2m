//  
//  ChannelViewController.swift
//  Many-to-many-call
//
//  Created by usama farooq on 13/06/2021.
//  Copyright © 2021 VDOTOK. All rights reserved.
//

import UIKit

public class ChannelViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitle: UILabel!
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var emptyLogoutButton: UIButton!
    @IBOutlet weak var blurView: UIView!
    @IBOutlet weak var onlineView: UIView! {
        didSet {
            onlineView.layer.cornerRadius = onlineView.frame.height/2
        }
    }
    @IBOutlet weak var emptyViewOnlineView: UIView! {
        didSet  {
            emptyViewOnlineView.layer.cornerRadius = emptyViewOnlineView.frame.height/2
        }
    }
    lazy var refreshControl = UIRefreshControl()
    
    var viewModel: ChannelViewModel!
    private var selectedGroupId: Int? = nil
    let navigationTitle = UILabel()
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        configureAppearance()
        bindViewModel()
        viewModel.viewModelDidLoad()
//        NotificationCenter.default.addObserver(self, selector: #selector(didSubscribe(notification:)), name: .didGroupCreated, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(removeCount(notification:)), name: .removeCount, object: nil)

    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.viewModelWillAppear()
    }
    
    @IBAction func didTapReferesh(_ sender: UIButton) {
        viewModel.fetchGroups()
    }
    
    @IBAction func didTapNewChat(_ sender: UIButton) {
        didTappedAdd()
    }
    
    @IBAction func didTapLogout(_ sender: UIButton) {
        UserDefaults.standard.removeObject(forKey: "UserResponse")
        viewModel.logout()
        let viewController = LoginBuilder().build(with: self.navigationController)
        viewController.modalPresentationStyle = .fullScreen
        self.navigationController?.present(viewController, animated: true, completion: nil)
    }
    
    fileprivate func bindViewModel() {

        viewModel.output = { [unowned self] output in
            //handle all your bindings here
            switch output {
            case .showProgress:
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    ProgressHud.show(viewController: self)
                }
            case .hideProgress:
                ProgressHud.hide()
            case .reload:
                self.refreshControl.endRefreshing()
                tableView(isHidden: viewModel.groups.count > 0 ? false : true)
                tableView.reloadData()
            case .connected:
                onlineView.backgroundColor = .green
                emptyViewOnlineView.backgroundColor = .green
            case .disconnected:
                onlineView.backgroundColor = .red
                emptyViewOnlineView.backgroundColor = .red
            case .failure(let message):
                ProgressHud.showError(message: message, viewController: self)
            }
        }
    }
    @objc private func didSubscribe(notification: NSNotification) {
        let userInfo = notification.userInfo as! [String: AnyObject]
        guard let model = userInfo["model"] as? Group else {
            return
        }
        viewModel.groups.insert(model, at: 0)
        viewModel.subscribe(group: model)
        
    }
    
    @objc private func removeCount(notification: NSNotification) {
        let userInfo = notification.userInfo as! [String: AnyObject]
        guard let channelName = userInfo["channelName"] as? String else { return }

    }
}

extension ChannelViewController {
    func configureAppearance() {
        guard let user = VDOTOKObject<UserResponse>().getData() else {return}
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "GroupCell", bundle: nil), forCellReuseIdentifier: "GroupCell")
        tableView(isHidden: viewModel.groups.count > 0 ? false : true)
        configureEmptyView()
        navigationTitle.text = "Chat Rooms"
        navigationTitle.font = UIFont(name: "Manrope-Medium", size: 20)
        navigationTitle.textColor = .appDarkGreenColor
        navigationTitle.sizeToFit()
        let leftItem = UIBarButtonItem(customView: navigationTitle)
        self.navigationItem.leftBarButtonItem = leftItem
        let image = UIImage(named: "plus")?.withRenderingMode(.alwaysOriginal)
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: image,
            style: .plain,
            target: self,
            action: #selector(didTappedAdd)
        )
        
        refreshControl.attributedTitle = NSAttributedString(string: "")
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        tableView.addSubview(refreshControl)
        
        let title = "Logout \(user.fullName!)"
        logoutButton.setTitle(title, for: .normal)
        emptyLogoutButton.setTitle(title, for: .normal)
    }
    
    @objc func refresh() {
        viewModel.fetchGroups()
    }
    
    @objc func didTappedAdd() {
       
        let vc = CreateGroupBuilder()
            .build(with: self.navigationController, delegate: self)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func configureEmptyView() {
        
        titleLabel.textColor = .appDarkGreenColor
        titleLabel.font = UIFont(name: "Inter-Regular", size: 21)
        subTitle.textColor = .appLightIndigoColor
        subTitle.font = UIFont(name: "Poppins-Regular", size: 14)
        logoutButton.tintColor = .appIndigoColor
        logoutButton.titleLabel?.font = UIFont.init(name: "Manrope-Bold", size: 14)
       
    }
    private func tableView(isHidden: Bool) {
        if isHidden {
            tableView.isHidden = isHidden
            emptyView.isHidden = !isHidden
        } else {
            tableView.isHidden = isHidden
            emptyView.isHidden = !isHidden
        }
        
    }
}

extension ChannelViewController: UITableViewDataSource, UITableViewDelegate {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if viewModel.isSearching {
            return viewModel.searchGroup.count
        }
        return viewModel.groups.count

    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupCell", for: indexPath) as! GroupCell
        cell.selectionStyle = .none
        let item = viewModel.itemAt(row: indexPath.row)
        cell.configure(with: item.group, delegate: self)

        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

    }
    
    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let edit = UIContextualAction(style: .normal,
                                         title: "Edit") { [weak self] (action, view, completionHandler) in
            self?.selectedGroupId = indexPath.row
            self?.loadGroupView()
                                            completionHandler(true)
        }
        let trash = UIContextualAction(style: .destructive,
                                       title: "Delete") { [weak self] (action, view, completionHandler) in
            self?.viewModel.deleteGroup(with: indexPath.row)
                                        completionHandler(true)
        }
        if viewModel.groups[indexPath.row].participants.count <= 2 {
            let configuration = UISwipeActionsConfiguration(actions: [trash])
            return configuration
        }
        let configuration = UISwipeActionsConfiguration(actions: [edit, trash])
        return configuration
    }

}

extension ChannelViewController: UISearchBarDelegate {

    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.isSearching = true
    }
    
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.view.endEditing(true)
    }
}

extension ChannelViewController: GroupCallDelegate {
    func didTapAudio(group: Group) {
        viewModel.moveToAudio(group: group)
    }
    
    func didTapVideo(group: Group) {
        viewModel.moveToVideo(group: group)
    }
  
}

extension ChannelViewController: CreateGroupDelegate {
    func didGroupCreated(group: Group) {
        viewModel.groups.insert(group, at: 0)
        tableView.reloadData()
    }
    
    
    
}

extension ChannelViewController {
    func loadGroupView() {
        let vc = CreateGroupPopup()
        vc.modalPresentationStyle = .custom
        vc.modalTransitionStyle = .crossDissolve
        present(vc, animated: true, completion: nil)
        vc.delegate = self
        blurView.isHidden = false
    }
}

extension ChannelViewController: PopupDelegate {
    func didTapDismiss(groupName: String?) {
        guard let id = selectedGroupId, let name = groupName else {return}
        blurView.isHidden = true
        viewModel.editGroup(with: name, id: id)
    }
    
    
}
