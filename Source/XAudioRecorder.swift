//
//  XAudioRecorder.swift
//  XAudioRecorder
//
//  Created by 闫明 on 2019/5/13.
//  Copyright © 2019 闫明. All rights reserved.
//

import UIKit
import AVFoundation
public protocol XAudioRecorderDelegate : NSObjectProtocol {
    func audioProgress(_ recorder: AVAudioRecorder, currentTime: Int64, meter power: Float)
    func audioRecorder(status: XAudioRecorder.Status)
}
extension XAudioRecorder {
    public enum Status {
        case unknown
        case recording
        case pause
        case stop
        case success(String?, Int64)// 录音地址 录音时长
        case error(Error)
    }
    public enum Format {
        case aac
        case mp3
    }
}
public class XAudioRecorder: NSObject {
    private var recorder: AVAudioRecorder?
    open private(set) var status: XAudioRecorder.Status = .unknown{
        didSet{
            DispatchQueue.main.async {
                self.delegate?.audioRecorder(status: self.status)
            }
        }
    }
    private(set) var error: Error?
    open weak var delegate: XAudioRecorderDelegate?
    open private(set) var currentTime: Int64 = 0
    /// 自动截断录音/s
    open var autoCutDuration: Int = 0
    /// is it recording or not?
    open private(set) var isRecording: Bool = false
    private(set) var isStop: Bool = false
    /// URL of the recorded file
    private(set) var recordPath: String?
    private let format: XAudioRecorder.Format
    public init(format: XAudioRecorder.Format = .aac){
        self.format = format
        super.init()
        self.setupAudioSession()
    }
    private var timer: XTimer?
    lazy var settings: [String: Any] = {
        let idKey = self.format == .aac ? kAudioFormatMPEG4AAC : kAudioFormatLinearPCM
        let temp: [String: Any] = [
            AVSampleRateKey: NSNumber(value: 44100.0),
            AVFormatIDKey: idKey,
            AVNumberOfChannelsKey: NSNumber(value: 2),
            AVLinearPCMBitDepthKey: NSNumber(value: 16),
        ]
        return temp
    }()
    lazy var convert: MCAudioManager = {
        let c = MCAudioManager()
        return c
    }()
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension XAudioRecorder {

    /// start or resume recording to file. 
    open func record() {
        resetRecord()
        guard let recorder = self.recorder, recorder.prepareToRecord() else { return }
        recorder.record()
        self.status = .recording
        self.isRecording = true
        if let timer = self.timer {
            timer.start()
        }else {
            self.timer = XTimer(interval: .fromSeconds(0.1), repeats: true, queue: DispatchQueue.global(), handler: {[weak self] (timer) in
                guard let `self` = self else {return}
                guard let recorder = self.recorder, recorder.isRecording else { return }
                recorder.updateMeters()
                let power = recorder.averagePower(forChannel: 0)//peak 最大 average平均
                self.currentTime += 1 * 100
                self.delegate?.audioProgress(recorder, currentTime: self.currentTime, meter: power)
                if self.autoCutDuration > 0, self.currentTime == self.autoCutDuration * 1000 {
                    print("超出",self.currentTime)
                    self.stop()
                    self.isStop = false
                }
            })
            self.timer?.start()
        }

    }

    /// pause recording
    open func pause() {
        guard let recorder = self.recorder, recorder.isRecording else { return }
        recorder.pause()
        self.timer?.suspend()
        self.isRecording = false
        self.status = .pause
    }

    /// stops recording. closes the file.
    open func stop() {
        guard let recorder = self.recorder, recorder.isRecording else { return }
        self.timer = nil
        recorder.stop()
        self.isRecording = false
        self.status = .stop
        self.isStop = true
    }
    open func clear(){
        let folder = NSHomeDirectory() + "/Documents/recorder"
        try? FileManager.default.removeItem(atPath: folder)
    }
}
extension XAudioRecorder: AVAudioRecorderDelegate {
    public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        guard flag, let path = recordPath else {return}
        let tempCurrentTime = self.currentTime
        if self.format == .aac {
            self.status = .success(self.recordPath, tempCurrentTime)
            self.currentTime = 0
        }else {
            let temp = NSHomeDirectory() + "/Documents/recorder"
            let mp3Path = temp + "/\(Int(Date().timeIntervalSince1970)).mp3"
            self.convert.audioPCMtoMP3(path, filePath: mp3Path) {[weak self] (errMessage) in
                guard let `self` = self else {return}
                self.status = .success(mp3Path, tempCurrentTime)
                self.currentTime = 0
            }
        }
        if !self.isStop {
            self.record()
        }
    }
    public func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?){
        if let e = error {
            self.isRecording = false
            self.status = .error(e)
        }
    }
}
extension XAudioRecorder {

    private func resetRecord(){
        do{
            let url = takeFile()
            self.recorder = nil
            self.recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.delegate = self
            recorder?.isMeteringEnabled = true
        }catch{
            print(error)
            self.isRecording = false
            self.status = .error(error)
        }
    }
    private func takeFile()-> URL{
        let temp = NSHomeDirectory() + "/Documents/recorder"
        if !FileManager.default.fileExists(atPath: temp) {
            try? FileManager.default.createDirectory(atPath: temp, withIntermediateDirectories: true, attributes: nil)
        }
        let gmt = Int(Date().timeIntervalSince1970)
        let ext = self.format == .aac ? ".aac" : ".caf"
        let recordPath = temp + "/\(gmt)" + ext
        self.recordPath = recordPath
        return URL(fileURLWithPath: recordPath)
    }
    private func setupAudioSession(){
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive(noti:)), name: UIApplication.willResignActiveNotification, object: nil)
        do {
            if #available(iOS 10.0, *) {
                try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [AVAudioSession.CategoryOptions.defaultToSpeaker, .mixWithOthers, .allowBluetooth])
            } else {
                AVAudioSession.sharedInstance()
                    .perform(NSSelectorFromString("setCategory:error:"), with: AVAudioSession.Category.playAndRecord)
            }
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("XAudioRecorder -- AudioSession: ", error)
        }
    }
    @objc private func willResignActive(noti: Notification) {
        self.stop()
    }
}
