---
layout: post
title:  "AVAudioEffectNode: painless low level audio effects written in Swift"
date:   2022-05-25 21:03:36 +0530
categories: Swift Low-level Audio AVFoundation
doctest: false

---

In a [previous post](https://orjpap.github.io/swift/real-time/audio/avfoundation/2020/06/19/avaudiosourcenode.html), I covered two AVFoundation nodes that can generate sound or tap into the output of an existing node. If you experiment with them, you'll quickly realize:

1. **AVAudioSourceNode** has 0 inputs and 1 output.
2. **AVAudioSinkNode** has 1 input and 0 outputs.

This means we can't use these nodes to create audio effects directly, since an audio effect needs (at least) 1 input and 1 output.

For creating audio effects, we typically use Audio Units. The AUv3 standard is built on the App Extensions model, meaning your plug-in is an extension contained within an app. Apple provides examples on how to do this, but they are often full of boilerplate and can be challenging to the uninitiated—where's the fun in that, right?

And by fun, I mean fun like [Novocaine](https://github.com/alexbw/novocaine), an Objective-C library that "takes the pain out of high-performance audio on iOS and macOS." Following a similar approach, I'll guide you through the simplest way I’ve found to create a user-friendly API for building audio effects in Swift using **AVFoundation**.

## AudioUnit, AUAudioUnit, AVAudioUnit (Send Help!)

Now, let's dive into creating our own `AVAudioEffectNode`. The API should look something like this:

```swift
let myEffectNode = AVAudioEffectNode(renderBlock: { -- our render block --})
```

Since we’re using **AVFoundation**, we need to create an `AVAudioNode` that can attach to the engine. This is where `AVAudioUnit` comes in, acting as a wrapper for Audio Units within **AVFoundation**. There are specialized subclasses like `AVAudioUnitEffect`, which we’ll be using later.

If you're new to this, a good starting point is the `AUComponent.h` header file in Xcode (just Cmd+Click on `AudioUnit` to access it). Here’s a quick summary:

1. Audio Units contain render blocks that handle the audio processing.

2. You create your own Audio Unit by subclassing `AUAudioUnit` (since `AudioUnit` is just a typealias).

3. An `AudioComponentDescription` is used to describe the unit, which is later instantiated.

### AudioComponentDescription

Here's how to define an **AudioComponentDescription** for our custom effect:

```swift
import AVFoundation

extension AudioComponentDescription {
    static let AVAudioEffectNodeAudioUnit = AudioComponentDescription(
        componentType: kAudioUnitType_Effect,
        componentSubType: fourCharCodeFrom("avae"), // provide your own
        componentManufacturer: fourCharCodeFrom("orjp"), // provide your own
        componentFlags: 0,
        componentFlagsMask: 0
    )
}

func fourCharCodeFrom(_ string : String) -> FourCharCode {
    assert(string.count == 4, "String length must be 4")
    var result : FourCharCode = 0
    for char in string.utf16 {
        result = (result << 8) + FourCharCode(char)
    }
    return result
}
```

In this example, we specify the `componentType` as `kAudioUnitType_Effect` because we’re building an effect. You also need to define custom four-character codes for `SubType` and `Manufacturer`. I’ve added a helper function to simplify that.

> **Note:** If you're debugging a macOS app and encounter the error **Code=-3000 "invalidComponentID"**, set the `componentFlags` to `AudioComponentFlags.sandboxSafe.rawValue`.

### Custom AUAudioUnit

Next, we subclass `AUAudioUnit` to create `AVAudioEffectNodeAudioUnit`, this is our custom Audio Unit:

1. We’ll need to override the `internalRenderBlock` to pass in our custom render logic.
2. We’ll also need to define one input and one output bus by overriding `inputBusses` and `outputBusses`.

```swift 
class AVAudioEffectNodeAudioUnit: AUAudioUnit {
    let inputBus: AUAudioUnitBus
    let outputBus: AUAudioUnitBus

    var _internalRenderBlock: AUInternalRenderBlock

    public override init(
        componentDescription: AudioComponentDescription,
        options: AudioComponentInstantiationOptions = []
    ) throws {
        let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!

        inputBus = try AUAudioUnitBus(format: audioFormat)
        outputBus = try AUAudioUnitBus(format: audioFormat)

        _internalRenderBlock = { _, _, _, _, _, _, _ in
            return kAudioUnitErr_Uninitialized
        }

        try super.init(componentDescription: componentDescription, options: options)
    }

    public override var inputBusses: AUAudioUnitBusArray {
        return AUAudioUnitBusArray(audioUnit: self, busType: .input, busses: [inputBus])
    }


    public override var outputBusses: AUAudioUnitBusArray {
        return AUAudioUnitBusArray(audioUnit: self, busType: .output, busses: [outputBus])
    }

    public override var internalRenderBlock: AUInternalRenderBlock {
        return _internalRenderBlock
    }
}

```

### Time for the glue. 

Now that we’ve created the core, let’s glue everything together by creating an `AVAudioEffectNode` class. This will inherit from `AVAudioUnitEffect`, and we’ll write a convenience initializer that allows us to pass in a render block—much like the `AVAudioSourceNode` API.

```swift
class AVAudioEffectNode: AVAudioUnitEffect {
    convenience init(renderBlock: @escaping AUInternalRenderBlock) {
        AUAudioUnit.registerSubclass(AVAudioEffectNodeAudioUnit.self,
                                     as: .AVAudioEffectNodeAudioUnit,
                                     name: "AVAudioEffectNode",
                                     version: 0)

        self.init(audioComponentDescription: .AVAudioEffectNodeAudioUnit)

        let audioEffectAudioUnit = self.auAudioUnit as! AVAudioEffectNodeAudioUnit
        audioEffectAudioUnit._internalRenderBlock = renderBlock
	 }
}
```

1. First, we register our custom `AUAudioUnit` using the **AudioComponentDescription** we defined earlier.
2. Next, we initialize the `AVAudioUnitEffect` using its inherited initializer.
3. Finally, we retrieve the `auAudioUnit`, cast it to our custom subclass, and pass the render block.

## Example: Symmetrical Clipping Effect

Here’s an example of how to implement a **symmetrical clipping** effect using `AVAudioEffectNode`. Symmetrical clipping is commonly used in overdrive simulations to clip both positive and negative waveform peaks evenly.

```swift
import AVFoundation

let symClipThreshold: Float = 1.0/3.0 // higher denominator > more clipping

let symClipNode = AVAudioEffectNode(renderBlock: { actionFlags, timestamp, frameCount, outputBusNumber, outputData, renderEvent, pullInputBlock -> AUAudioUnitStatus in

    // Pull the audio from the input
    let inputStatus = pullInputBlock?(actionFlags, timestamp, frameCount, 0, outputData)

    if inputStatus != noErr {
        return inputStatus ?? kAudioUnitErr_FailedInitialization
    }

    let ablPointer = UnsafeMutableAudioBufferListPointer(outputData)
    for buffer in ablPointer {
        let input = UnsafePointer<Float>(buffer.mData!.assumingMemoryBound(to: Float.self))
        let outputBuffer = UnsafeMutablePointer<Float>(buffer.mData!.assumingMemoryBound(to: Float.self))
        let processed = symClip(input: input, count: Int(frameCount))
        for i in 0..<Int(frameCount) {
            outputBuffer[i] = processed[i]
        }
    }

    return noErr
})

// "Overdrive" simlation with symmetrical clipping from DAFX (2011) translated to Swift
// Author: Dutilleux, ZΓΆlzer
// Symmetrical clipping clips both positive and negative amplitude peaks of a waveform evenly
func symClip(input: UnsafePointer<Float>, count: Int) -> [Float] {
    var output = [Float](repeating: 0.0, count: count)

    for i in 0..<count {
        let x = input[i]
        if abs(x) < symClipThreshold {
            output[i] = 2.0 * x
        } else if abs(x) >= symClipThreshold && abs(x) <= 2.0 * symClipThreshold {
            if x > 0 {
                output[i] = (3.0 - pow((2.0 - x * 3.0), 2.0)) / 3.0
            } else {
                output[i] = -(3.0 - pow((2.0 - abs(x) * 3.0), 2.0)) / 3.0
            }
        } else if abs(x) > 2.0 * symClipThreshold {
            if x > 0 {
                output[i] = 1.0
            } else {
                output[i] = -1.0
            }
        }
    }

    return output
}
```

### Putting the Nodes Together

You can now connect any kind of `AVAudioEngineNode` to your shiny new audio effect:

```swift
let engine = AVAudioEngine()

engine.attach(sineWaveNode)
engine.attach(symClipNode)

engine.connect(sineWaveNode, to: symClipNode, format: nil)
engine.connect(symClipNode, to: engine.mainMixerNode, format: nil)

engine.mainMixerNode.volume = 0.4

try! engine.start()
CFRunLoopRun()
engine.stop()

```

## Coda

All in all, combining a source node, sink node, and effect node creates a robust and flexible API for low-level audio processing and generation with AVFoundation. I'm excited to see where AVFoundation is headed and hopeful that future updates will bring even more user-friendly Swift APIs for audio development.

You can find the [full example](https://github.com/orjpap/AVAudioEffectNode-Example) as an Xcode project on my github.

Feel free to [contact me](mailto:orjpap@gmail.com) for tips, feedback, opinions or sending me your cool audio effects.

Thank you for reading!