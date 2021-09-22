import UIKit
import CoreMedia

open class NalUnitParser {

    private class var startCode: UnsafeMutablePointer<UInt8> {
        let start: [UInt8] = [0,0,0,1]
        let startBuffer = start.withUnsafeBytes { return $0 }
        let rawPointer = UnsafeMutableRawPointer(mutating: startBuffer.baseAddress!)
        return rawPointer.bindMemory(to: UInt8.self, capacity: 4)
    }
    
    open class func unitParser(packet: VideoPacket) -> [NalUnitProtocol] {
        var nalUnits: [NalUnitProtocol] = []
        let length = packet.bufferSize;
        if length > 4 {
            var unitBegin = packet.buffer
            var unitEnd = packet.buffer + 4
            while unitEnd != (packet.buffer + length) {
                if unitEnd.pointee == 0x01 {
                    if memcmp(unitEnd - 3, startCode, 4) == 0 {
                        let count = unitEnd - 3 - unitBegin
                        if let unit =  nalUnit(type: packet.type, buffer: unitBegin, bufferSize: count) {
                            nalUnits.append(unit)
                        }
                        unitBegin = unitEnd - 3
                    }
                }
                unitEnd += 1
            }
            let count = unitEnd - unitBegin
            if let unit =  nalUnit(type: packet.type, buffer: unitBegin, bufferSize: count) {
                nalUnits.append(unit)
            }
        }
        return nalUnits
    }
    
    private class func nalUnit(type: EncodeType, buffer: UnsafePointer<UInt8>, bufferSize: Int) -> NalUnitProtocol? {
        guard bufferSize > 4 else {
            return nil
        }
        if type == .h264 {
            return H264NalUnit(buffer, bufferSize: bufferSize)
        }else {
            return H265NalUnit(buffer, bufferSize: bufferSize)
        }
    }
    
}
