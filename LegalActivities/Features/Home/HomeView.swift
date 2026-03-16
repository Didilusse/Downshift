
//
//  HomeView.swift
//  LegalActivities
//
//  Home screen with quick stats, quick actions, and activity feed.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showStartRacing = false
    @State private var showFullFeed = false
    @State private var showProfile = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    quickStatsCard
                    quickActionsSection
                    recentActivitySection
                }
                .padding(.vertical)
            }
            .navigationTitle("LegalActivities")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showProfile = true
                    } label: {
                        Image(systemName: appState.userProfile.avatarSystemName)
                            .font(.title2)
                            .foregroundStyle(.primary)
                    }
                }
            }
            .sheet(isPresented: $showStartRacing) {
                StartRacingView()
                    .environmentObject(appState)
            }
            .sheet(isPresented: $showProfile) {
                NavigationStack {
                    ProfileView()
                        .environmentObject(appState)
                }
            }
            .sheet(isPresented: $showFullFeed) {
                NavigationStack {
                    ActivityFeedView()
                        .environmentObject(appState)
                }
            }
            .onAppear {
                appState.loadRoutes()
            }
        }
    }

    // MARK: - Quick Stats Card
    private var quickStatsCard: some View {
        let weekStats = appState.thisWeekStats()
        let units = appState.userProfile.unitPreference

        return Button {
            showProfile = true
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundStyle(.blue)
                    Text("Quick Stats")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()

                HStack(spacing: 0) {
                    statItem(
                        value: "\(appState.userProfile.totalRaces)",
                        label: "Total Races"
                    )
                    Divider().frame(height: 40)
                    statItem(
                        value: units.formatDistance(weekStats.distance),
                        label: "This Week"
                    )
                    Divider().frame(height: 40)
                    statItem(
                        value: units.formatSpeed(appState.userProfile.bestAvgSpeed),
                        label: "Best Avg Speed"
                    )
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }

    private func statItem(value: String, label: String) -> some View {
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

    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .padding(.horizontal)

            HStack(spacing: 12) {
                NavigationLink {
                    RouteCreationView()
                } label: {
                    quickActionButton(
                        icon: "plus.circle.fill",
                        title: "New Route",
                        color: .blue
                    )
                }
                .buttonStyle(.plain)

                Button {
                    showStartRacing = true
                } label: {
                    quickActionButton(
                        icon: "flag.checkered",
                        title: "Start Racing",
                        color: .green
                    )
                }
                .buttonStyle(.plain)
                .disabled(appState.savedRoutes.isEmpty)
                .opacity(appState.savedRoutes.isEmpty ? 0.5 : 1.0)
            }
            .padding(.horizontal)
        }
    }

    private func quickActionButton(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }

    // MARK: - Recent Activity Feed
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)

            if appState.activityFeed.isEmpty {
                emptyFeedView
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(appState.activityFeed.prefix(5))) { item in
                        ActivityFeedRow(item: item)
                        if item.id != appState.activityFeed.prefix(5).last?.id {
                            Divider().padding(.horizontal)
                        }
                    }
                }
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                .padding(.horizontal)

                Button {
                    showFullFeed = true
                } label: {
                    Text("View All Activity")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal)
            }
        }
    }

    private var emptyFeedView: some View {
        VStack(spacing: 8) {
            Image(systemName: "trophy.fill")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No activity yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Create a route and start racing to see your activity here.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

// MARK: - Activity Feed Row
struct ActivityFeedRow: View {
    let item: ActivityFeedItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.iconName)
                .font(.title2)
                .foregroundStyle(iconColor)
                .frame(width: 36)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(titleText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                if let dur = item.duration {
                    if item.type == .personalBestBeaten, let prev = item.previousBest {
                        Text("\(formatShortDuration(prev)) → \(formatShortDuration(dur))")
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else {
                        Text(formatShortDuration(dur))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(item.relativeTimestamp)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private var titleText: String {
        switch item.type {
        case .personalBestBeaten:
            return "\(item.actorName) beat PB on \(item.routeName)"
        case .routeCompleted:
            return "\(item.actorName) completed \(item.routeName)"
        case .friendRaced:
            return "\(item.actorName) raced \(item.routeName)"
        case .challengeAccepted:
            return "\(item.actorName) accepted a challenge on \(item.routeName)"
        case .challengeCompleted:
            return "\(item.actorName) completed challenge on \(item.routeName)"
        }
    }

    private var iconColor: Color {
        switch item.type {
        case .personalBestBeaten: return .yellow
        case .routeCompleted: return .green
        case .friendRaced: return .blue
        case .challengeAccepted: return .orange
        case .challengeCompleted: return .purple
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
}
