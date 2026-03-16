
//
//  StartRacingView.swift
//  LegalActivities
//
//  Full-screen route selection pushed from HomeView's NavigationStack.
//

import SwiftUI

struct StartRacingView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    // One shared LocationManager for whichever route the user picks
    @StateObject private var locationManager = LocationManager()

    @State private var searchText = ""
    @State private var selectedDifficulty: Difficulty? = nil

    var body: some View {
        VStack(spacing: 0) {
            difficultyFilterBar

            if appState.savedRoutes.isEmpty {
                emptyView
            } else {
                List {
                    if !appState.recentRoutes.isEmpty {
                        Section("Recent Routes") {
                            ForEach(appState.recentRoutes) { route in
                                routeRow(route)
                            }
                        }
                    }

                    Section("All Routes") {
                        if filteredRoutes.isEmpty {
                            Text("No routes match your filter.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(filteredRoutes) { route in
                                routeRow(route)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Select a Route")
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.hidden, for: .tabBar)
        .searchable(text: $searchText, prompt: "Search routes")
        .onAppear { appState.loadRoutes() }
    }

    // MARK: - Route row (NavigationLink so the push stays inside HomeView's NavigationStack)
    @ViewBuilder
    private func routeRow(_ route: SavedRoute) -> some View {
        NavigationLink {
            RaceInProgressView(route: route, locationManager: locationManager)
                .onDisappear { appState.loadRoutes() }
        } label: {
            HStack(spacing: 14) {
                // Colour dot
                Circle()
                    .fill(difficultyColor(route.difficulty))
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 4) {
                    Text(route.name)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    HStack(spacing: 8) {
                        DifficultyBadge(difficulty: route.difficulty)

                        if let pb = appState.personalBest(for: route) {
                            Label(formatShortDuration(pb), systemImage: "trophy.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("No races yet")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if !route.tags.isEmpty {
                        Text(route.tags.joined(separator: " · "))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: - Difficulty filter chips
    private var difficultyFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: selectedDifficulty == nil) {
                    selectedDifficulty = nil
                }
                ForEach(Difficulty.allCases, id: \.self) { diff in
                    FilterChip(title: diff.rawValue, isSelected: selectedDifficulty == diff) {
                        selectedDifficulty = selectedDifficulty == diff ? nil : diff
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Empty state
    private var emptyView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "map.fill")
                .font(.system(size: 52))
                .foregroundStyle(.secondary)
            Text("No Routes Yet")
                .font(.title3)
                .fontWeight(.semibold)
            Text("Create a route first, then come back to race it.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    // MARK: - Helpers
    private var filteredRoutes: [SavedRoute] {
        var routes = appState.savedRoutes
        if !searchText.isEmpty {
            routes = routes.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        if let diff = selectedDifficulty {
            routes = routes.filter { $0.difficulty == diff }
        }
        return routes
    }

    private func difficultyColor(_ difficulty: Difficulty) -> Color {
        switch difficulty {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
}

// MARK: - Shared Components

struct DifficultyBadge: View {
    let difficulty: Difficulty

    var body: some View {
        Text(difficulty.rawValue)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(badgeColor.opacity(0.15))
            .foregroundStyle(badgeColor)
            .clipShape(Capsule())
    }

    private var badgeColor: Color {
        switch difficulty {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.secondarySystemBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

#Preview {
    NavigationStack {
        StartRacingView()
            .environmentObject(AppState())
    }
}
