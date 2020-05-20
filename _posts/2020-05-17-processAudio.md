---
layout: post
title:  "AVAudioSourceNode, AVAudioSinkNode or How I deleted a Repo in Less Than 24 hours"
date:   2020-05-19 10:03:36 +0530
categories: Swift Real-time Audio AVFoundation
doctest: true 
---

Two days ago, I set out to create a simple Swift library for real-time audio processing. I was aiming to provide an easy to setup way of **processing input** from an audio device/file, and **generating output** to a device/file, sample by sample.

[AudioKit](https://audiokit.io) which is an audio toolkit for iOS, macOS, and tvOS, offers a well documented Swift API but is a big dependency to add to a project if you only need to perform these tasks. 

On the other hand, **Core Audio** (initially released in 2003), Apple's lowest level of abstraction audio framework, clearly states on the front page of its [documentation](https://developer.apple.com/documentation/coreaudio): "Use the Core Audio framework to interact with device’s audio hardware.". Being so close to hardware comes with a lot of **responsibilities** and responsibilities mean **boilerplate**. 

Finally, last time I checked™, [AVFoundation](https://developer.apple.com/av-foundation/) was too high-level for these tasks.

So I took a copy of Chris Adamson's [Learning Core Audio](https://www.amazon.com/Learning-Core-Audio-Hands-Programming/dp/0321636848) book off of my dusty electronic bookshelf and started digging into **Audio Units**. An audio unit is a software object that performs some sort of work on a stream of audio, frame by frame[^2]. In order to generate sound we need to fill a buffer with (typically) 32-bit floating point values ranging between -1.0, 1.0. The stream of these values can be used to describe the displacement of the speaker's cone in time, which then produces displacement in air particles which are perceived by our ears as sounds. This work is executed on a real-time high priority thread and is usually referred to as a render block or process block. For a more in-depth explanation [read this.](https://docs.cycling74.com/max5/tutorials/msp-tut/mspdigitalaudio.html)

## ProcessAudio

The hello world of audio generators is a **sinewave**. But let's make some **noise** instead. In order to do so using the Audio Units API we need to:

1. Find the default output audio component
2. Create a new instance of an audio unit and attach it to the default output
3. Set the renderBlock property of the audio unit to our **noise generator**: A function that returns a random 32-bit floating point number in the closed range [-1.0, 1.0].
4. Start the audio unit
5. Sleep on the current thread so that we can hear the audio being generated on the real-time thread.
6. Clean up the audio unit

Even though the Audio Units API is accessible by Swift, it's a C API, the setup spans almost 70 lines of code and it looks like [this](https://www.cocoawithlove.com/2010/10/ios-tone-generator-introduction-to.html). So I created a wrapper around this setup code that could be used like so:

```swift
func whiteNoise() -> Float {
	return Float.random(in: -1.0...1.0)
}

let device = ProcessAudio.defaultOutput
device?.connect { _, buffer, bufferSize in
    for frameNumber in 0..<Int(bufferSize) {
        buffer[frameNumber] = whiteNoise()
    }
})

device?.start()
sleep(5)
device?.stop()
```

And that was the birth of **ProcessAudio**. I turned it into a Swift Package using SPM, wrote some tests, made sure it compiles in both macOS and iOS and took notes on how I can improve and expand the API. 

## AVAudioNodes

Everything was going according to plan, until I found out about **AVAudioSourceNode** and **AVAudioSinkNode** that were [introduced](https://developer.apple.com/videos/play/wwdc2019/510) in WWDC2019. These two new AVAudio nodes are part of the [AVFoundation](https://developer.apple.com/documentation/avfoundation) framework and can be used in macOS 10.15 and iOS 13 onwards. 

AVAudioSourceNode *sends* audio to an AVAudioEngine node. The audio is computed in a callback and can be rendered in real-time or offline modes.

AVAudioSinkNode *receives* audio from an AVAudioEngine node. The audio is processed in a callback and can be rendered in real-time or offline modes.

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

The API addresses the exact same points that I wanted to address by making ProcessAudio and it actually looks very similar! How nice.

Two things might baffle Swift programmers in this example:

1. **UnsafeMutableAudioBufferListPointer** and **UnsafeMutableBufferPointer**. 

   By default, Swift is memory safe: It prevents direct access to memory and makes sure you’ve initialized everything before you use it. But you can also use *unsafe Swift*, which lets you access memory directly through pointers. In this example we use an UnsafeMutableBufferPointer instance in low level operations to eliminate uniqueness checks and bounds checks. I recommend reading [Unsafe Swift](https://pfandrade.me/blog/unsafe-swift/) by Paulo Andrande to get a better understanding of the unsafe side of Swift. 

2. The **OSStatus** return type.

   Almost every Apple C API function signals success or failure through their return value, which is of type OSStatus. Any status other than noErr (which is 0) signals an error. You can find more details [here](https://www.osstatus.com/search/results?platform=all&framework=all&search=)

## Why unsafe Swift?

First of all unsafe Swift lets you work with [pointers](https://codeburst.io/pointers-in-5-minutes-b94f9d1dfdb5) and interoprate with C libraries.

In addition, unsafe Swift can help you gain a performance boost by sacrificing memory safety. The code you write in the AVAudioSourceNode’s block *must be realtime compliant*. Your callback is called in a real-time thread with a hard deadline. @44,1khz sampling rate with a buffer size of 512 samples gives you ~11ms to complete processing in your callback. If that's not the case, you get silence. That time limit prohibits: 

1. Memory Allocations
2. Using Locks
3. Network Requests or any kind of I/O
4. Memory boundary checks/uniqueness checks
5. Checking your Twitter

Check out [this guide](https://github.com/apple/swift/blob/master/docs/OptimizationTips.rst) on writing high-performance Swift code.

## Conclusion

The only reason for ProcessAudio to exist as a library, would be to be used in older iOS and macOS versions. However, I think I can delete the repo without destroying the world as we know it. I really enjoyed the process and picked up a few lessons along the way.

AVFoundation really suprised me. It provides a clear, powerful API that can be used to generate audio and I'm looking forward making some stuff with it. I'm wondering how it compares to the Audio Unit impementation performance-wise, or if there's no difference at all because a core audio implementation is hiding under the hood of the two new AVAudioNodes.

I guess the question now (and pretty much always in real time systems) is: *how far can we go without writing C*?

Feel free to [contact me](mailto:orjpap@gmail.com) or tweet to me on [Twitter](https://twitter.com/OrestisPapadop8) if you have any additional tips or feedback.

Thanks!

[^2]: A *sample* is single numerical value for a single audio channel in an audio stream.. A *frame* is a collection of time-coincident samples. For instance, a linear PCM stereo sound file has two samples per frame, one for the left channel and one for the right channel.)