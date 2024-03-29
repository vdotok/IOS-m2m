//  
//  ChannelViewModel.swift
//  Many-to-many-call
//
//  Created by usama farooq on 13/06/2021.
//  Copyright © 2021 VDOTOK. All rights reserved.
//

import Foundation
import iOSSDKStreaming

typealias ChannelViewModelOutput = (ChannelViewModelImpl.Output) -> Void

struct TempGroup {
    let group: Group
    let unReadMessageCount: Int
    let lastMessage: String
    let presentParticipant: Int
}

protocol ChannelViewModelInput {
    var output: ChannelViewModelOutput? { get set}
    var groups: [Group] {get set}
    var searchGroup: [Group] {get set}
    var isSearching: Bool {get set}
  
   
    var presentCandidates: [String: [String]] {get set}

    func viewModelDidLoad()
    func viewModelWillAppear()
    func fetchGroups()
    func subscribe(group: Group)
    func itemAt(row: Int) -> TempGroup
    func moveToVideo(group: Group)
    func moveToAudio(group: Group)
    func deleteGroup(with id: Int)
    func editGroup(with title: String, id: Int)
    func logout()
}

protocol ChannelViewModel: ChannelViewModelInput {
    var output: ChannelViewModelOutput? { get set}
    
    func viewModelDidLoad()
    func viewModelWillAppear()
}

class ChannelViewModelImpl: ChannelViewModel, ChannelViewModelInput {
    
    var groups: [Group] = []
    var searchGroup: [Group] = []
    var isSearching: Bool = false
    var store: AllGroupStroreable
    var vtokSdk: VideoTalkSDK?
    var presentCandidates: [String : [String]] = [:]
    var contacts: [User] = []
    var deleteStore: DeleteStoreable = DeleteService(service: NetworkService())
    var editStore: EditGroupStoreable = EditGroupService(service: NetworkService())
    
    private let allUserStoreAble: AllUserStoreAble = AllUsersService(service: NetworkService())
    
    private let router: ChannelRouter
    var output: ChannelViewModelOutput?
    
    init(router: ChannelRouter, store:AllGroupStroreable = AllGroupService(service: NetworkService()) ) {
        self.router = router
        self.store = store
    }
    
    func viewModelDidLoad() {
        if (!AuthenticationConstants.TENANTSERVER.isEmpty && !AuthenticationConstants.PROJECTID.isEmpty) {
             UserDefaults.baseUrl = AuthenticationConstants.TENANTSERVER
             UserDefaults.projectId = AuthenticationConstants.PROJECTID
          } else {
            AuthenticationConstants.TENANTSERVER =  UserDefaults.baseUrl
            AuthenticationConstants.PROJECTID = UserDefaults.projectId
        }
        configureVdotTok()
        fetchGroups()
    }
    
    func viewModelWillAppear() {
        fetchGroups()
    }
    
    private func configureVdotTok() {
        guard let user = VDOTOKObject<UserResponse>().getData(),
              let url = user.mediaServerMap?.completeAddress
        else {return}
        let request = RegisterRequest(type: Constants.Request,
                                      requestType: Constants.Register,
                                      referenceId: user.refID!,
                                      authorizationToken: user.authorizationToken!,
                                      requestId: getRequestId(),
                                      projectId: AuthenticationConstants.PROJECTID)
        self.vtokSdk = VTokSDK(url: url, registerRequest: request, connectionDelegate: self)
        
    }
    
    private func getRequestId() -> String {
        let generatable = IdGenerator()
        guard let response = VDOTOKObject<UserResponse>().getData() else {return ""}
        let timestamp = NSDate().timeIntervalSince1970
        let myTimeInterval = TimeInterval(timestamp)
        let time = Date(timeIntervalSince1970: TimeInterval(myTimeInterval)).stringValue()
        let tenantId = "12345"
        let token = generatable.getUUID(string: time + tenantId + response.refID!)
        return token
        
    }
    
    //For all of your viewBindings
    enum Output {
        case reload
        case showProgress
        case hideProgress
        case connected
        case disconnected
        case failure(message: String)
    }
}

extension ChannelViewModelImpl {
    
    func moveToVideo(group: Group) {
        guard let sdk = vtokSdk else {return}
        router.moveToCalling(sdk: sdk, group: group, users: contacts)
    }
    
    func moveToAudio(group: Group) {
        guard let sdk = vtokSdk else {return}
        router.moveToAudio(sdk: sdk, group: group, users: contacts)
    }
    
    
    func fetchGroups() {
        let request = AllGroupRequest()
        self.output?(.showProgress)
        store.fetchGroups(with: request) { [weak self] (response) in
            guard let self = self else {return}
            output?(.hideProgress)
            switch response {
            case .success(let response):
                switch response.status {
                case 503:
                    self.output?(.failure(message: response.message ))
                case 500:
                    self.output?(.failure(message: response.message))
                case 401:
                    self.output?(.failure(message: response.message))
                case 200:
                    self.groups = response.groups ?? []
                    DispatchQueue.main.async {
                        self.output?(.reload)
                    }
                    self.fetchUsers()
                    
                default:
                    break
                }
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func fetchUsers() {
        let request = AllUserRequest()
        allUserStoreAble.fetchUsers(with: request) { [weak self] (response) in
            guard let self = self else {return}
            switch response {
            case .success(let response):
                self.contacts = response.users
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func subscribe(group: Group) {
        
    }
    
    func itemAt(row: Int) -> TempGroup {
        let channel = groups[row].channelName
        let present = presentCandidates[channel]
        let group = TempGroup(group: groups[row], unReadMessageCount: 0, lastMessage: "", presentParticipant: present?.count ?? 0)
        
        return group
    }
    
    func logout() {
        self.vtokSdk?.closeConnection()
        UserDefaults.standard.removeObject(forKey: "projectId")
        UserDefaults.standard.removeObject(forKey: "baseUrl")
    }
    
    func deleteGroup(with id: Int) {
        output?(.showProgress)
        let request = DeleteGroupRequest(group_id: groups[id].id)
        deleteStore.delete(with: request) { [weak self] response in
            self?.output?(.hideProgress)
            switch response {
            case .success(let response):
                DispatchQueue.main.async {
                    switch response.status {
                    case 503:
                        self?.output?(.failure(message: response.message ))
                    case 500:
                        self?.output?(.failure(message: response.message))
                    case 401:
                        self?.output?(.failure(message: response.message))
                    case 600:
                        self?.output?(.failure(message: response.message))
                    case 200:
                        
                    self?.groups.remove(at: id)
                    self?.output?(.reload)
                    default:
                    break
                    }
                }
                
                print("\(response)")
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func editGroup(with title: String, id: Int) {
        guard  groups[id].participants.count != 1 else {
            output?(.failure(message: "one to one group name cannot be updated"))
            return
        }
        output?(.showProgress)
        let request = EditGroupRequest(group_title: title, group_id: groups[id].id)
        editStore.editGroup(with: request) { [weak self] result in
            self?.output?(.hideProgress)
            switch result {
            case .success(_):
                self?.groups[id].groupTitle = title
                DispatchQueue.main.async {
                    self?.output?(.reload)
                }
               
            case .failure(let error):
                print(error)
                
            }
        }
    }
}

extension ChannelViewModelImpl: SDKConnectionDelegate {
    
    func initReInvite(){}
    
    func didGenerate(output: SDKOutPut) {
        switch output {
        case .disconnected(_):
            self.output?(.disconnected)
        case .registered:
            self.output?(.connected)
        case .sessionRequest(let sessionRequest):
            guard let sdk = vtokSdk else {return}
            router.moveToIncomingCall(sdk: sdk, baseSession: sessionRequest, users: self.contacts)
        }
    }
    
}
