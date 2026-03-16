
//
//  StartRacingView.swift
//  LegalActivities
//
//  Quick route selection sheet for starting a race.
//

import SwiftUI

struct StartRacingView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationManager = LocationManager()

    @State private var searchText = ""
    @State private var selectedDifficulty: Difficulty? = nil
    @State private var selectedRoute: SavedRoute? = nil

    var body: some View {
        NavigationStack {
            List {
                // Recent routes section
                if !appState.recentRoutes.isEmpty {
                    Section("Recent Routes") {
                        ForEach(appState.recentRoutes) { route in
                            routeRow(route)
                        }
                    }
                }

                // All routes section
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
            .navigationTitle("Select a Route")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .searchable(text: $searchText, prompt: "Search routes")
            .safeAreaInset(edge: .top) {
                difficultyFilterBar
                    .background(Color(.systemBackground))
            }
        }
        .navigationDestination(item: $selectedRoute) { route in
            RaceInProgressView(route: route, locationManager: locationManager)
                .onDisappear {
                    appState.loadRoutes()
                    dismiss()
                }
        }
    }

    @ViewBuilder
    private func routeRow(_ route: SavedRoute) -> some View {
        Button {
            selectedRoute = route
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(route.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    HStack(spacing: 8) {
                        DifficultyBadge(difficulty: route.difficulty)
                        if let pb = appState.personalBest(for: route) {
                            Text("PB: \(formatShortDuration(pb))")
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
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
    }

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
            .padding(.vertical, 8)
        }
    }

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
    StartRacingView()
        .environmentObject(AppState())
}
