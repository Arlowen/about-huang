//
//  RoleSelectionView.swift
//  about-huang
//
//  角色选择页面
//

import SwiftUI

struct RoleSelectionView: View {
    @ObservedObject var userSettings = UserSettings.shared
    @State private var selectedRole: UserRole?
    @State private var showConfirmation = false
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                colors: [
                    Color("XiaoHuangMain", bundle: nil).opacity(0.3),
                    Color("CyclePink", bundle: nil).opacity(0.2),
                    Color(.systemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // 标题
                VStack(spacing: 12) {
                    Text("关于小黄")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(Color("XiaoHuangMain", bundle: nil))
                    
                    Text("选择你的身份")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                
                // 角色选择卡片
                HStack(spacing: 20) {
                    RoleCard(
                        role: .xiaoHuang,
                        isSelected: selectedRole == .xiaoHuang
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedRole = .xiaoHuang
                        }
                    }
                    
                    RoleCard(
                        role: .xiaoZhang,
                        isSelected: selectedRole == .xiaoZhang
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedRole = .xiaoZhang
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // 确认按钮
                Button {
                    if let role = selectedRole {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        userSettings.selectRole(role)
                    }
                } label: {
                    Text("进入")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(selectedRole != nil ? Color("XiaoHuangMain", bundle: nil) : Color.gray)
                        )
                }
                .disabled(selectedRole == nil)
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - 角色卡片

struct RoleCard: View {
    let role: UserRole
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                // Emoji
                Text(role.emoji)
                    .font(.system(size: 64))
                
                // 名字
                Text("我是\(role.displayName)")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemBackground))
                    .shadow(
                        color: isSelected ? Color("XiaoHuangMain", bundle: nil).opacity(0.4) : .black.opacity(0.1),
                        radius: isSelected ? 12 : 8,
                        x: 0,
                        y: 4
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        isSelected ? Color("XiaoHuangMain", bundle: nil) : Color.clear,
                        lineWidth: 3
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RoleSelectionView()
}
