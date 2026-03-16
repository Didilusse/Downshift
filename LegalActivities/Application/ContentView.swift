
//
//  ContentView.swift
//  LegalActivities
//
//  Created by Adil Rahmani on 5/11/25.
//

import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject var appState = AppState()

    var body: some View {
        TabView {
            HomeView()
                .environmentObject(appState)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            RoutesListView()
                .environmentObject(appState)
                .tabItem {
                    Label("Routes", systemImage: "map.fill")
                }

            FriendsView()
                .environmentObject(appState)
                .tabItem {
                    Label("Friends", systemImage: "person.2.fill")
                }

            LeaderboardsView()
                .environmentObject(appState)
                .tabItem {
                    Label("Rankings", systemImage: "list.number")
                }

            NavigationStack {
                ProfileView()
                    .environmentObject(appState)
            }
            .tabItem {
                Label("Profile", systemImage: "person.circle.fill")
            }
        }
    }
}

#Preview {
    ContentView()
}
