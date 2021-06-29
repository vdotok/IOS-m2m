//  
//  CallingViewModel.swift
//  Many-to-many-call
//
//  Created by usama farooq on 15/06/2021.
//

import Foundation
import iOSSDKStreaming
import UIKit
import AVFoundation

typealias CallingViewModelOutput = (CallingViewModelImpl.Output) -> Void

protocol CallingViewModelInput {
    
}

protocol CallingViewModel: CallingViewModelInput {
    var output: CallingViewModelOutput? { get set}
    var users: [User]? {get set}
    
    func viewModelDidLoad()
    func viewModelWillAppear()
    func acceptCall(session: VTokBaseSession)
    func rejectCall(session: VTokBaseSession)
    func hangupCall(session: VTokBaseSession)
    func flipCamera(session: VTokBaseSession, state: CameraType)
    func mute(session: VTokBaseSession, state: AudioState)
    func speaker(session: VTokBaseSession, state: SpeakerState)
    func disableVideo(session: VTokBaseSession, state: VideoState)
}

class CallingViewModelImpl: CallingViewModel, CallingViewModelInput {

    private let router: CallingRouter
    var output: CallingViewModelOutput?
    var vtokSdk: VTokSDK?
    var participants: [Participant]?
    var screenType: ScreenType
    var session: VTokBaseSession?
    var users: [User]?
    var player: AVAudioPlayer?
    
    init(router: CallingRouter, vtokSdk: VTokSDK, participants: [Participant]? = nil, screenType: ScreenType, session: VTokBaseSession? = nil, users: [User]? = nil) {
        self.router = router
        self.vtokSdk = vtokSdk
        self.participants = participants
        self.screenType = screenType
        self.session = session
        self.users = users
    }
    
    func viewModelDidLoad() {
        if let baseSession = session, baseSession.state == .receivedSessionInitiation {
            vtokSdk?.set(sessionDelegate: self, for: baseSession)
        }
        
        loadViews()
        
    }
    
    func viewModelWillAppear() {
        
    }
    
    private func loadViews() {
        switch screenType {
        case .audioView:
        audioCallToParticipants()
        case .videoView:
            callToParticipants()
        case .incomingCall:
            guard let session = session else {return}
            guard let selectedUser =  users?.filter({$0.refID == session.to.first}).first else {return}
            playSound()
            output?(.loadIncomingCallView(session: session, user: selectedUser))
        }
    }
    
    //For all of your viewBindings
    enum Output {
        case loadView(mediaType: SessionMediaType)
        case loadIncomingCallView(session: VTokBaseSession, user: User)
        case configureLocal(view: UIView, session: VTokBaseSession)
        case configureRemote(streams: [UserStream])
        case updateVideoView(session: VTokBaseSession)
        case loadAudioView
        case dismissCallView
        case updateView(session: VTokBaseSession)
    }
    
    private func callToParticipants() {
        guard let user = VDOTOKObject<UserResponse>().getData() else { return }
        guard let participents = participants else {return}
        let participantsRefIds = participents.map({$0.refID}).filter({$0 != user.refID })
        output?(.loadView(mediaType: .videoCall))
        vtokSdk?.makeGroupCall(to: participantsRefIds, sessionDelegate: self, mediaType: .videoCall)
        
    }
    
    private func audioCallToParticipants() {
        guard let user = VDOTOKObject<UserResponse>().getData() else { return }
        guard let participents = participants else {return}
        let participantsRefIds = participents.map({$0.refID}).filter({$0 != user.refID })
        output?(.loadView(mediaType: .audioCall))
        vtokSdk?.makeGroupCall(to: participantsRefIds, sessionDelegate: self, mediaType: .audioCall)
        
        
    }
}

extension CallingViewModelImpl {
    func acceptCall(session: VTokBaseSession) {
        stopSound()
        switch session.sessionMediaType {
        case .audioCall:
            output?(.loadView(mediaType: .audioCall))
            output?(.updateVideoView(session: session))
        case .videoCall:
            output?(.loadView(mediaType: .videoCall))
            output?(.updateVideoView(session: session))
        default:
            break
        }
        vtokSdk?.accept(session: session)
    }
    
    func rejectCall(session: VTokBaseSession) {
        vtokSdk?.reject(session: session)
        output?(.dismissCallView)
        stopSound()
    }
    
    func hangupCall(session: VTokBaseSession) {
        stopSound()
        vtokSdk?.hangup(session: session)
    }
    
    func mute(session: VTokBaseSession, state: AudioState) {
        vtokSdk?.mute(session: session, state: state)
    }
    
    func speaker(session: VTokBaseSession, state: SpeakerState) {
        vtokSdk?.speaker(session: session, state: state)
    }
    
    func flipCamera(session: VTokBaseSession, state: CameraType) {
        vtokSdk?.switchCamera(session: session, to: state)
    }
    
    func disableVideo(session: VTokBaseSession, state: VideoState) {
        vtokSdk?.disableVideo(session: session, State: state)
    }
    
}

extension CallingViewModelImpl: SessionDelegate {
    
    func sessionDidConnnect(session: VTokBaseSession) {
        stopSound()
        output?(.updateView(session: session))
    }
    
    func sessionDidFail(session: VTokBaseSession, error: Error) {
        
    }
    
    func sessionDidDisconnect(session: VTokBaseSession, error: Error?) {
        
    }
    
    func sessionWasRejected(session: VTokBaseSession, message: String) {
        DispatchQueue.main.async {[weak self] in
            self?.output?(.dismissCallView)
            self?.stopSound()
        }
    }
    
    func userBusyFor(session: VTokBaseSession, message: String) {
        
    }
    
    func sessionDidHangUp(session: VTokBaseSession, message: String) {
        DispatchQueue.main.async {[weak self] in
            
            self?.output?(.dismissCallView)
        }
    }
    
    func configureLocalViewFor(session: VTokBaseSession, renderer: UIView) {
        output?(.configureLocal(view: renderer, session: session))
    }
    
    func configureRemoteFor(session: VTokBaseSession, renderer: UIView) {
        
    }
    
    func configureRemoteViews(for streams: [UserStream]) {
        output?(.configureRemote(streams: streams))
    }
    
    func remoteParticipantDidRemove() {
        
    }
    
    func handle(stateInformation: StateInformation, for session: VTokBaseSession) {
        
    }
    
    func sessionTryingToConnect(session: VTokBaseSession) {
        output?(.updateView(session: session))
    }
    
    func sessionMissed(session: VTokBaseSession, message: String) {
        DispatchQueue.main.async {[weak self] in
            self?.output?(.dismissCallView)
            self?.stopSound()
        }
    }
    
    func sessionRinging(session: VTokBaseSession, message: String) {
        output?(.updateView(session: session))
    }
    
    func invalid(session: VTokBaseSession, message: String) {
        
    }
    
    func sessionDidUpdate(session: VTokBaseSession) {
        DispatchQueue.main.async { [weak self] in
            self?.output?(.updateView(session: session))
        }
        
    }

    
}

extension CallingViewModelImpl {
    func stopSound() {
        player?.stop()
    }
    
    func playSound() {
        guard let url = Bundle.main.url(forResource: "iphone_11_pro", withExtension: "mp3") else {
            print("url not found")
            return
        }

        do {
            /// this codes for making this app ready to takeover the device audio
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            try AVAudioSession.sharedInstance().setActive(true)

            /// change fileTypeHint according to the type of your audio file (you can omit this)

            /// for iOS 11 onward, use :
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)

            /// else :
            /// player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileTypeMPEGLayer3)

            // no need for prepareToPlay because prepareToPlay is happen automatically when calling play()
            player!.numberOfLoops = 3
            player!.play()
        } catch let error as NSError {
            print("error: \(error.localizedDescription)")
        }
    }
}
