import UIKit

public enum EncodeType {
    case h264
    case h265
}

open class VideoPacket {

    open private(set) var type: EncodeType
    open private(set) var buffer: UnsafePointer<UInt8>
    open private(set) var bufferSize: Int
    open private(set) var fps: Int
    open private(set) var isIFrame: Bool
    open private(set) var videoSize: CGSize
        
    public convenience init(_ data: NSData, fps: Int, isIFrame: Bool = false, type: EncodeType, videoSize: CGSize) {
        let buffer = data as Data
        self.init(buffer, fps: fps, isIFrame: isIFrame, type: type, videoSize: videoSize)
    }
    
    public convenience init(_ data: Data, fps: Int, isIFrame: Bool = false, type: EncodeType, videoSize: CGSize) {
        let buffer = [UInt8](data)
        self.init(buffer, fps: fps, isIFrame: isIFrame, type: type, videoSize: videoSize)
    }
    
    public convenience init(_ data: [UInt8], fps: Int, isIFrame: Bool = false, type: EncodeType, videoSize: CGSize) {
        let uint8Pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
        uint8Pointer.initialize(from: data, count:data.count)
        let buffer = UnsafePointer(uint8Pointer)
        self.init(buffer, bufferSize: data.count, fps: fps, isIFrame: isIFrame, type: type, videoSize: videoSize)
        buffer.deallocate()
    }
    
    public init(_ buffer: UnsafePointer<UInt8>, bufferSize: Int, fps: Int, isIFrame: Bool = false, type: EncodeType, videoSize: CGSize) {
        
        self.buffer = buffer.copy(capacity: bufferSize)
        self.bufferSize = bufferSize
        self.fps = fps;
        self.isIFrame = isIFrame
        self.type = type
        self.videoSize = videoSize
        
    }
    
    deinit {
        buffer.deallocate()
    }
  
}

public extension VideoPacket {
    static func ==(lhs: VideoPacket, rhs: VideoPacket) -> Bool {
        if lhs.bufferSize != rhs.bufferSize {
            return false
        }
        return memcmp(lhs.buffer, rhs.buffer, lhs.bufferSize) == 0
    }

    static func !=(lhs: VideoPacket, rhs: VideoPacket) -> Bool {
        if lhs.bufferSize != rhs.bufferSize {
            return true
        }
        return memcmp(lhs.buffer, rhs.buffer, lhs.bufferSize) != 0
    }
}
