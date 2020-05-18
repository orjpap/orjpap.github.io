---

layout: post
title:  "AVAudioSourceNode, AVAudioSinkNode: how I deleted a repo in less than 48hours"
date:   2020-05-04 21:03:36 +0530
categories: Swift Real-time Audio AVFoundation
doctest: true

---

Two days ago, I set out to create a simple Swift library for real-time audio processing. I was aiming to provide a boilerplate-free way of **processing input** from an audio device/file, and **generating output** to a device/file, sample by sample (or frame by frame). 

Last time I checked there was AudioKit, which is great and you should check it out, but a big dependency to add to a project were you only need to process some audio as well as Core Audio. Apple's lowest level of abstraction audio framework, **Core Audio** (initially released in 2003), which on the front page of its [documentation](https://developer.apple.com/documentation/coreaudio) clearly states: "Use the Core Audio framework to interact with device’s audio hardware."

An audio unit is a software object that performs some sort of work on a stream of audio, frame by frame. Being so close to the hardware comes with a lot of responsibilities, that's why Audio Units take time and code to set up and make sure that everything is OK. 

The hello world of audio generators is a sinewave. But let's make some noise instead. In order to do this with Core Audio we need to:

1. Find the default output audio component
2. Create a new instance of an audio unit and attach it to it
3. Set the renderBlock property of the audio unit to our noise callback
4. Start the audio unit
5. Sleep on the current thread so that we can hear the audio being generated on the real-time thread.
6. Clean up the audio unit

I made a wrapper that provided the following API:

```swift
let device = ProcessAudio.defaultOutput
// Make some noise
device.connect { _, buffer, bufferSize in
    for frameNumber in 0..<Int(bufferSize) {
        data[frameNumber] = Float32.random(in: 0..<1)
    }
})
device.start()
sleep(5)
device.stop()
```



Turns out AVAudioSourceNode and AVAudioSinkNode [introduced](https://developer.apple.com/videos/play/wwdc2019/510) in WWDC2019, can be used in the exact same way.

## Conclusion

That's all you need in order to enable testing for Swift codeblocks in your Jekyll site!

Keep your eyes peeled for further updates to the very promising [Doctest](https://github.com/SwiftDocOrg/DocTest?utm_campaign=iOS%2BDev%2BWeekly&utm_medium=web&utm_source=iOS%2BDev%2BWeekly%2BIssue%2B454) since it's still on its early days.

Feel free to [contact me](mailto:orjpap@gmail.com) or tweet to me on [Twitter](https://twitter.com/OrestisPapadop8) if you have any additional tips or feedback.

Thanks!

