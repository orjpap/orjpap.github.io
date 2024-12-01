---
layout: post
title: "AVAudioEffectNode: Configurable Input-Output"
date: 2024-12-01 12:03:36 +0530
categories: Swift Low-level Audio AVFoundation
doctest: false

---
In my [previous post](https://orjpap.github.io/swift/low-level/audio/avfoundation/2024/09/19/avAudioEffectNode.html), I have come up with a simplistic implementation of an AVAudioEffectNode with a custom render block. At that time, I assumed a fixed setup with two channels and a sample rate of 44,100 Hz. However, a reader recently reached out, asking how to adapt this for an audio effect that converts stereo input to mono output. This inspired me to modify the `AVAudioEffectNode` class for greater flexibility.

## Key Changes

To accommodate different input and output configurations, I made the following updates:

1. **Dynamic Bus Arrays**: Instead of using fixed input and output busses, I implemented lazy-loaded bus arrays. This allows for more dynamic configuration:

```swift
private lazy var inputBusArray: AUAudioUnitBusArray = {
	let defaultAudioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
	let inputBus = try! AUAudioUnitBus(format: defaultAudioFormat)
	return AUAudioUnitBusArray(audioUnit: self, busType: .input, busses: [inputBus])
}()
private lazy var outputBusArray: AUAudioUnitBusArray = {
	let defaultAudioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
	let outputBus = try! AUAudioUnitBus(format: defaultAudioFormat)
	return AUAudioUnitBusArray(audioUnit: self, busType: .output, busses: [outputBus])
}()
```

 2. **Overriding Bus Properties** needed for AUV3 implementation
```swift
public override var inputBusses: AUAudioUnitBusArray {
	return inputBusArray
}

public override var outputBusses: AUAudioUnitBusArray {
	return outputBusArray
}
```

For the full implementation, check out [this gist](https://gist.github.com/orjpap/85a3d1029ff068516a4063d04ea5b8d8).

## Usage

You can now easily change the input and output formats using:

- `avAudioEffectNode.auAudioUnit.inputBusses.replaceBusses`
- `avAudioEffectNode.auAudioUnit.outputBusses.replaceBusses`

Here's an example using the symclip node from my [previous example](https://github.com/orjpap/AVAudioEffectNode-Example):

```swift
print(symClipNode. inputFormat (forBus: 0))
// prints: <AVAudioFormat 0x600002a85180: 2 ch, 44100 Hz, Float32, deinterleaved>

let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 1)!
let inputBuss = try AUAudioUnitBus(format: audioFormat)

symClipNode.auAudioUnit.inputBusses.replaceBusses([inputBuss])

print(symClipNode.inputFormat (forBus: 0))
// prints: <AVAudioFormat 0x600002a84d0: 1 ch, 48000 Hz, Float32, deinterleaved>
```

## Bonus: BYOB (Bring your own buffers) input pulling

When the input and output have different buffer counts (2 in and 1 out in our reader's case) you have to BYOB.
 
Here's a sane (and not very Swifty) way of doing this:

```swift
let sumNode = AVAudioEffectNode(renderBlock: { actionFlags, timestamp, frameCount, outputBusNumber,
	outputData, renderEvent, pullInputBlock -> AUAudioUnitStatus in

	let bufferSizeBytes = MemoryLayout<Float>.size * Int (frameCount)
	var inputBufferlist = AudioBufferList.allocate(maximumBuffers: 2)

	inputBufferList[0] = AudioBuffer (mNumberChannels: 1,
									  mDataByteSize: UInt32(bufferSizeBytes),
									  mData: malloc(bufferSizeBytes))
	inputBufferList[1] = AudioBuffer (mNumberChannels: 1,
									  mDataByteSize: UInt32(bufferSizeBytes),
									  mData: malloc(bufferSizeBytes))
	// Pull the audio from the input
	let inputStatus = pullInputBlock?(actionFlags, timestamp, frameCount, 0, inputBufferList.unsafeMutablePointer)
	
	if inputStatus != noErr {
		return inputStatus ?? KAudioUnitErr_FailedInitialization
	}

	let ablPointer = UnsafeMutableAudioBufferListPointer(outputData)
	for buffer in ablPointer {
		// do your summing here
		let input = UnsafePointer<Float>(inputBufferList[0].mData!.assumingMemoryBound(to: Float.self))
		...
	}
｝
```

Since you allocated you are now also responsible for freeing when you are done with the block:

```swift
for buffer in inputBufferList {
	free(buffer.mData)
}
free(inputBufferList.unsafeMutablePointer)
```

Unfortunately some of those C-APIs don't translate well to Swift and can be hard to use even when you know what you are doing.

Feel free to [contact me](mailto:orjpap@gmail.com) for tips, feedback, opinions or sending me your cool audio effects.

Thank you for reading!