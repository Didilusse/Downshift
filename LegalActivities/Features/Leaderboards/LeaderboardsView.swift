
//
//  LeaderboardsView.swift
//  LegalActivities
//
//  Per-route and global leaderboards mixing user and friend times.
//

import SwiftUI

struct LeaderboardsView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: LeaderboardTab = .perRoute
    @State private var selectedRouteId: UUID? = nil

    enum LeaderboardTab: String, CaseIterable {
        case perRoute = "Per Route"
        case global = "Global"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Leaderboard", selection: $selectedTab) {
                    ForEach(LeaderboardTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                if selectedTab == .perRoute {
                    perRouteLeaderboard
                } else {
                    globalLeaderboard
                }
            }
            .navigationTitle("Leaderboards")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                if selectedRouteId == nil, let first = appState.savedRoutes.first {
                    selectedRouteId = first.id
                }
            }
        }
    }

    // MARK: - Per Route Leaderboard
    private var perRouteLeaderboard: some View {
        VStack(spacing: 0) {
            if appState.savedRoutes.isEmpty {
                emptyView(message: "Create a route to see per-route leaderboards.")
            } else {
                // Route picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(appState.savedRoutes) { route in
                            FilterChip(
                                title: route.name,
                                isSelected: selectedRouteId == route.id
                            ) {
                                selectedRouteId = route.id
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color(.systemBackground))

                if let routeId = selectedRouteId,
                   let route = appState.savedRoutes.first(where: { $0.id == routeId }) {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            let entries = buildPerRouteEntries(route: route)
                            if entries.isEmpty {
                                emptyView(message: "No times recorded for this route yet.")
                            } else {
                                ForEach(Array(entries.enumerated()), id: \.element.id) { idx, entry in
                                    LeaderboardRow(rank: idx + 1, entry: entry, isUser: entry.name == appState.userProfile.name)
                                    Divider().padding(.horizontal)
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
        }
    }

    // MARK: - Global Leaderboard
    private var globalLeaderboard: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                let entries = buildGlobalEntries()
                if entries.isEmpty {
                    emptyView(message: "Race on routes to appear in global rankings.")
                } else {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { idx, entry in
                        LeaderboardRow(rank: idx + 1, entry: entry, isUser: entry.name == appState.userProfile.name)
                        Divider().padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: - Data Building
    private func buildPerRouteEntries(route: SavedRoute) -> [LeaderboardEntry] {
        var entries: [LeaderboardEntry] = []

        // User's best for this route
        if let userBest = appState.personalBest(for: route) {
            entries.append(LeaderboardEntry(
                id: UUID(),
                name: appState.userProfile.name,
                time: userBest,
                isUser: true
            ))
        }

        // Friends' bests for this route
        for friend in appState.friends {
            if let friendBest = friend.personalBests[route.id.uuidString] {
                entries.append(LeaderboardEntry(
                    id: UUID(),
                    name: friend.name,
                    time: friendBest,
                    isUser: false
                ))
            }
        }

        return entries.sorted { $0.time < $1.time }
    }

    private func buildGlobalEntries() -> [LeaderboardEntry] {
        var totalTimes: [String: TimeInterval] = [:]

        // User's overall best average
        let userBestAvg = appState.userProfile.personalBests.values.min()
        if let best = userBestAvg {
            totalTimes[appState.userProfile.name] = best
        }

        // Friends' overall bests
        for friend in appState.friends {
            if let bestTime = friend.personalBests.values.min() {
                let existing = totalTimes[friend.name]
                if existing == nil || bestTime < existing! {
                    totalTimes[friend.name] = bestTime
                }
            }
        }

        return totalTimes.map { name, time in
            LeaderboardEntry(id: UUID(), name: name, time: time, isUser: name == appState.userProfile.name)
        }
        .sorted { $0.time < $1.time }
        .prefix(20)
        .map { $0 }
    }

    private func emptyView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "list.number")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
}

// MARK: - Supporting Types & Views
struct LeaderboardEntry: Identifiable {
    let id: UUID
    let name: String
    let time: TimeInterval
    let isUser: Bool
}

struct LeaderboardRow: View {
    let rank: Int
    let entry: LeaderboardEntry
    let isUser: Bool

    var body: some View {
        HStack(spacing: 16) {
            rankBadge
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.subheadline)
                    .fontWeight(isUser ? .bold : .regular)
                    .foregroundStyle(isUser ? .blue : .primary)
                if isUser {
                    Text("You")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
            }
            Spacer()
            Text(formatShortDuration(entry.time))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(rank <= 3 ? rankColor : .primary)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(isUser ? Color.blue.opacity(0.05) : Color.clear)
    }

    private var rankBadge: some View {
        ZStack {
            Circle()
                .fill(rank <= 3 ? rankColor.opacity(0.15) : Color(.secondarySystemBackground))
                .frame(width: 36, height: 36)
            if rank == 1 {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.yellow)
                    .font(.subheadline)
            } else if rank == 2 {
                Text("2nd")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color(red: 0.75, green: 0.75, blue: 0.75))
            } else if rank == 3 {
                Text("3rd")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color(red: 0.8, green: 0.5, blue: 0.2))
            } else {
                Text("\(rank)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.75)
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return .secondary
        }
    }
}

#Preview {
    LeaderboardsView()
        .environmentObject(AppState())
}
