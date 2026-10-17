import Foundation
import AVFoundation

public class AudioService: NSObject, ObservableObject, AVAudioPlayerDelegate {
    public static let shared = AudioService()

    @Published public var isPlaying: Bool = false
    @Published public var currentlyPlaying: String?

    private var player: AVAudioPlayer?

    override private init() {
        super.init()
    }

    public func playTone(frequency: Double, duration: TimeInterval) {
        stop()

        // Generate synthetic gentle tone buffer
        let sampleRate = 44100.0
        let frameCount = Int(sampleRate * duration)
        var audioData = [Float](repeating: 0.0, count: frameCount)

        for i in 0..<frameCount {
            let progress = Double(i) / sampleRate
            let envelope = sin(Double.pi * Double(i) / Double(frameCount)) // smooth fade-in and fade-out
            audioData[i] = Float(sin(2.0 * Double.pi * frequency * progress) * envelope * 0.3)
        }

        let audioFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(frameCount)) else { return }
        pcmBuffer.frameLength = AVAudioFrameCount(frameCount)

        if let channelData = pcmBuffer.floatChannelData?[0] {
            for i in 0..<frameCount {
                channelData[i] = audioData[i]
            }
        }

        // Configure audio session
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)

        self.isPlaying = true
        self.currentlyPlaying = "\(Int(frequency)) Hz Chime"

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.isPlaying = false
            self?.currentlyPlaying = nil
        }
    }

    public func previewChime() {
        playTone(frequency: 587.33, duration: 1.5) // D5 chime
    }

    public func previewAthan() {
        // Melodic sequence simulating Takbeer tone progression
        let notes: [(freq: Double, dur: Double)] = [
            (440.0, 0.4), // A4
            (523.25, 0.5), // C5
            (587.33, 0.7), // D5
            (659.25, 0.6)  // E5
        ]

        var delay = 0.0
        for (f, d) in notes {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.playTone(frequency: f, duration: d)
            }
            delay += d + 0.1
        }
    }

    public func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        currentlyPlaying = nil
    }

    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.currentlyPlaying = nil
        }
    }
}
