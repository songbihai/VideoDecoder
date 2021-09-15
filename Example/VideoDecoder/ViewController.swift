//
//  ViewController.swift
//  VideoDecoder
//
//  Created by songbihai on 09/11/2021.
//  Copyright (c) 2021 songbihai. All rights reserved.
//

import UIKit
import VideoToolbox
import VideoDecoder

class ViewController: UIViewController {
    
    var decoder: VideoDecoder!
    var fps: Int = 20
    var type: EncodeType = .h264
    
    var videoFileReader: VideoFileReader!
    var decodeQueue = DispatchQueue(label: "com.videoDecoder.queue")
    var decodeTimer: DispatchSourceTimer?
    

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var encodeTypeLabel: UILabel!
    @IBOutlet weak var fpsLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        videoFileReader = .init(.h264)
        H264Decoder.defaultMinimumGroupOfPictures = 1
        H265Decoder.defaultMinimumGroupOfPictures = 1
        decoder = H264Decoder.init(delegate: self)
        setupTimer()
    }
    
    func setupTimer() {
        if let _ = decodeTimer {
            return
        }
        decodeTimer = DispatchSource.makeTimerSource(queue: decodeQueue)
        decodeTimer?.schedule(deadline: .now(), repeating: .microseconds(1000000/fps))
        decodeTimer?.setEventHandler(handler: {
            self.takeVideoPackets()
         })
    }
    
    func takeVideoPackets() {
        
        if let videoPacket = videoFileReader.nextVideoPacket()  {
            decoder.decodeOnePacket(videoPacket)
        }else {
            if startButton.isSelected {
                DispatchQueue.main.async { [weak self] in
                    if let self = self {
                        self.startAction(self.startButton)
                    }
                }
            }
        }
        
    }
    
    @IBAction func encodeTypeChanged(_ sender: UISwitch) {
        type = sender.isOn ? .h264 : .h265
        encodeTypeLabel.text = sender.isOn ? "H264" : "H265"
        if startButton.isSelected {
            startAction(startButton)
        }
        videoFileReader = .init(type)
        if type == .h264 {
            decoder = H264Decoder(delegate: self)
        }else {
            decoder = H265Decoder(delegate: self)
        }
        imageView.image = nil
    }
    
    @IBAction func fpsChanged(_ sender: UISlider) {
        fps = Int(sender.value)
        VideoFileReader.fps = fps
        fpsLabel.text = "fps: \(fps)"
        
        if startButton.isSelected {
            decodeTimer?.cancel()
            decodeTimer = nil
        }
        if !startButton.isSelected {
            decodeTimer?.resume()
            decodeTimer?.cancel()
            decodeTimer = nil
        }
        setupTimer()
        if startButton.isSelected {
            decodeTimer?.resume()
        }
    }
    
    @IBAction func startAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            decodeTimer?.resume()
        }else {
            decodeTimer?.suspend()
        }
    }
}

extension ViewController: VideoDecoderDelegate {
    
    func decodeOutput(video: CMSampleBuffer) {
        if let image = video.image {
            DispatchQueue.main.async {
                self.imageView.image = image
            }
        }
    }
    
    func decodeOutput(error: DecodeError) {
        print("decodeOutput error: \(error)")
    }
    
    
    
    
}

