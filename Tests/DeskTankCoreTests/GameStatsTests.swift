import Testing
@testable import DeskTankCore

@Test func recordingKillIncrementsTotalAndCurrentRunKills() {
    let stats = GameStats().recordingKill()

    #expect(stats.totalKills == 1)
    #expect(stats.currentRunKills == 1)
}

@Test func recordingWinIncrementsSuccessesAndKeepsCurrentRunKillsForRecap() {
    let stats = GameStats()
        .recordingKill()
        .recordingKill()
        .recordingWin()

    #expect(stats.successes == 1)
    #expect(stats.failures == 0)
    #expect(stats.totalKills == 2)
    #expect(stats.currentRunKills == 2)
}

@Test func recordingFailureIncrementsFailuresAndKeepsCurrentRunKillsForRecap() {
    let stats = GameStats()
        .recordingKill()
        .recordingFailure()

    #expect(stats.successes == 0)
    #expect(stats.failures == 1)
    #expect(stats.totalKills == 1)
    #expect(stats.currentRunKills == 1)
}

@Test func winRateHandlesEmptyAndPlayedGames() {
    #expect(GameStats().winRate == 0)

    let stats = GameStats(successes: 3, failures: 1)

    #expect(stats.winRate == 0.75)
}
