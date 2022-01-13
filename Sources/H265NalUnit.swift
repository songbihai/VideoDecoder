import UIKit

open class H265NalUnit: NalUnitProtocol {
    
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
        let typeValue = (outHeadBuffer.pointee & 0x7E) >> 1
        switch typeValue {
        case 0x01:
            type = .pFrame
        case 0x13:
            type = .idr
        case 0x20:
            type = .vps
        case 0x21:
            type = .sps
        case 0x22:
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
