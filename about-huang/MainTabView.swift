//
//  MainTabView.swift
//  about-huang
//
//  主 TabView - 整合五个核心页面
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .moments
    
    enum Tab: String, CaseIterable {
        case moments = "碎碎念"
        case cycle = "周期"
        case wishes = "愿望"
        case wiki = "说明书"
        
        var icon: String {
            switch self {
            case .moments: return "heart.text.square.fill"
            case .cycle: return "calendar.circle.fill"
            case .wishes: return "star.fill"
            case .wiki: return "book.fill"
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MomentsView()
                .tabItem {
                    Label(Tab.moments.rawValue, systemImage: Tab.moments.icon)
                }
                .tag(Tab.moments)
            
            CycleView()
                .tabItem {
                    Label(Tab.cycle.rawValue, systemImage: Tab.cycle.icon)
                }
                .tag(Tab.cycle)
            
            WishesView()
                .tabItem {
                    Label(Tab.wishes.rawValue, systemImage: Tab.wishes.icon)
                }
                .tag(Tab.wishes)
            
            WikiView()
                .tabItem {
                    Label(Tab.wiki.rawValue, systemImage: Tab.wiki.icon)
                }
                .tag(Tab.wiki)
        }
        .tint(Color("XiaoHuangMain", bundle: nil))
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            UITabBar.appearance().scrollEdgeAppearance = appearance
            UITabBar.appearance().standardAppearance = appearance
        }
    }
}

#Preview {
    MainTabView()
}
