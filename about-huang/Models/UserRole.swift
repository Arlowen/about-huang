//
//  UserRole.swift
//  about-huang
//
//  用户角色管理
//

import SwiftUI
import Combine

/// 用户角色
enum UserRole: String, CaseIterable, Codable {
    case xiaoHuang = "xiaoHuang"
    case xiaoZhang = "xiaoZhang"
    
    var displayName: String {
        switch self {
        case .xiaoHuang: return "小黄"
        case .xiaoZhang: return "小张"
        }
    }
    
    var emoji: String {
        switch self {
        case .xiaoHuang: return "🐥"
        case .xiaoZhang: return "👦"
        }
    }
    
    var partnerRole: UserRole {
        switch self {
        case .xiaoHuang: return .xiaoZhang
        case .xiaoZhang: return .xiaoHuang
        }
    }
}

/// 用户设置管理
class UserSettings: ObservableObject {
    static let shared = UserSettings()
    
    private let roleKey = "selectedRole"
    
    @Published private var roleRawValue: String
    
    init() {
        self.roleRawValue = UserDefaults.standard.string(forKey: "selectedRole") ?? ""
    }
    
    var hasSelectedRole: Bool {
        !roleRawValue.isEmpty
    }
    
    var currentRole: UserRole? {
        get { UserRole(rawValue: roleRawValue) }
        set {
            roleRawValue = newValue?.rawValue ?? ""
            UserDefaults.standard.set(roleRawValue, forKey: roleKey)
        }
    }
    
    func selectRole(_ role: UserRole) {
        currentRole = role
    }
    
    func clearRole() {
        roleRawValue = ""
        UserDefaults.standard.set("", forKey: roleKey)
    }
}
