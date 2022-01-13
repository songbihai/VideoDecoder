import Foundation
import AVFoundation
import VideoToolbox

public enum DecodeError : Error, CustomStringConvertible {
    
    case notFoundVpsOrSpsOrPps
    
    case pixelBufferCreate(CVReturn)
    
    case blockBufferCreateWithMemoryBlock(OSStatus)
    
    case sampleBufferCreateReady(OSStatus)
    
    case decompressionSessionDecodeFrame(OSStatus)
    
    case decompressionOutputCallback(OSStatus)
    
    case videoFormatDescriptionCreateFromH264ParameterSets(OSStatus)
    
    case videoFormatDescriptionCreateFromHEVCParameterSets(OSStatus)
    
    case decompressionSessionCreate(OSStatus)
    
    case videoFormatDescriptionCreateForImageBuffer(OSStatus)
    
    case sampleBufferCreateForImageBuffer(OSStatus)
    
    public var description : String {
        
        switch self {
        case .notFoundVpsOrSpsOrPps: return "DecodeError.notFoundVpsOrSpsOrPps"
            
        case .pixelBufferCreate(let ret): return "DecodeError.pixelBufferCreate(\(ret))"
            
        case .blockBufferCreateWithMemoryBlock(let status): return "DecodeError.blockBufferCreateWithMemoryBlock(\(status))"
            
        case .sampleBufferCreateReady(let status): return "DecodeError.sampleBufferCreateReady(\(status))"
            
        case .decompressionSessionDecodeFrame(let status): return "DecodeError.decompressionSessionDecodeFrame(\(status))"
            
        case .decompressionOutputCallback(let status): return "DecodeError.decompressionOutputCallback(\(status))"
            
        case .videoFormatDescriptionCreateFromH264ParameterSets(let status): return "DecodeError.videoFormatDescriptionCreateFromH264ParameterSets(\(status))"
            
        case .videoFormatDescriptionCreateFromHEVCParameterSets(let status): return "DecodeError.videoFormatDescriptionCreateFromHEVCParameterSets(\(status))"
            
        case .decompressionSessionCreate(let status): return "DecodeError.decompressionSessionCreate(\(status))"
            
        case .videoFormatDescriptionCreateForImageBuffer(let status): return "DecodeError.videoFormatDescriptionCreateForImageBuffer(\(status))"
            
        case .sampleBufferCreateForImageBuffer(let status): return "DecodeError.sampleBufferCreateForImageBuffer(\(status))"
        }
        
    }
}

public protocol VideoDecoderDelegate: AnyObject {
    
    func decodeOutput(video: CMSampleBuffer)
    
    func decodeOutput(error: DecodeError)
    
}

public protocol VideoDecoder: AnyObject {
    
    var isBaseline: Bool { get set }
    
    var delegate: VideoDecoderDelegate { get set}
    
    func initDecoder(vpsUnit: NalUnitProtocol?, spsUnit: NalUnitProtocol?, ppsUnit: NalUnitProtocol?, isReset: Bool)
    
    func deinitDecoder()
    
    func decodeOnePacket(_ packet: VideoPacket)
    
    func decodeVideoUnit(_ unit: NalUnitProtocol) 
    
}

