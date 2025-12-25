//
//  MomentsView.swift
//  about-huang
//
//  碎碎念 - 私密时间轴
//

import SwiftUI
import SwiftData

struct MomentsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Moment.timestamp, order: .reverse) private var moments: [Moment]
    
    @State private var showAddSheet = false
    @State private var selectedMoment: Moment?
    @State private var momentToDelete: Moment?
    @State private var showDeleteConfirmation = false
    
    /// 按天分组的数据
    private var groupedMoments: [(date: String, moments: [Moment])] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh-Hans")
        formatter.dateFormat = "yyyy年M月d日"
        
        let grouped = Dictionary(grouping: moments) { moment in
            formatter.string(from: moment.timestamp)
        }
        return grouped.map { (date: $0.key, moments: $0.value) }
            .sorted { $0.moments.first?.timestamp ?? .now > $1.moments.first?.timestamp ?? .now }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                // 主内容区域
                if moments.isEmpty {
                    emptyStateView
                } else {
                    timelineScrollView
                }
                
                // 悬浮添加按钮
                fabButton
            }
            .navigationTitle("碎碎念")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground))
            .sheet(isPresented: $showAddSheet) {
                AddMomentSheet()
            }
            .sheet(item: $selectedMoment) { moment in
                EditMomentSheet(moment: moment)
            }
            .confirmationDialog("确定删除", isPresented: $showDeleteConfirmation, presenting: momentToDelete) { moment in
                Button("删除", role: .destructive) {
                    deleteMoment(moment)
                }
                Button("取消", role: .cancel) {}
            } message: { _ in
                Text("删除后无法恢复")
            }
        }
    }
    
    // MARK: - 空状态视图
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 64))
                .foregroundStyle(.tertiary)
            
            Text("还没有碎碎念")
                .font(.title3)
                .foregroundStyle(.secondary)
            
            Text("点击右下角的 + 记录第一条")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - 时间轴滚动视图
    
    private var timelineScrollView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: .sectionHeaders) {
                ForEach(groupedMoments, id: \.date) { group in
                    Section {
                        ForEach(group.moments) { moment in
                            MomentTimelineRow(moment: moment, onEdit: {
                                selectedMoment = moment
                            }, onDelete: {
                                momentToDelete = moment
                                showDeleteConfirmation = true
                            })
                        }
                    } header: {
                        sectionHeader(for: group.date)
                    }
                }
            }
            .padding(.bottom, 100) // 为 FAB 留出空间
        }
    }
    
    // MARK: - 日期分组标题
    
    private func sectionHeader(for dateString: String) -> some View {
        HStack {
            Text(dateString)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - 悬浮添加按钮
    
    private var fabButton: some View {
        Button {
            // Haptic 反馈
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            showAddSheet = true
        } label: {
            Image(systemName: "heart.fill")
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
    
    // MARK: - 删除 Moment
    
    private func deleteMoment(_ moment: Moment) {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        modelContext.delete(moment)
    }
}

// MARK: - 时间轴行视图

struct MomentTimelineRow: View {
    let moment: Moment
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    private var timeString: String {
        moment.timestamp.formatted(.dateTime.hour().minute())
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 左侧：时间 + 竖线
            VStack(spacing: 4) {
                Text(timeString)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .frame(width: 50)
                
                // 时间轴圆点
                Circle()
                    .fill(Color("XiaoHuangMain", bundle: nil))
                    .frame(width: 10, height: 10)
                
                // 连接线
                Rectangle()
                    .fill(Color("XiaoHuangMain", bundle: nil).opacity(0.3))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 50)
            
            // 右侧：卡片内容
            momentCard
                .contentShape(Rectangle())
                .onTapGesture {
                    onEdit()
                }
                .contextMenu {
                    Button {
                        onEdit()
                    } label: {
                        Label("编辑", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
    
    // MARK: - 卡片视图
    
    private var momentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 心情 Emoji
            Text(moment.mood)
                .font(.title)
            
            // 文字内容
            Text(moment.content)
                .font(.body)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
            
            // 图片（如果有）
            if let imageData = moment.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Preview

#Preview {
    MomentsView()
        .modelContainer(for: Moment.self, inMemory: true) { result in
            if case .success(let container) = result {
                let context = container.mainContext
                for moment in Moment.preview {
                    context.insert(moment)
                }
            }
        }
}
