import DeskTankCore
import Foundation

@MainActor
final class GameStatsStore {
    private enum Key {
        static let totalKills = "DeskTank.stats.totalKills"
        static let successes = "DeskTank.stats.successes"
        static let failures = "DeskTank.stats.failures"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> GameStats {
        GameStats(
            totalKills: defaults.integer(forKey: Key.totalKills),
            successes: defaults.integer(forKey: Key.successes),
            failures: defaults.integer(forKey: Key.failures)
        )
    }

    func save(_ stats: GameStats) {
        defaults.set(stats.totalKills, forKey: Key.totalKills)
        defaults.set(stats.successes, forKey: Key.successes)
        defaults.set(stats.failures, forKey: Key.failures)
    }
}
