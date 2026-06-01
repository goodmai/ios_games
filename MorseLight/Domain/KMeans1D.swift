import Foundation

/// One-dimensional two-means (k=2) clustering with a configurable convergence
/// threshold. Splits values into a `low` and `high` centroid — used by
/// `MorseSegmentDecoder` to separate dot- and dash-length on-spans.
///
/// The loop stops as soon as the larger centroid shift falls below `epsilon`
/// (Δμ < ε), rather than always running a fixed number of iterations, so typical
/// well-separated inputs converge in 2–3 passes. `maxIterations` is a safety cap.
struct KMeans1D: Sendable {

    var epsilon: Double = 0.0005
    var maxIterations: Int = 50

    struct Clusters: Equatable, Sendable {
        let low: Double
        let high: Double
        let iterations: Int
        let converged: Bool
    }

    func cluster(_ values: [Double]) -> Clusters? {
        let sorted = values.sorted()
        guard let lo = sorted.first, let hi = sorted.last else { return nil }
        guard sorted.count > 1 else {
            return Clusters(low: lo, high: lo, iterations: 0, converged: true)
        }

        var c1 = lo
        var c2 = hi
        var iterations = 0
        var converged = false

        while iterations < maxIterations {
            iterations += 1
            let mid = (c1 + c2) / 2.0
            let dots = sorted.filter { $0 <= mid }
            let dashes = sorted.filter { $0 > mid }
            if dots.isEmpty || dashes.isEmpty { converged = true; break }

            let newC1 = dots.reduce(0, +) / Double(dots.count)
            let newC2 = dashes.reduce(0, +) / Double(dashes.count)
            let delta = max(abs(newC1 - c1), abs(newC2 - c2))
            c1 = newC1
            c2 = newC2
            if delta < epsilon { converged = true; break }
        }

        return Clusters(low: c1, high: c2, iterations: iterations, converged: converged)
    }
}
</content>
