import Foundation

enum SoundEffect: String, Sendable {
    case jump
    case collect
    case hit
    case gameOver
    case victory
    case buttonTap
}

enum BackgroundMusic: String, Sendable {
    case menu = "menu_theme"
    case gameplay = "gameplay_theme"
    case boss = "boss_theme"
}

protocol AudioManaging: Sendable {
    func play(_ effect: SoundEffect) async
    func play(_ music: BackgroundMusic) async
    func stop() async
    func setVolume(_ volume: Float) async
    var isMuted: Bool { get async }
    func toggleMute() async
}

actor AudioManager: AudioManaging {
    private(set) var isMuted: Bool = false
    private var volume: Float = 1.0
    private var currentMusic: BackgroundMusic?

    func play(_ effect: SoundEffect) {
        guard !isMuted else { return }
        // Hook into AVFoundation or SpriteKit audio in the real implementation
    }

    func play(_ music: BackgroundMusic) {
        guard !isMuted else { return }
        self.setCurrentMusic(music)
    }

    func stop() {
        currentMusic = nil
    }

    func setVolume(_ volume: Float) {
        self.volume = max(0, min(1, volume))
    }

    func toggleMute() {
        isMuted.toggle()
    }

    private func setCurrentMusic(_ music: BackgroundMusic) {
        currentMusic = music
    }
}
