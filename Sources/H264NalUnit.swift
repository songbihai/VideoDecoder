import UIKit
import CoreFoundation

open class H264NalUnit: NalUnitProtocol {
    
    open private(set) var bufferSize: Int
    open private(set) var buffer: UnsafePointer<UInt8>
    open private(set) var outHeadBuffer: UnsafePointer<UInt8>
    open private(set) var lengthHeadBuffer: UnsafePointer<UInt8>?
    open private(set) var type: NalUnitType
    
    public init(_ buffer: UnsafePointer<UInt8>, bufferSize: Int) {
        self.buffer = buffer.copy(capacity: bufferSize)
        self.bufferSize = bufferSize
        outHeadBuffer = self.buffer + 4
        var length = CFSwapInt32HostToBig(UInt32(bufferSize - 4))
        let rawPointer = UnsafeMutableRawPointer.allocate(byteCount: bufferSize, alignment: MemoryLayout<UInt8>.alignment)
        rawPointer.initializeMemory(as: UInt8.self, from: self.buffer, count: bufferSize)
        memcpy(rawPointer, &length, 4)
        let rawBufferPointer = UnsafeRawBufferPointer(start: rawPointer, count: bufferSize)
        if let baseAddress = rawBufferPointer.baseAddress {
            let outRawPointer = UnsafeRawPointer(baseAddress)
            lengthHeadBuffer = outRawPointer.bindMemory(to: UInt8.self, capacity: bufferSize)
        }
        var type: NalUnitType = .other
        let typeValue = outHeadBuffer.pointee & 0x1f
        switch typeValue {
        case 0x01:
            type = .pFrame
        case 0x02:
            type = .pFrame
        case 0x03:
            type = .pFrame
        case 0x04:
            type = .pFrame
        case 0x05:
            type = .idr
        case 0x07:
            type = .sps
        case 0x08:
            type = .pps
        default:
            break
        }
        self.type = type
    }
    
    deinit {
        buffer.deallocate()
        lengthHeadBuffer?.deallocate()
    }
    
}
