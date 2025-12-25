//
//  WishesView.swift
//  about-huang
//
//  愿望 - 心愿单与兑换券
//

import SwiftUI
import SwiftData

struct WishesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Wish.createdAt, order: .reverse) private var allWishes: [Wish]
    
    @State private var selectedTab: WishTab = .inProgress
    @State private var showAddSheet = false
    @State private var wishToUse: Wish?
    @State private var showUseConfirmation = false
    @State private var showSuccessAnimation = false
    
    enum WishTab: String, CaseIterable {
        case inProgress = "进行中"
        case completed = "已完成"
    }
    
    /// 过滤后的愿望列表
    private var filteredWishes: [Wish] {
        switch selectedTab {
        case .inProgress:
            return allWishes.filter { $0.status == .todo }
        case .completed:
            return allWishes.filter { $0.status == .completed || $0.status == .used }
        }
    }
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 主内容
                VStack(spacing: 0) {
                    // 自定义 Segment Control
                    segmentControl
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    
                    // 网格内容
                    if filteredWishes.isEmpty {
                        emptyStateView
                    } else {
                        wishesGrid
                    }
                }
                
                // 悬浮添加按钮
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        fabButton
                    }
                }
                
                // 成功动画遮罩
                if showSuccessAnimation {
                    successAnimationOverlay
                }
            }
            .navigationTitle("愿望")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground))
            .sheet(isPresented: $showAddSheet) {
                AddWishSheet()
            }
            .confirmationDialog(
                "使用兑换券",
                isPresented: $showUseConfirmation,
                presenting: wishToUse
            ) { wish in
                Button("确定使用一张") {
                    useCoupon(wish)
                }
                Button("取消", role: .cancel) {}
            } message: { wish in
                Text("「\(wish.title)」\n剩余 \(wish.remainingCount) 张")
            }
        }
    }
    
    // MARK: - Segment Control
    
    private var segmentControl: some View {
        HStack(spacing: 0) {
            ForEach(WishTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                    let selectionFeedback = UISelectionFeedbackGenerator()
                    selectionFeedback.selectionChanged()
                } label: {
                    Text(tab.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(selectedTab == tab ? .white : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selectedTab == tab
                                ? Capsule().fill(Color("XiaoHuangMain", bundle: nil))
                                : Capsule().fill(Color.clear)
                        )
                }
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    // MARK: - 空状态视图
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: selectedTab == .inProgress ? "star.slash" : "checkmark.circle")
                .font(.system(size: 64))
                .foregroundStyle(.tertiary)
            
            Text(selectedTab == .inProgress ? "还没有愿望" : "还没有完成的愿望")
                .font(.title3)
                .foregroundStyle(.secondary)
            
            if selectedTab == .inProgress {
                Text("点击右下角 + 添加第一个愿望")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - 愿望网格
    
    private var wishesGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(filteredWishes) { wish in
                    if wish.type == .coupon {
                        CouponCard(wish: wish) {
                            wishToUse = wish
                            showUseConfirmation = true
                        }
                    } else {
                        NormalWishCard(wish: wish)
                    }
                }
            }
            .padding(20)
            .padding(.bottom, 80) // 为 FAB 留出空间
        }
    }
    
    // MARK: - 悬浮添加按钮
    
    private var fabButton: some View {
        Button {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            showAddSheet = true
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(Color("XiaoHuangMain", bundle: nil))
                        .shadow(color: Color("XiaoHuangMain", bundle: nil).opacity(0.4), radius: 8, x: 0, y: 4)
                )
        }
        .padding(.trailing, 24)
        .padding(.bottom, 24)
    }
    
    // MARK: - 成功动画遮罩
    
    private var successAnimationOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                    .symbolEffect(.bounce, value: showSuccessAnimation)
                
                Text("兑换成功！")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
            }
        }
        .transition(.opacity)
    }
    
    // MARK: - 使用兑换券
    
    private func useCoupon(_ wish: Wish) {
        // Heavy 震动反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        // 显示成功动画
        withAnimation {
            showSuccessAnimation = true
        }
        
        // 更新数据
        wish.useCoupon()
        
        // 延迟隐藏动画
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showSuccessAnimation = false
            }
        }
    }
}

// MARK: - 普通愿望卡片

struct NormalWishCard: View {
    let wish: Wish
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 图标
            Image(systemName: wish.icon)
                .font(.system(size: 32))
                .foregroundColor(Color("XiaoHuangMain", bundle: nil))
                .frame(width: 56, height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color("XiaoHuangMain", bundle: nil).opacity(0.15))
                )
            
            // 标题
            Text(wish.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            // 进度条
            VStack(alignment: .leading, spacing: 4) {
                ProgressView(value: wish.progress)
                    .tint(Color("XiaoHuangMain", bundle: nil))
                
                Text("\(Int(wish.progress * 100))%")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 160)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
        .overlay(
            // 已完成标记
            Group {
                if wish.status == .completed {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                        .padding(8)
                }
            },
            alignment: .topTrailing
        )
    }
}

// MARK: - 兑换券卡片（电影票样式）

struct CouponCard: View {
    let wish: Wish
    let onUse: () -> Void
    
    private var isUsedUp: Bool {
        wish.remainingCount <= 0
    }
    
    var body: some View {
        Button(action: {
            if !isUsedUp {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                onUse()
            }
        }) {
            VStack(spacing: 0) {
                // 上半部分
                VStack(spacing: 8) {
                    Image(systemName: wish.icon)
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                    
                    Text(wish.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .background(
                    isUsedUp
                        ? Color.gray
                        : Color("CyclePink", bundle: nil)
                )
                
                // 锯齿分割线
                CouponDivider()
                    .fill(Color(.systemBackground))
                    .frame(height: 16)
                    .background(isUsedUp ? Color.gray : Color("CyclePink", bundle: nil))
                
                // 下半部分
                VStack(spacing: 4) {
                    Text(isUsedUp ? "已用完" : "剩余")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(isUsedUp ? "×" : "\(wish.remainingCount) 张")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(isUsedUp ? .secondary : .primary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(Color(.systemBackground))
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
            .opacity(isUsedUp ? 0.6 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isUsedUp)
    }
}

// MARK: - 锯齿分割线形状

struct CouponDivider: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let segmentWidth: CGFloat = 12
        let segmentCount = Int(rect.width / segmentWidth)
        
        path.move(to: CGPoint(x: 0, y: 0))
        
        for i in 0..<segmentCount {
            let x = CGFloat(i) * segmentWidth
            
            // 半圆缺口
            path.addArc(
                center: CGPoint(x: x + segmentWidth / 2, y: 0),
                radius: segmentWidth / 2,
                startAngle: .degrees(180),
                endAngle: .degrees(0),
                clockwise: true
            )
        }
        
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        
        for i in stride(from: segmentCount - 1, through: 0, by: -1) {
            let x = CGFloat(i) * segmentWidth
            
            path.addArc(
                center: CGPoint(x: x + segmentWidth / 2, y: rect.height),
                radius: segmentWidth / 2,
                startAngle: .degrees(0),
                endAngle: .degrees(180),
                clockwise: true
            )
        }
        
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - 添加愿望 Sheet

struct AddWishSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var selectedIcon: String = "star.fill"
    @State private var selectedType: WishType = .normal
    @State private var totalCount: Int = 3
    
    private let iconOptions = [
        "star.fill", "heart.fill", "gift.fill", "airplane",
        "cup.and.saucer.fill", "film.fill", "gamecontroller.fill",
        "bag.fill", "sparkles", "moon.stars.fill"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                // 类型选择
                Section("类型") {
                    Picker("愿望类型", selection: $selectedType) {
                        ForEach(WishType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // 基本信息
                Section("基本信息") {
                    TextField("愿望标题", text: $title)
                    
                    // 图标选择
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(iconOptions, id: \.self) { icon in
                                Button {
                                    selectedIcon = icon
                                } label: {
                                    Image(systemName: icon)
                                        .font(.title2)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(selectedIcon == icon ?
                                                      Color("XiaoHuangMain", bundle: nil).opacity(0.2) :
                                                      Color(.tertiarySystemBackground))
                                        )
                                        .foregroundColor(selectedIcon == icon ?
                                                         Color("XiaoHuangMain", bundle: nil) :
                                                         .secondary)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // 兑换券设置
                if selectedType == .coupon {
                    Section("兑换券设置") {
                        Stepper("总次数: \(totalCount)", value: $totalCount, in: 1...20)
                    }
                }
            }
            .navigationTitle("新愿望")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveWish()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func saveWish() {
        let newWish = Wish(
            title: title.trimmingCharacters(in: .whitespaces),
            icon: selectedIcon,
            type: selectedType,
            totalCount: selectedType == .coupon ? totalCount : 1
        )
        
        modelContext.insert(newWish)
        
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
        
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    WishesView()
        .modelContainer(for: Wish.self, inMemory: true) { result in
            if case .success(let container) = result {
                let context = container.mainContext
                for wish in Wish.preview {
                    context.insert(wish)
                }
            }
        }
}
