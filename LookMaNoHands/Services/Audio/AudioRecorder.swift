import AVFoundation

// Thread-safe buffer for audio tap callback (runs on audio thread)
private final class SampleBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var samples: [Float] = []

    func append(_ newSamples: [Float]) {
        lock.lock()
        samples.append(contentsOf: newSamples)
        lock.unlock()
    }

    func drain() -> [Float] {
        lock.lock()
        let result = samples
        samples.removeAll()
        lock.unlock()
        return result
    }
}

final class AudioRecorder: @unchecked Sendable {
    private var audioEngine: AVAudioEngine?
    private var sampleBuffer = SampleBuffer()
    private let targetSampleRate: Double = 16000
    private var nativeSampleRate: Double = 48000

    func startRecording() {
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let nativeFormat = inputNode.outputFormat(forBus: 0)
        nativeSampleRate = nativeFormat.sampleRate

        // Capture only the Sendable buffer — no self reference in the tap
        let buffer = sampleBuffer
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: nativeFormat) { pcmBuffer, _ in
            guard let channelData = pcmBuffer.floatChannelData?[0] else { return }
            let count = Int(pcmBuffer.frameLength)
            guard count > 0 else { return }
            buffer.append(Array(UnsafeBufferPointer(start: channelData, count: count)))
        }

        do {
            engine.prepare()
            try engine.start()
            self.audioEngine = engine
        } catch {
            NSLog("LMNH: AudioRecorder failed to start: \(error)")
        }
    }

    func stopRecording() -> [Float] {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil

        let samples = sampleBuffer.drain()

        // Downsample from native rate to 16kHz for WhisperKit
        guard nativeSampleRate != targetSampleRate, !samples.isEmpty else {
            return samples
        }
        let ratio = nativeSampleRate / targetSampleRate
        let outputLength = Int(Double(samples.count) / ratio)
        return (0..<outputLength).map { i in
            samples[min(Int(Double(i) * ratio), samples.count - 1)]
        }
    }

    var isRecording: Bool {
        audioEngine?.isRunning ?? false
    }
}
