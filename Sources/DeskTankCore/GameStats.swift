import Foundation

public struct GameStats: Equatable, Sendable {
    public let totalKills: Int
    public let successes: Int
    public let failures: Int
    public let currentRunKills: Int

    public init(
        totalKills: Int = 0,
        successes: Int = 0,
        failures: Int = 0,
        currentRunKills: Int = 0
    ) {
        self.totalKills = max(0, totalKills)
        self.successes = max(0, successes)
        self.failures = max(0, failures)
        self.currentRunKills = max(0, currentRunKills)
    }

    public var gamesPlayed: Int {
        successes + failures
    }

    public var winRate: Double {
        guard gamesPlayed > 0 else {
            return 0
        }

        return Double(successes) / Double(gamesPlayed)
    }

    public func recordingKill() -> GameStats {
        GameStats(
            totalKills: totalKills + 1,
            successes: successes,
            failures: failures,
            currentRunKills: currentRunKills + 1
        )
    }

    public func recordingWin() -> GameStats {
        GameStats(
            totalKills: totalKills,
            successes: successes + 1,
            failures: failures,
            currentRunKills: currentRunKills
        )
    }

    public func recordingFailure() -> GameStats {
        GameStats(
            totalKills: totalKills,
            successes: successes,
            failures: failures + 1,
            currentRunKills: currentRunKills
        )
    }

    public func resettingCurrentRun() -> GameStats {
        GameStats(totalKills: totalKills, successes: successes, failures: failures)
    }
}
