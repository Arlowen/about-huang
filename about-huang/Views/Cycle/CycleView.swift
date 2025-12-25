//
//  CycleView.swift
//  about-huang
//
//  周期 - 经期记录与关怀
//

import SwiftUI
import SwiftData

struct CycleView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CycleRecord.startDate, order: .reverse) private var records: [CycleRecord]
    
    @State private var showAddSheet = false
    @State private var showEndSheet = false
    @State private var selectedRecord: CycleRecord?
    
    /// 最近的一条记录
    private var latestRecord: CycleRecord? {
        records.first
    }
    
    /// 是否正在经期中
    private var isOnPeriod: Bool {
        guard let latest = latestRecord else { return false }
        return latest.isOngoing
    }
    
    /// 经期第几天（如果正在经期）
    private var currentPeriodDay: Int {
        guard let latest = latestRecord, latest.isOngoing else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: latest.startDate, to: Date()).day ?? 0
        return days + 1
    }
    
    /// 距离下次经期还有多少天
    private var daysUntilNextPeriod: Int {
        guard let latest = latestRecord else { return 0 }
        return latest.daysUntilNextCycle
    }
    
    /// 圆环进度 (0.0 - 1.0)
    private var ringProgress: Double {
        if isOnPeriod {
            return min(1.0, Double(currentPeriodDay) / 7.0)
        } else {
            let cycleLength = Double(CycleRecord.defaultCycleLength)
            let daysPassed = cycleLength - Double(daysUntilNextPeriod)
            return max(0, min(1.0, daysPassed / cycleLength))
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 状态圆环
                    statusRingSection
                    
                    // 历史记录
                    historySection
                }
                .padding(.bottom, 20)
            }
            .background(backgroundGradient)
            .navigationTitle("周期")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAddSheet) {
                CycleAddSheet()
            }
            .sheet(isPresented: $showEndSheet) {
                if let record = selectedRecord {
                    CycleEndSheet(record: record)
                }
            }
            .sheet(item: $selectedRecord) { record in
                CycleEditSheet(record: record)
            }
        }
    }
    
    // MARK: - 背景渐变
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: isOnPeriod
                ? [Color("CyclePink", bundle: nil).opacity(0.3), Color(.systemBackground)]
                : [Color("XiaoHuangMain", bundle: nil).opacity(0.1), Color(.systemBackground)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    // MARK: - 状态圆环区域
    
    private var statusRingSection: some View {
        VStack(spacing: 24) {
            // 圆环
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 24, lineCap: .round))
                
                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(
                        isOnPeriod ? Color("CyclePink", bundle: nil) : Color("XiaoHuangMain", bundle: nil),
                        style: StrokeStyle(lineWidth: 24, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: ringProgress)
                
                VStack(spacing: 8) {
                    if isOnPeriod {
                        Text("第 \(currentPeriodDay) 天")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(Color("CyclePink", bundle: nil))
                        Text("经期进行中")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else if latestRecord != nil {
                        if daysUntilNextPeriod > 0 {
                            Text("\(daysUntilNextPeriod)")
                                .font(.system(size: 56, weight: .bold, design: .rounded))
                                .foregroundStyle(Color("XiaoHuangMain", bundle: nil))
                            Text("天后可能来")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            // 预测日期已过
                            Text("💭")
                                .font(.system(size: 48))
                            Text("可能快来了")
                                .font(.title3)
                                .foregroundStyle(Color("CyclePink", bundle: nil))
                        }
                    } else {
                        Text("🌸")
                            .font(.system(size: 48))
                        Text("开始记录")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 220, height: 220)
            
            // 主按钮
            if !isOnPeriod {
                Button {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    showAddSheet = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "drop.fill")
                        Text("记录新周期")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 160, height: 50)
                    .background(
                        Capsule()
                            .fill(Color("CyclePink", bundle: nil))
                            .shadow(color: Color("CyclePink", bundle: nil).opacity(0.4), radius: 8, x: 0, y: 4)
                    )
                }
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - 历史记录区域
    
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("历史记录")
                    .font(.headline)
                Spacer()
                Text("\(records.count) 条")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            
            if records.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 40))
                        .foregroundStyle(.tertiary)
                    Text("暂无记录")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(records) { record in
                        CycleHistoryCard(record: record) {
                            selectedRecord = record
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - 历史记录卡片

struct CycleHistoryCard: View {
    let record: CycleRecord
    let onTap: () -> Void
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // 左侧图标
                Circle()
                    .fill(record.isOngoing ? Color("CyclePink", bundle: nil) : Color("CyclePink", bundle: nil).opacity(0.3))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: record.isOngoing ? "drop.fill" : "checkmark")
                            .foregroundColor(record.isOngoing ? .white : Color("CyclePink", bundle: nil))
                    )
                
                // 中间信息
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(dateFormatter.string(from: record.startDate))
                            .font(.headline)
                        
                        if let endDate = record.endDate {
                            Text("→")
                                .foregroundStyle(.secondary)
                            Text(dateFormatter.string(from: endDate))
                                .font(.headline)
                        } else {
                            Text("进行中")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color("CyclePink", bundle: nil)))
                        }
                    }
                    
                    HStack(spacing: 12) {
                        if let duration = record.durationDays {
                            Label("\(duration) 天", systemImage: "calendar")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        if !record.note.isEmpty {
                            Label("有备注", systemImage: "note.text")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 添加新周期 Sheet

struct CycleAddSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var startDate = Date()
    @State private var hasEnded = false
    @State private var endDate = Date()
    @State private var isPainful = false
    @State private var note = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("开始时间") {
                    DatePicker("开始日期", selection: $startDate, displayedComponents: .date)
                }
                
                Section("结束时间") {
                    Toggle("已结束", isOn: $hasEnded)
                    
                    if hasEnded {
                        DatePicker("结束日期", selection: $endDate, in: startDate..., displayedComponents: .date)
                    }
                }
                
                Section("备注") {
                    TextField("备注（可选）", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("记录新周期")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { saveRecord() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private func saveRecord() {
        let newRecord = CycleRecord(
            startDate: startDate,
            endDate: hasEnded ? endDate : nil,
            isPainful: isPainful,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        modelContext.insert(newRecord)
        
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
        
        dismiss()
    }
}

// MARK: - 结束周期 Sheet

struct CycleEndSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var record: CycleRecord
    
    @State private var endDate = Date()
    @State private var isPainful = false
    @State private var note = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("结束时间") {
                    DatePicker("结束日期", selection: $endDate, in: record.startDate..., displayedComponents: .date)
                }
                
                Section("备注") {
                    TextField("备注（可选）", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("记录结束")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("确认") { endRecord() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                isPainful = record.isPainful
                note = record.note
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
    
    private func endRecord() {
        record.endDate = endDate
        record.isPainful = isPainful
        record.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
        
        dismiss()
    }
}

// MARK: - 编辑周期 Sheet

struct CycleEditSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var record: CycleRecord
    
    @State private var startDate = Date()
    @State private var hasEnded = false
    @State private var endDate = Date()
    @State private var isPainful = false
    @State private var note = ""
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("开始时间") {
                    DatePicker("开始日期", selection: $startDate, displayedComponents: .date)
                }
                
                Section("结束时间") {
                    Toggle("已结束", isOn: $hasEnded)
                    
                    if hasEnded {
                        DatePicker("结束日期", selection: $endDate, in: startDate..., displayedComponents: .date)
                    }
                }
                
                Section("备注") {
                    TextField("备注（可选）", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Button("删除此记录", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                }
            }
            .navigationTitle("编辑记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { saveChanges() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                startDate = record.startDate
                hasEnded = record.endDate != nil
                endDate = record.endDate ?? Date()
                isPainful = record.isPainful
                note = record.note
            }
            .confirmationDialog("确定删除", isPresented: $showDeleteConfirmation) {
                Button("删除", role: .destructive) {
                    deleteRecord()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("删除后无法恢复")
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private func saveChanges() {
        record.startDate = startDate
        record.endDate = hasEnded ? endDate : nil
        record.isPainful = isPainful
        record.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
        
        dismiss()
    }
    
    private func deleteRecord() {
        modelContext.delete(record)
        
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.warning)
        
        dismiss()
    }
}

// MARK: - Preview

#Preview("正常状态") {
    CycleView()
        .modelContainer(for: CycleRecord.self, inMemory: true) { result in
            if case .success(let container) = result {
                let context = container.mainContext
                // 添加一条已结束的记录（模拟非经期状态）
                let pastRecord = CycleRecord(
                    startDate: Calendar.current.date(byAdding: .day, value: -20, to: Date())!,
                    endDate: Calendar.current.date(byAdding: .day, value: -15, to: Date())!
                )
                context.insert(pastRecord)
            }
        }
}

#Preview("经期中") {
    CycleView()
        .modelContainer(for: CycleRecord.self, inMemory: true) { result in
            if case .success(let container) = result {
                let context = container.mainContext
                // 添加一条进行中的记录
                let ongoingRecord = CycleRecord(
                    startDate: Calendar.current.date(byAdding: .day, value: -2, to: Date())!
                )
                context.insert(ongoingRecord)
            }
        }
}
