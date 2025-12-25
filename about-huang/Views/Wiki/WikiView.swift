//
//  WikiView.swift
//  about-huang
//
//  说明书 - 个人喜好档案
//

import SwiftUI
import SwiftData

struct WikiView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ProfileItem.section) private var items: [ProfileItem]
    
    @State private var showAddSheet = false
    @State private var selectedItem: ProfileItem?
    
    /// 按 section 分组的数据
    private var groupedItems: [(section: String, items: [ProfileItem])] {
        let grouped = Dictionary(grouping: items) { $0.section }
        // 按预定义顺序排列
        let orderedSections = ProfileItem.predefinedSections
        return orderedSections.compactMap { section in
            guard let sectionItems = grouped[section], !sectionItems.isEmpty else { return nil }
            return (section: section, items: sectionItems)
        } + grouped.filter { !orderedSections.contains($0.key) }
            .map { (section: $0.key, items: $0.value) }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // 顶部 Header
                profileHeader
                
                // 分组内容
                ForEach(groupedItems, id: \.section) { group in
                    Section(group.section) {
                        ForEach(group.items) { item in
                            NavigationLink {
                                WikiEditView(item: item)
                            } label: {
                                WikiRowView(item: item)
                            }
                        }
                        .onDelete { indexSet in
                            deleteItems(in: group.section, at: indexSet)
                        }
                    }
                }
                
                // 添加新条目
                Section {
                    Button {
                        showAddSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(Color("XiaoHuangMain", bundle: nil))
                            Text("添加新条目")
                                .foregroundColor(Color("XiaoHuangMain", bundle: nil))
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("说明书")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showAddSheet) {
                WikiAddSheet()
            }
        }
    }
    
    // MARK: - 头像 Header
    
    private var profileHeader: some View {
        Section {
            VStack(spacing: 16) {
                // 头像
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color("XiaoHuangMain", bundle: nil),
                                    Color("XiaoHuangMain", bundle: nil).opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                    
                    Text("🐥")
                        .font(.system(size: 50))
                }
                .shadow(color: Color("XiaoHuangMain", bundle: nil).opacity(0.3), radius: 8, x: 0, y: 4)
                
                // 名字和签名
                VStack(spacing: 4) {
                    Text("小黄")
                        .font(.title2.weight(.bold))
                    
                    Text("「被偏爱的都有恃无恐 💕」")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .listRowBackground(Color.clear)
        }
    }
    
    // MARK: - 删除条目
    
    private func deleteItems(in section: String, at offsets: IndexSet) {
        let sectionItems = groupedItems.first { $0.section == section }?.items ?? []
        for index in offsets {
            let item = sectionItems[index]
            modelContext.delete(item)
        }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

// MARK: - 行视图

struct WikiRowView: View {
    let item: ProfileItem
    
    var body: some View {
        HStack {
            Text(item.title)
                .foregroundStyle(.primary)
            
            Spacer()
            
            Text(item.content)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(maxWidth: 180, alignment: .trailing)
        }
    }
}

// MARK: - 编辑页面

struct WikiEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var item: ProfileItem
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var section: String = ""
    
    var body: some View {
        Form {
            Section("分组") {
                Picker("所属分组", selection: $section) {
                    ForEach(ProfileItem.predefinedSections, id: \.self) { sectionName in
                        Text(sectionName).tag(sectionName)
                    }
                }
            }
            
            Section("标题") {
                TextField("标题", text: $title)
            }
            
            Section("内容") {
                TextEditor(text: $content)
                    .frame(minHeight: 100)
            }
            
            Section {
                HStack {
                    Text("上次更新")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(item.lastUpdated.formatted(.dateTime.month().day().hour().minute()))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .navigationTitle("编辑条目")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    saveChanges()
                }
                .fontWeight(.semibold)
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .onAppear {
            title = item.title
            content = item.content
            section = item.section
        }
    }
    
    private func saveChanges() {
        item.title = title.trimmingCharacters(in: .whitespaces)
        item.content = content.trimmingCharacters(in: .whitespaces)
        item.section = section
        item.lastUpdated = Date()
        
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
        
        dismiss()
    }
}

// MARK: - 添加新条目 Sheet

struct WikiAddSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var section: String = "基础档案"
    
    var body: some View {
        NavigationStack {
            Form {
                Section("分组") {
                    Picker("所属分组", selection: $section) {
                        ForEach(ProfileItem.predefinedSections, id: \.self) { sectionName in
                            Text(sectionName).tag(sectionName)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("标题") {
                    TextField("例如：奶茶偏好", text: $title)
                }
                
                Section("内容") {
                    TextField("例如：三分糖去冰", text: $content)
                }
            }
            .navigationTitle("添加条目")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        addItem()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
    
    private func addItem() {
        let newItem = ProfileItem(
            section: section,
            title: title.trimmingCharacters(in: .whitespaces),
            content: content.trimmingCharacters(in: .whitespaces)
        )
        
        modelContext.insert(newItem)
        
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
        
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    WikiView()
        .modelContainer(for: ProfileItem.self, inMemory: true) { result in
            if case .success(let container) = result {
                let context = container.mainContext
                for item in ProfileItem.preview {
                    context.insert(item)
                }
            }
        }
}
