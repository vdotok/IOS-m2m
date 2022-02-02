//  
//  CallingViewController.swift
//  Many-to-many-call
//
//  Created by usama farooq on 15/06/2021.
//  Copyright © 2021 VDOTOK. All rights reserved.
//

import UIKit
import iOSSDKStreaming

public class CallingViewController: UIViewController {

    var viewModel: CallingViewModel!
    var groupCallingView: GroupCallingView?
    var incomingCallingView: IncomingCall?
    var counter = 0
    var timer = Timer()
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        configureAppearance()
        bindViewModel()
        viewModel.viewModelDidLoad()
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.viewModelWillAppear()
    }
    
    fileprivate func bindViewModel() {

        viewModel.output = { [weak self] output in
            guard let self = self else {return}
            //handle all your bindings here
            switch output {
            case .configureLocal(let view, session: let session):
                self.configureLocalView(rendrer: view, session: session)
            case .configureRemote(let streams):
                self.configureRemote(streams: streams)
            case .loadView(let mediaType):
                self.loadGroupCallingView(mediaType: mediaType)
            case .loadIncomingCallView(let session, let user):
                self.loadIncomingCallView(session: session, contact: user)
            case .dismissCallView:
                self.dismiss(animated: true, completion: nil)
            case .updateVideoView(let session):
                self.updateVideoView(session: session)
            case .updateView(let session):
                self.configureView(for: session)
            case .updateHangupButton(let status):
                self.handleHangup(status: status)
            default:
                break
            }
        }
    }
    
    private func updateVideoView(session: VTokBaseSession) {
        guard let groupCallingView = groupCallingView else {return}
        groupCallingView.updateAudioVideoview(for: session)
    }
    
    private func configureLocalView(rendrer: UIView, session: VTokBaseSession) {
        guard let groupCallingView = groupCallingView else {return}
        groupCallingView.configureLocal(view: rendrer)
        groupCallingView.session = session
    }
    private func configureView(for session: VTokBaseSession) {
        guard let groupCallingView = groupCallingView else {return}
        groupCallingView.updateView(for: session)
        
    }
    
    private func handleHangup(status: Bool) {
        guard let groupCallingView = groupCallingView else {return}
        groupCallingView.handleHanup(status: status)
    }
    
    private func configureRemote(streams: [UserStream]) {
        guard let groupCallingView = groupCallingView else {return}
        groupCallingView.updateDataSource(with: streams)
    }
}

extension CallingViewController {
    
    private func loadGroupCallingView(mediaType: SessionMediaType) {
        let view = GroupCallingView.getView()
        self.groupCallingView = view
        guard let groupCallingView = self.groupCallingView else {return}
        groupCallingView.loadViewFor(mediaType: mediaType)
        groupCallingView.users = viewModel.users
        groupCallingView.delegate = self
        groupCallingView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(groupCallingView)
        
        NSLayoutConstraint.activate([
            groupCallingView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            groupCallingView.trailingAnchor.constraint(equalTo:self.view.trailingAnchor),
            groupCallingView.topAnchor.constraint(equalTo: self.view.topAnchor),
            groupCallingView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
    }
    
    private func loadIncomingCallView(session: VTokBaseSession, contact: User) {
        let view = IncomingCall.loadView()
        self.incomingCallingView = view
        
        guard let incomingCallingView = self.incomingCallingView else {return}
        view.configureView(baseSession: session, user: contact)
        view.session = session
        incomingCallingView.delegate = self
        incomingCallingView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(incomingCallingView)
        
        NSLayoutConstraint.activate([
            incomingCallingView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            incomingCallingView.trailingAnchor.constraint(equalTo:self.view.trailingAnchor),
            incomingCallingView.topAnchor.constraint(equalTo: self.view.topAnchor),
            incomingCallingView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
    }
    
    
    func configureAppearance() {

    }
}

extension CallingViewController: IncomingCallDelegate {
    func didReject(session: VTokBaseSession) {
        viewModel.rejectCall(session: session)
    }
    
    func didAccept(session: VTokBaseSession) {
        viewModel.acceptCall(session: session)
    }
    
    
}

extension CallingViewController: VideoDelegate {
    func didTapVideo(for baseSession: VTokBaseSession, state: VideoState) {
        viewModel.disableVideo(session: baseSession, state: state)
    }
    
    func didTapMute(for baseSession: VTokBaseSession, state: AudioState) {
        viewModel.mute(session: baseSession, state: state)
    }
    
    func didTapEnd(for baseSession: VTokBaseSession) {
        viewModel.hangupCall(session: baseSession)
    }
    
    func didTapFlip(for baseSession: VTokBaseSession, type: CameraType) {
        viewModel.flipCamera(session: baseSession, state: type)
        
    }
    
    func didTapSpeaker(baseSession: VTokBaseSession, state: SpeakerState) {
        viewModel.speaker(session: baseSession, state: state)
        
    }
    
    
}


