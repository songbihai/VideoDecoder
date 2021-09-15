//
//  VideoFileReader.swift
//  VideoDecoder_Example
//
//  Analog push video stream
//  模拟推视频流
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
import VideoDecoder

class VideoFileReader {
    
    static var fps: Int = 20
    
    var type: EncodeType
    
    var streamBuffer: [UInt8] = []
    var fileStream: InputStream?
    private var fps: Int {
        return VideoFileReader.fps
    }
    
    init(_ type: EncodeType) {
        self.type = type
        let forResource = type == .h264 ? "h264Data" : "h265Data";
        guard let path = Bundle.main.path(forResource: forResource, ofType: nil) else {
            return
        }
        fileStream = InputStream.init(fileAtPath: path)
        fileStream?.open()
    }
    
    func nextVideoPacket() -> VideoPacket? {
        
        guard streamBuffer.count != 0 || readStremData() != 0 else {
            return nil
        }
        
        guard streamBuffer.count > 4 && [UInt8](streamBuffer[0...3]) == [0,0,0,1] else {
            return nil
        }
        
        var startIndex = 4
        
        while true {
            while ((startIndex + 3) < streamBuffer.count) {
                if [UInt8](streamBuffer[startIndex...startIndex+3]) == [0,0,0,1] {
                    let data = [UInt8](streamBuffer[0..<startIndex])
                    streamBuffer.removeSubrange(0..<startIndex)
                    return VideoPacket.init(data, fps: fps, type: type, videoSize: CGSize(width: 1920, height: 1080))
                }
                startIndex += 1
            }
            if readStremData() == 0 {
                return nil
            }
        }
        
    }
    
    func readStremData() -> Int {
        if let stream = fileStream, stream.hasBytesAvailable {
            var tempArray = [UInt8](repeating: 0, count: 512 * 1024)
            let bytes = stream.read(&tempArray, maxLength: 512 * 1024)
            if bytes > 0 {
                streamBuffer.append(contentsOf: Array(tempArray[0..<bytes]))
            }
            return bytes
        }
        
        return 0
    }
    
}
