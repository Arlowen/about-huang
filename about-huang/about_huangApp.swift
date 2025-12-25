//
//  about_huangApp.swift
//  about-huang
//
//  关于小黄 - 私人情侣 App
//

import SwiftUI
import SwiftData

@main
struct about_huangApp: App {
    @StateObject private var userSettings = UserSettings.shared
    
    init() {
        // 设置中文语言环境
        UserDefaults.standard.set(["zh-Hans"], forKey: "AppleLanguages")
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Moment.self,
            CycleRecord.self,
            Wish.self,
            ProfileItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            if userSettings.hasSelectedRole {
                MainTabView()
                    .environment(\.locale, Locale(identifier: "zh-Hans"))
            } else {
                RoleSelectionView()
                    .environment(\.locale, Locale(identifier: "zh-Hans"))
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
