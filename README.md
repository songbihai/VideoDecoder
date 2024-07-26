# VideoDecoder

iOS platform video hard decoding, support h264, h265

Using VideoDecoder requires you to handle threads yourself

### Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

h264:
```swift
//Initialize the decoder instance and assign it a delegate to receive the decoded data  
//callbacks
let decoder = H264Decoder(delegate: self)

//Initialize the videoPacket instance of h264 encode data
decoder.decodeOnePacket(videoPacket)

```

h265:
```swift
//Initialize the decoder instance and assign it a delegate to receive the decoded data  
//callbacks
let decoder = H265Decoder(delegate: self)

//Initialize the videoPacket instance of h265 encode data
decoder.decodeOnePacket(videoPacket)

```
VideoPacket:
```swift
//Initialize the videoPacket instance functions
init(_ data: NSData, fps: Int, isIFrame: Bool = false, type: EncodeType, videoSize: CGSize)
init(_ data: Data, fps: Int, isIFrame: Bool = false, type: EncodeType, videoSize: CGSize)
init(_ data: [UInt8], fps: Int, isIFrame: Bool = false, type: EncodeType, videoSize: CGSize)
init(_ buffer: UnsafePointer<UInt8>, bufferSize: Int, fps: Int, isIFrame: Bool = false, type: EncodeType, videoSize: CGSize)

```


### Build Requirements

iOS

  >11.0+
  >Swift5.0+

## Installation

### CocoaPods

```ruby
pod 'VideoDecoder'
```

### Carthage

```ruby
github "songbihai/VideoDecoder"
```

### Reward

If VideoDecoder helps you in the development, if you need technical support or you need custom features, you can reward me.

<!--BTC: 
1Ck25TZVwoKgfAudvN8hfohrn5yh45NHiz

ETH:
0xc1ebe8b486cf27e19de5c067ee4462ca6af18823-->


<!-- ![Ali pay](https://i.loli.net/2021/09/15/z5LuainUDeIRTpZ.jpg)  ![WeChat pay](https://i.loli.net/2021/09/15/e8GXMf1CIxR9KVo.jpg) -->

## License

VideoDecoder is available under the MIT license. See the LICENSE file for more info.


# Star History

[![Star History Chart](https://api.star-history.com/svg?repos=songbihai/VideoDecoder&type=Date)](https://star-history.com/#songbihai/VideoDecoder&Date)

