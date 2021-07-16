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
    var vtokSdk: VideoTalkSDK?
    var participants: [Participant]?
    var screenType: ScreenType
    var session: VTokBaseSession?
    var users: [User]?
    var player: AVAudioPlayer?
    var counter = 0
    var timer = Timer()
    
    init(router: CallingRouter, vtokSdk: VideoTalkSDK, participants: [Participant]? = nil, screenType: ScreenType, session: VTokBaseSession? = nil, users: [User]? = nil) {
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
            makeSession(with: .audioCall)
        case .videoView:
            makeSession(with: .videoCall)
        case .incomingCall:
            guard let session = session else {return}
            guard let selectedUser =  users?.filter({$0.refID == session.to.first}).first else {return}
           
            playSound()
            output?(.loadIncomingCallView(session: session, user: selectedUser))
            self.session = session
            callHangupHandling()
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
        case updateHangupButton(status: Bool)
    }
    
    private func makeSession(with sessionMediaType: SessionMediaType) {
        guard let user = VDOTOKObject<UserResponse>().getData(),
              let refID = user.refID
        else {return}
        guard let participents = participants else {return}
        let participantsRefIds = participents.map({$0.refID}).filter({$0 != user.refID })
        let requestId = getRequestId()
        let baseSession = VTokBaseSessionInit(from: refID,
                                              to: participantsRefIds,
                                              requestID: requestId,
                                              sessionUUID: requestId,
                                              sessionMediaType: sessionMediaType,
                                              callType: .manytomany)
        output?(.loadView(mediaType: sessionMediaType))
        vtokSdk?.initiate(session: baseSession, sessionDelegate: self)
        callHangupHandling()
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
        output?(.updateHangupButton(status: false))
        vtokSdk?.accept(session: session)
        
    }
    
    func rejectCall(session: VTokBaseSession) {
        vtokSdk?.reject(session: session)
        timer.invalidate()
        counter = 0
        output?(.dismissCallView)
        stopSound()
    }
    
    func hangupCall(session: VTokBaseSession) {
        stopSound()
        timer.invalidate()
        counter = 0
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
    func configureLocalViewFor(session: VTokBaseSession, renderer: UIView) {
        output?(.configureLocal(view: renderer, session: session))
    }
    
    func configureRemoteViews(for session: VTokBaseSession, with streams: [UserStream]) {
        output?(.configureRemote(streams: streams))
    }
    
    func stateDidUpdate(for session: VTokBaseSession) {
        self.session = session
        switch session.state {
        case .ringing:
            output?(.updateView(session: session))
        case .connected:
          didConnect()
        case .rejected:
          sessionReject()
        case .missedCall:
            sessionMissed()
        case .hangup:
            sessionHangup()
        case .tryingToConnect:
            output?(.updateView(session: session))
        default:
            break
        }
    }
    
    
}

extension CallingViewModelImpl {
    private func didConnect() {
        stopSound()
        timer.invalidate()
        counter = 0
        guard let session = session else {return}
        output?(.updateView(session: session))
        output?(.updateHangupButton(status: true))
    }
    
    private func sessionReject() {
        DispatchQueue.main.async {[weak self] in
            self?.output?(.dismissCallView)
            self?.stopSound()
        }
    }
    
    private func sessionMissed() {
        DispatchQueue.main.async {[weak self] in
            self?.output?(.dismissCallView)
            self?.stopSound()
        }
    }
    
    private func sessionHangup() {
        DispatchQueue.main.async {[weak self] in
            
            self?.output?(.dismissCallView)
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

extension CallingViewModelImpl {
    func callHangupHandling() {
        timer.invalidate()
        counter = 0
        timer = Timer.scheduledTimer(timeInterval: 1,
                                     target: self,
                                     selector: #selector(timerAction),
                                     userInfo: nil,
                                     repeats: true)
    }
    
    @objc func timerAction() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {return}
            self.counter += 1
            if self.counter > 30 {
                guard let session = self.session else {return}
                self.counter = 0
                self.timer.invalidate()
                switch session.sessionDirection {
                case .incoming:
                    self.vtokSdk?.reject(session: session)
                    self.output?(.dismissCallView)
                case .outgoing:
                    self.vtokSdk?.hangup(session: session)
                    
                }
                
               
            }
        }
      
        
    }
}
