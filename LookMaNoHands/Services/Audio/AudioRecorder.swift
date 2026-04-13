import AVFoundation

@MainActor
final class AudioRecorder {
    private var audioEngine: AVAudioEngine?
    private var audioSamples: [Float] = []
    private let sampleRate: Double = 16000

    func startRecording() {
        audioSamples.removeAll()

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let recordingFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: false
        )!

        // Install a tap to capture audio buffers
        let bufferSize: AVAudioFrameCount = 1024
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: recordingFormat) { [weak self] buffer, _ in
            guard let self else { return }
            let channelData = buffer.floatChannelData?[0]
            let frameLength = Int(buffer.frameLength)
            if let channelData, frameLength > 0 {
                let samples = Array(UnsafeBufferPointer(start: channelData, count: frameLength))
                Task { @MainActor in
                    self.audioSamples.append(contentsOf: samples)
                }
            }
        }

        do {
            engine.prepare()
            try engine.start()
            self.audioEngine = engine
        } catch {
            print("AudioRecorder: Failed to start engine: \(error)")
        }
    }

    func stopRecording() -> [Float] {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        let samples = audioSamples
        audioSamples.removeAll()
        return samples
    }

    var isRecording: Bool {
        audioEngine?.isRunning ?? false
    }
}
