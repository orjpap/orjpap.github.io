---

layout: post
title:  "AVAudioSourceNode, AVAudioSinkNode: Low-Level Audio In Swift"
date:   2020-06-19 21:03:36 +0530
categories: Swift Real-time Audio AVFoundation
hidden: false
doctest: false

---

Apple [introduced](https://developer.apple.com/videos/play/wwdc2019/510) **AVAudioSourceNode** and **AVAudioSinkNode** in WWDC2019. These two new AVAudio nodes are part of the [AVFoundation](https://developer.apple.com/documentation/avfoundation) framework and can be used in macOS 10.15 and iOS 13 onwards.

They provide a way to **process input** from an audio device/file, and **generating output** to a device/file, _sample by sample_.

AVAudioSourceNode _sends_ audio to an AVAudioEngine node. The audio is computed in a callback and can be rendered in real-time or offline modes.

AVAudioSinkNode _receives_ audio from an AVAudioEngine node. The audio is processed in a callback and can be rendered in real-time or offline modes.

The following code outputs five seconds of white noise using an AVAudioSourceNode:
```swift
import AVFoundation

func whiteNoise() -> Float {
	return Float.random(in: -1.0...1.0)
}

let whiteNoiseGenerator = AVAudioSourceNode() { (silence, timeStamp, frameCount, audioBufferList) ->
    OSStatus in
    let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
    for frame in 0..<Int(frameCount) {
        let value = whiteNoise()
        for buffer in ablPointer {
            let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
            buf[frame] = value
        }
    }
    return noErr
}

let engine = AVAudioEngine()
engine.attach(whiteNoiseGenerator)
engine.connect(whiteNoiseGenerator, to: engine.mainMixerNode, format: nil)
engine.mainMixerNode.outputVolume = 0.5

try! engine.start()
sleep(5)
engine.stop()
```

Two things might baffle Swift programmers in this example:

1.  **UnsafeMutableAudioBufferListPointer** and **UnsafeMutableBufferPointer**.

    By default, Swift is memory safe: It prevents direct access to memory and makes sure you’ve initialized everything before you use it. But you can also use _unsafe Swift_, which lets you access memory directly through pointers. In this example we use an UnsafeMutableBufferPointer instance in low level operations to eliminate uniqueness checks and bounds checks. I recommend reading [Unsafe Swift](https://pfandrade.me/blog/unsafe-swift/) by Paulo Andrande to get a better understanding of the unsafe side of Swift.
2.  The **OSStatus** return type.

    Almost every Apple C API function signals success or failure through their return value, which is of type OSStatus. Any status other than noErr (which is 0) signals an error. You can find more details [here](https://www.osstatus.com/search/results?platform=all&framework=all&search=)

Why unsafe Swift?
-----------------

First of all unsafe Swift lets you work with [pointers](https://codeburst.io/pointers-in-5-minutes-b94f9d1dfdb5) and interoprate with C libraries.

In addition, unsafe Swift can help you gain a performance boost by sacrificing memory safety. The code you write in the AVAudioSourceNode’s block _must be realtime compliant_. Your callback is called in a real-time thread with a hard deadline. @44,1khz sampling rate with a buffer size of 512 samples gives you ~11ms to complete processing in your callback. If that’s not the case, you get silence. That time limit prohibits:
1.  Memory Allocations
2.  Using Locks
3.  Network Requests or any kind of I/O
4.  Memory boundary checks/uniqueness checks
5.  Checking your Twitter

Check out [this guide](https://github.com/apple/swift/blob/master/docs/OptimizationTips.rst) on writing high-performance Swift code.

Conclusion
----------

AVFoundation really suprised me. It provides a clear, powerful API that can be used to generate audio and I’m looking forward making some stuff with it. I’m wondering how it compares to the Audio Unit impementation performance-wise, or if there’s no difference at all because a core audio implementation is hiding under the hood of the two new AVAudioNodes.


Feel free to [contact me](mailto:orjpap@gmail.com) or tweet to me on [Twitter](https://twitter.com/orjpap) if you have any additional tips or feedback.

Thanks!