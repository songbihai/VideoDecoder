# VideoDecoder

iOS platform video hard decoding, support h264, h265

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

<!-- ### Reward

If VideoDecoder helps you in the development, if you need technical support or you need custom features, you can reward me. -->

<!-- BTC: 
3BGTcyasYoZDV7MjHqMiQuew4R925vC6kL

ETH:
0x83f931a297C3A05Fd0eF3891670f85316EB12A4C -->


<!-- ![Ali pay](https://i.loli.net/2021/09/15/z5LuainUDeIRTpZ.jpg)  ![WeChat pay](https://i.loli.net/2021/09/15/e8GXMf1CIxR9KVo.jpg) -->

## License

VideoDecoder is available under the MIT license. See the LICENSE file for more info.
