//
//  H264Decoder.swift
//  DecoderKit
//
//  Created by songbihai on 2021/9/7.
//

import UIKit
import AVFoundation
import VideoToolbox

open class H264Decoder: VideoDecoder {
    
    public static var defaultMinimumGroupOfPictures: Int = 12
    
    public static let defaultDecodeFlags: VTDecodeFrameFlags = [
        ._EnableAsynchronousDecompression,
        ._EnableTemporalProcessing
    ]
    
    public static let defaultAttributes: [NSString: AnyObject] = [
        kCVPixelBufferPixelFormatTypeKey: NSNumber(value: kCVPixelFormatType_32BGRA),
        kCVPixelBufferIOSurfacePropertiesKey: [:] as AnyObject,
        kCVPixelBufferOpenGLESCompatibilityKey: NSNumber(booleanLiteral: true)
    ]
    
    open var delegate: VideoDecoderDelegate
    
    private var spsUnit: H264NalUnit?
    private var ppsUnit: H264NalUnit?
    private var fps: Int = 0
    private var videoSize: CGSize = .zero
    private var invalidateSession: Bool = false
    private var buffers: [CMSampleBuffer] = []
    private var minimumGroupOfPictures: Int = H264Decoder.defaultMinimumGroupOfPictures
    private var formatDesc: CMVideoFormatDescription?
    private var callback: VTDecompressionOutputCallback = {(decompressionOutputRefCon: UnsafeMutableRawPointer?, _: UnsafeMutableRawPointer?, status: OSStatus, infoFlags: VTDecodeInfoFlags, imageBuffer: CVBuffer?, presentationTimeStamp: CMTime, duration: CMTime) in
        let decoder: H264Decoder = Unmanaged<H264Decoder>.fromOpaque(decompressionOutputRefCon!).takeUnretainedValue()
        decoder.didOutputForSession(status, infoFlags: infoFlags, imageBuffer: imageBuffer, presentationTimeStamp: presentationTimeStamp, duration: duration)
    }
    private var attributes: [NSString: AnyObject] {
        H264Decoder.defaultAttributes
    }
        
    private var session: VTDecompressionSession?
    
    public init(delegate: VideoDecoderDelegate) {
        self.delegate = delegate
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.didAudioSessionInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.applicationWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    open func initDecoder(vpsUnit: NalUnitProtocol?, spsUnit: NalUnitProtocol?, ppsUnit: NalUnitProtocol?, isReset: Bool) {
        if isReset || invalidateSession {
            deinitDecoder()
        }
        if let _ = session {
            return
        }
        guard let spsUnit = spsUnit, let ppsUnit = ppsUnit else {
            delegate.decodeOutput(error: .notFoundVpsOrSpsOrPps)
            return
        }
        let parameterSetPointers: [UnsafePointer<UInt8>] = [ppsUnit.outHeadBuffer, spsUnit.outHeadBuffer]
        let parameterSetSizes: [Int] = [ppsUnit.bufferSize - 4, spsUnit.bufferSize - 4]
        var status = CMVideoFormatDescriptionCreateFromH264ParameterSets(allocator: kCFAllocatorDefault, parameterSetCount: 2, parameterSetPointers: parameterSetPointers, parameterSetSizes: parameterSetSizes, nalUnitHeaderLength: 4, formatDescriptionOut: &formatDesc)
        if status != noErr {
            delegate.decodeOutput(error: .videoFormatDescriptionCreateFromH264ParameterSets(status))
            return
        }
        guard let format = formatDesc else {
            return
        }
        var record = VTDecompressionOutputCallbackRecord(
            decompressionOutputCallback: callback,
            decompressionOutputRefCon: Unmanaged.passUnretained(self).toOpaque()
        )
        status = VTDecompressionSessionCreate(
            allocator: kCFAllocatorDefault,
            formatDescription: format,
            decoderSpecification: nil,
            imageBufferAttributes: attributes as CFDictionary?,
            outputCallback: &record,
            decompressionSessionOut: &session)
        if status != noErr {
            delegate.decodeOutput(error: .decompressionSessionCreate(status))
        }
    }
    
    open func deinitDecoder() {
        if let session = session {
            VTDecompressionSessionInvalidate(session)
            self.session = nil
        }
    }
    
    open func decodeOnePacket(_ packet: VideoPacket) {
        if fps != packet.fps || videoSize != packet.videoSize {
            invalidateSession = true
        }
        
        let nalUnits = NalUnitParser.unitParser(packet: packet)
        var currntUnit: H264NalUnit?
        nalUnits.forEach { nalUnit in
            print("================\(nalUnit.type)")
            if let unit = nalUnit as? H264NalUnit {
                switch unit.type {
                case .sps:
                    if let _ = spsUnit {
                        break
                    }
                    spsUnit = unit
                case .pps:
                    if let _ = ppsUnit {
                        break
                    }
                    ppsUnit = unit
                case .idr:
                    initDecoder(vpsUnit: nil, spsUnit: spsUnit, ppsUnit: ppsUnit, isReset: false)
                    currntUnit = unit
                case .pFrame:
                    currntUnit = unit
                default:
                    break
                }
            }
            guard let unit = currntUnit else {
                return
            }
            decodeVideoUnit(unit)
        }
    }
    
    open func decodeVideoUnit(_ unit: H264NalUnit) {
                        
        var blockBuffer: CMBlockBuffer?
        let buffer = UnsafeMutableRawPointer(mutating: unit.lengthHeadBuffer)
        var status = CMBlockBufferCreateWithMemoryBlock(allocator: kCFAllocatorDefault, memoryBlock: buffer, blockLength: unit.bufferSize, blockAllocator: kCFAllocatorNull, customBlockSource: nil, offsetToData: 0, dataLength: unit.bufferSize, flags: 0, blockBufferOut: &blockBuffer)
        if status != noErr {
            delegate.decodeOutput(error: .blockBufferCreateWithMemoryBlock(status))
            return
        }
        
        if let blockBuff = blockBuffer {
            
            var sampleBuffer: CMSampleBuffer?
            let sampleSizeArray : [Int] = [unit.bufferSize]
            status = CMSampleBufferCreateReady(allocator: kCFAllocatorDefault, dataBuffer: blockBuff, formatDescription: formatDesc, sampleCount: 1, sampleTimingEntryCount: 0, sampleTimingArray: nil, sampleSizeEntryCount: 1, sampleSizeArray: sampleSizeArray, sampleBufferOut: &sampleBuffer)
            if status != noErr {
                delegate.decodeOutput(error: .sampleBufferCreateReady(status))
                return
            }
            
            if let sampleBuff = sampleBuffer, let session = session {
                
                let flagIn: VTDecodeFrameFlags = .init(rawValue: 0)
                var flagOut: VTDecodeInfoFlags = .init(rawValue: 0)
                status = VTDecompressionSessionDecodeFrame(session, sampleBuffer: sampleBuff, flags: flagIn, frameRefcon: nil, infoFlagsOut: &flagOut)
                if status != noErr {
                    delegate.decodeOutput(error: .decompressionSessionDecodeFrame(status))
                }
                
            }
            
        }
        
    }
    
    private func didOutputForSession(_ status: OSStatus, infoFlags: VTDecodeInfoFlags, imageBuffer: CVImageBuffer?, presentationTimeStamp: CMTime, duration: CMTime) {
        
        guard let imageBuffer: CVPixelBuffer = imageBuffer, status == noErr else {
            delegate.decodeOutput(error: .decompressionOutputCallback(status))
            return
        }
        
        var timingInfo = CMSampleTimingInfo(
            duration: duration,
            presentationTimeStamp: presentationTimeStamp,
            decodeTimeStamp: CMTime.invalid
        )

        var videoFormatDescription: CMVideoFormatDescription?
        var status = CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: imageBuffer,
            formatDescriptionOut: &videoFormatDescription
        )
        guard status == noErr else {
            delegate.decodeOutput(error: .videoFormatDescriptionCreateForImageBuffer(status))
            return
        }

        var sampleBuffer: CMSampleBuffer?
        status = CMSampleBufferCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: imageBuffer,
            dataReady: true,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: videoFormatDescription!,
            sampleTiming: &timingInfo,
            sampleBufferOut: &sampleBuffer
        )
        guard status == noErr else {
            delegate.decodeOutput(error: .sampleBufferCreateForImageBuffer(status))
            return
        }

        guard let buffer: CMSampleBuffer = sampleBuffer else {
            return
        }
        
        buffers.append(buffer)
        buffers.sort {
            $0.presentationTimeStamp < $1.presentationTimeStamp
        }
        if buffers.count >= minimumGroupOfPictures {
            delegate.decodeOutput(video: buffers.removeFirst())
        }
      
    }
    
    @objc
    private func applicationWillEnterForeground(_ notification: Notification) {
        invalidateSession = true
    }

    @objc
    private func didAudioSessionInterruption(_ notification: Notification) {
        guard
            let userInfo: [AnyHashable: Any] = notification.userInfo,
            let value: NSNumber = userInfo[AVAudioSessionInterruptionTypeKey] as? NSNumber,
            let type: AVAudioSession.InterruptionType = AVAudioSession.InterruptionType(rawValue: value.uintValue) else {
            return
        }
        switch type {
        case .ended:
            invalidateSession = true
        default:
            break
        }
    }
    
    deinit {
        deinitDecoder()
        self.invalidateSession = true
        self.buffers.removeAll()
        NotificationCenter.default.removeObserver(self)
    }
    
}
