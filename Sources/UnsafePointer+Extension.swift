import Foundation

public extension UnsafePointer {
    
    func copy(capacity: Int) -> UnsafePointer {
        
        let mutablePointer = UnsafeMutablePointer<Pointee>.allocate(capacity: capacity)
        mutablePointer.initialize(from: self, count:capacity)
        return UnsafePointer(mutablePointer)
        
    }
    
}
