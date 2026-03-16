//
//  RouteStatsView.swift
//  LegalActivities
//
//  Per-route stats screen showing all racers (user + friends) and their times.
//

import SwiftUI

struct RouteStatsView: View {
    let route: SavedRoute
    @EnvironmentObject var appState: AppState

    // Build a unified list of all racers for this route, sorted by best time
    private var racerEntries: [RacerEntry] {
        var entries: [RacerEntry] = []

        // Your own results
        let myResults = route.raceHistory
        if !myResults.isEmpty {
            let best = myResults.min(by: { $0.totalDuration < $1.totalDuration })!
            let avgSpd = myResults.map { $0.averageSpeed }.reduce(0, +) / Double(myResults.count)
            let last = myResults.max(by: { $0.date < $1.date })!.date
            entries.append(RacerEntry(
                name: appState.userProfile.name,
                avatarSystemName: appState.userProfile.avatarSystemName,
                bestTime: best.totalDuration,
                totalRaces: myResults.count,
                avgSpeed: avgSpd,
                lastRaced: last,
                isYou: true
            ))
        }

        // Friends who raced this route
        for friend in appState.friends {
            let friendRaces = friend.recentRaces.filter { $0.routeId == route.id }
            guard !friendRaces.isEmpty else { continue }
            let best = friendRaces.min(by: { $0.totalDuration < $1.totalDuration })!
            let avgSpd = friendRaces.map { $0.averageSpeed }.reduce(0, +) / Double(friendRaces.count)
            let last = friendRaces.max(by: { $0.date < $1.date })!.date
            entries.append(RacerEntry(
                name: friend.name,
                avatarSystemName: friend.avatarSystemName,
                bestTime: best.totalDuration,
                totalRaces: friendRaces.count,
                avgSpeed: avgSpd,
                lastRaced: last,
                isYou: false
            ))
        }

        return entries.sorted { $0.bestTime < $1.bestTime }
    }

    private var units: UnitPreference { appState.userProfile.unitPreference }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                routeHeaderCard
                overallStatsCard
                leaderboardSection
            }
            .padding(.vertical)
        }
        .navigationTitle(route.name)
        .navigationBarTitleDisplayMode(.large)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Route Header Card
    private var routeHeaderCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                difficultyBadge
                ForEach(route.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.tertiarySystemBackground))
                        .clipShape(Capsule())
                }
                Spacer()
            }

            Divider()

            HStack(spacing: 0) {
                infoItem(value: "\(route.raceHistory.count)", label: "Your Races")
                Divider().frame(height: 40)
                if let pb = appState.personalBest(for: route) {
                    infoItem(value: formatShortDuration(pb), label: "Your PB")
                } else {
                    infoItem(value: "—", label: "Your PB")
                }
                Divider().frame(height: 40)
                infoItem(value: "\(racerEntries.count)", label: "Total Racers")
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }

    private var difficultyBadge: some View {
        Text(route.difficulty.rawValue)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(difficultyColor(route.difficulty).opacity(0.15))
            .foregroundStyle(difficultyColor(route.difficulty))
            .clipShape(Capsule())
    }

    // MARK: - Overall Stats Card
    @ViewBuilder
    private var overallStatsCard: some View {
        let allTimes = racerEntries.map { $0.bestTime }
        if !allTimes.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Label("Overall Stats", systemImage: "chart.bar.xaxis")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Divider()

                HStack(spacing: 0) {
                    infoItem(value: formatShortDuration(allTimes.min()!), label: "Course Record")
                    Divider().frame(height: 40)
                    infoItem(
                        value: formatShortDuration(allTimes.reduce(0, +) / Double(allTimes.count)),
                        label: "Avg Best Time"
                    )
                    Divider().frame(height: 40)
                    infoItem(
                        value: "\(racerEntries.map { $0.totalRaces }.reduce(0, +))",
                        label: "Total Races"
                    )
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
            .padding(.horizontal)
        }
    }

    // MARK: - Leaderboard Section
    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Leaderboard")
                .font(.headline)
                .padding(.horizontal)

            if racerEntries.isEmpty {
                emptyLeaderboard
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(racerEntries.enumerated()), id: \.offset) { index, entry in
                        racerRow(rank: index + 1, entry: entry)
                        if index < racerEntries.count - 1 {
                            Divider().padding(.horizontal)
                        }
                    }
                }
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                .padding(.horizontal)
            }
        }
    }

    private var emptyLeaderboard: some View {
        VStack(spacing: 10) {
            Image(systemName: "flag.checkered.2.crossed")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No races yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Race this route or add friends to populate the leaderboard.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
    }

    // MARK: - Racer Row
    private func racerRow(rank: Int, entry: RacerEntry) -> some View {
        HStack(spacing: 12) {
            // Rank badge
            ZStack {
                Circle()
                    .fill(rankColor(rank))
                    .frame(width: 28, height: 28)
                Text("\(rank)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(rank <= 3 ? .white : .primary)
            }

            Image(systemName: entry.avatarSystemName)
                .font(.title2)
                .foregroundStyle(entry.isYou ? .blue : .secondary)
                .frame(width: 34)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(entry.isYou ? appState.userProfile.name : entry.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(entry.isYou ? .blue : .primary)
                    if entry.isYou {
                        Text("You")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                Text("\(entry.totalRaces) race\(entry.totalRaces == 1 ? "" : "s") · \(units.formatSpeed(entry.avgSpeed)) avg")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(formatShortDuration(entry.bestTime))
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(rank == 1 ? Color(red: 0.8, green: 0.65, blue: 0.1) : .primary)
                Text("best")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(entry.isYou ? Color.blue.opacity(0.04) : Color.clear)
    }

    // MARK: - Helpers
    private func infoItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return Color(red: 0.85, green: 0.73, blue: 0.1)
        case 2: return Color(white: 0.65)
        case 3: return Color(red: 0.75, green: 0.45, blue: 0.2)
        default: return Color(.tertiarySystemFill)
        }
    }

    private func difficultyColor(_ d: Difficulty) -> Color {
        switch d {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
}

// MARK: - Data model for a racer entry
extension RouteStatsView {
    struct RacerEntry {
        let name: String
        let avatarSystemName: String
        let bestTime: TimeInterval
        let totalRaces: Int
        let avgSpeed: Double
        let lastRaced: Date
        let isYou: Bool
    }
}

#Preview {
    NavigationStack {
        RouteStatsView(route: SavedRoute(name: "Test Route", coordinates: []))
            .environmentObject(AppState())
    }
}
