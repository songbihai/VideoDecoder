import CoreMedia
import UIKit

public extension CMSampleBuffer {
    
    var image: UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(self) else { return nil }
        CVPixelBufferLockBaseAddress(imageBuffer, [])
        let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer)
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
        guard let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: rgbColorSpace, bitmapInfo: bitmapInfo.rawValue) else { return nil }
        guard let cgImage = context.makeImage() else { return nil }
        let image = UIImage(cgImage: cgImage)
        return image
    }
    
    var isNotSync: Bool {
        get {
            getAttachmentValue(for: kCMSampleAttachmentKey_NotSync) ?? false
        }
        set {
            setAttachmentValue(for: kCMSampleAttachmentKey_NotSync, value: newValue)
        }
    }

    var isValid: Bool {
        CMSampleBufferIsValid(self)
    }

    var dataBuffer: CMBlockBuffer? {
        get {
            CMSampleBufferGetDataBuffer(self)
        }
        set {
            _ = newValue.map {
                CMSampleBufferSetDataBuffer(self, newValue: $0)
            }
        }
    }

    var imageBuffer: CVImageBuffer? {
        CMSampleBufferGetImageBuffer(self)
    }

    var numSamples: CMItemCount {
        CMSampleBufferGetNumSamples(self)
    }

    var duration: CMTime {
        CMSampleBufferGetDuration(self)
    }

    var formatDescription: CMFormatDescription? {
        CMSampleBufferGetFormatDescription(self)
    }

    var decodeTimeStamp: CMTime {
        CMSampleBufferGetDecodeTimeStamp(self)
    }

    var presentationTimeStamp: CMTime {
        CMSampleBufferGetPresentationTimeStamp(self)
    }

    // swiftlint:disable discouraged_optional_boolean
    @inline(__always)
    private func getAttachmentValue(for key: CFString) -> Bool? {
        guard
            let attachments = CMSampleBufferGetSampleAttachmentsArray(self, createIfNecessary: false) as? [[CFString: Any]],
            let value = attachments.first?[key] as? Bool else {
            return nil
        }
        return value
    }

    @inline(__always)
    private func setAttachmentValue(for key: CFString, value: Bool) {
        guard
            let attachments: CFArray = CMSampleBufferGetSampleAttachmentsArray(self, createIfNecessary: true), 0 < CFArrayGetCount(attachments) else {
            return
        }
        let attachment = unsafeBitCast(CFArrayGetValueAtIndex(attachments, 0), to: CFMutableDictionary.self)
        CFDictionarySetValue(
            attachment,
            Unmanaged.passUnretained(key).toOpaque(),
            Unmanaged.passUnretained(value ? kCFBooleanTrue : kCFBooleanFalse).toOpaque()
        )
    }
    
}
