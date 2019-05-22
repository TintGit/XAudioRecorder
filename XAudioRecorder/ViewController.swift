//
//  ViewController.swift
//  XAudioRecorder
//
//  Created by 闫明 on 2019/5/13.
//  Copyright © 2019 闫明. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    
    @IBAction func startAction(_ sender: UIButton) {
        self.recorder.record()
    }
    @IBAction func pauseAction(_ sender: UIButton) {
        self.recorder.pause()
    }
    @IBAction func stopAction(_ sender: UIButton) {
        self.recorder.stop()
    }
    lazy var recorder: XAudioRecorder = {
        let r = XAudioRecorder(format: .aac)
        return r
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
    }


}

