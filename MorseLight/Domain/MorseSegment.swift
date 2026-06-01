import Foundation

/// A contiguous on (signal) or off (gap) span with a measured duration.
///
/// Produced by any front-end that turns a physical channel into a Morse timeline
/// — audio energy (`MorseAudioDecoder`) or camera luminance (`LightSignalDecoder`)
/// — and consumed by `MorseSegmentDecoder`.
struct MorseSegment: Equatable, Sendable {
    let isOn: Bool
    let duration: TimeInterval
}
</content>
