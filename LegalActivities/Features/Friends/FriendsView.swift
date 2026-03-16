
//
//  FriendsView.swift
//  LegalActivities
//
//  Friends list with mock friend profiles and race activity.
//

import SwiftUI

struct FriendsView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedFriend: Friend? = nil

    var body: some View {
        NavigationStack {
            Group {
                if appState.friends.isEmpty {
                    emptyView
                } else {
                    List {
                        ForEach(appState.friends) { friend in
                            Button {
                                selectedFriend = friend
                            } label: {
                                FriendRow(friend: friend, appState: appState)
                            }
                            .listRowBackground(Color(.secondarySystemBackground))
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedFriend) { friend in
                FriendDetailView(friend: friend)
                    .environmentObject(appState)
            }
            .onAppear {
                appState.refreshFriendsAndFeed()
            }
        }
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No friends yet")
                .font(.headline)
            Text("Create routes and race to see friends activity here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Friend Row
struct FriendRow: View {
    let friend: Friend
    let appState: AppState

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: friend.avatarSystemName)
                .font(.title)
                .foregroundStyle(.blue)
                .frame(width: 44, height: 44)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(friend.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                if let recent = friend.recentRaces.first {
                    Text("Last raced \(recent.routeName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(recent.date.formatted(.relative(presentation: .named)))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                } else {
                    Text("No recent activity")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let recent = friend.recentRaces.first {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatShortDuration(recent.totalDuration))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text(appState.userProfile.unitPreference.formatDistance(recent.totalDistance))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Friend Detail View
struct FriendDetailView: View {
    let friend: Friend
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    profileHeader
                    statsSection
                    personalBestsSection
                    recentRacesSection
                }
                .padding(.vertical)
            }
            .navigationTitle(friend.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: friend.avatarSystemName)
                .font(.system(size: 56))
                .foregroundStyle(.blue)
                .frame(width: 80, height: 80)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())

            Text(friend.name)
                .font(.title2)
                .fontWeight(.bold)

            Text("\(friend.recentRaces.count) recent races")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private var statsSection: some View {
        let units = appState.userProfile.unitPreference
        let totalDist = friend.recentRaces.reduce(0.0) { $0 + $1.totalDistance }
        let bestSpeed = friend.recentRaces.map { $0.averageSpeed }.max() ?? 0

        return VStack(alignment: .leading, spacing: 10) {
            Text("Stats")
                .font(.headline)
                .padding(.horizontal)

            HStack(spacing: 0) {
                statCell(value: "\(friend.recentRaces.count)", label: "Races")
                Divider().frame(height: 40)
                statCell(value: units.formatDistance(totalDist), label: "Total Dist.")
                Divider().frame(height: 40)
                statCell(value: units.formatSpeed(bestSpeed), label: "Best Speed")
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        }
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var personalBestsSection: some View {
        Group {
            if !friend.personalBests.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Personal Bests")
                        .font(.headline)
                        .padding(.horizontal)

                    VStack(spacing: 0) {
                        ForEach(Array(friend.personalBests.sorted(by: { $0.value < $1.value }).prefix(5)), id: \.key) { routeIdStr, time in
                            let routeName = appState.savedRoutes.first(where: { $0.id.uuidString == routeIdStr })?.name ?? "Unknown Route"
                            HStack {
                                Image(systemName: "trophy.fill")
                                    .foregroundStyle(.yellow)
                                    .font(.caption)
                                Text(routeName)
                                    .font(.subheadline)
                                Spacer()
                                Text(formatShortDuration(time))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.blue)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                            Divider().padding(.horizontal)
                        }
                    }
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }
            }
        }
    }

    private var recentRacesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Races")
                .font(.headline)
                .padding(.horizontal)

            if friend.recentRaces.isEmpty {
                Text("No races yet.")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                VStack(spacing: 0) {
                    ForEach(friend.recentRaces) { race in
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(race.routeName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(race.date.formatted(.relative(presentation: .named)))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 3) {
                                Text(formatShortDuration(race.totalDuration))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text(appState.userProfile.unitPreference.formatDistance(race.totalDistance))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        Divider().padding(.horizontal)
                    }
                }
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }
        }
    }
}

#Preview {
    FriendsView()
        .environmentObject(AppState())
}
