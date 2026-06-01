import Testing
import Foundation
@testable import MorseLight

@Suite("KMeans1D")
struct KMeans1DTests {

    private let dotDash: [Double] = [0.08, 0.08, 0.08, 0.24, 0.24]

    // MARK: - Clustering correctness

    @Test("Separates dot and dash clusters around their means")
    func separatesClusters() throws {
        let result = try #require(KMeans1D().cluster(dotDash))
        #expect(abs(result.low - 0.08) < 0.001)
        #expect(abs(result.high - 0.24) < 0.001)
    }

    @Test("Single value collapses to one cluster with zero iterations")
    func singleValue() throws {
        let result = try #require(KMeans1D().cluster([0.1]))
        #expect(result.low == 0.1)
        #expect(result.high == 0.1)
        #expect(result.iterations == 0)
        #expect(result.converged)
    }

    @Test("Empty input returns nil")
    func emptyInput() {
        #expect(KMeans1D().cluster([]) == nil)
    }

    // MARK: - Convergence threshold (epsilon)

    @Test("Converges before the iteration cap on well-separated data")
    func convergesEarly() throws {
        let result = try #require(KMeans1D().cluster(dotDash))
        #expect(result.converged)
        #expect(result.iterations >= 1)
        #expect(result.iterations < KMeans1D().maxIterations)
    }

    @Test("Larger epsilon never needs more iterations than a tiny epsilon")
    func epsilonMonotonic() throws {
        let values: [Double] = [0.05, 0.06, 0.09, 0.25, 0.26, 0.30]
        let loose = try #require(KMeans1D(epsilon: 0.1).cluster(values))
        let tight = try #require(KMeans1D(epsilon: 1e-9).cluster(values))
        #expect(loose.iterations <= tight.iterations)
    }

    @Test("maxIterations caps the loop")
    func respectsIterationCap() throws {
        let result = try #require(KMeans1D(epsilon: 0, maxIterations: 1).cluster(dotDash))
        #expect(result.iterations <= 1)
    }

    // MARK: - Default threshold

    @Test("Default epsilon is 0.0005")
    func defaultEpsilon() {
        #expect(KMeans1D().epsilon == 0.0005)
    }
}
</content>
