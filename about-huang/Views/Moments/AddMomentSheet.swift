//
//  AddMomentSheet.swift
//  about-huang
//
//  新增碎碎念弹窗
//

import SwiftUI
import SwiftData
import PhotosUI

struct AddMomentSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var content: String = ""
    @State private var selectedMood: String = "😊"
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: Data?
    
    // 可选的心情 Emoji
    private let moodOptions = ["😊", "😍", "🥰", "😋", "🤗", "😴", "🥺", "😢", "😤", "🤔"]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 心情选择器
                    moodPicker
                    
                    // 内容输入
                    contentEditor
                    
                    // 图片选择
                    photoPicker
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("新碎碎念")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveMoment()
                    }
                    .fontWeight(.semibold)
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - 心情选择器
    
    private var moodPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今天心情如何？")
                .font(.headline)
                .foregroundStyle(.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(moodOptions, id: \.self) { mood in
                        Button {
                            // Haptic 反馈
                            let selectionFeedback = UISelectionFeedbackGenerator()
                            selectionFeedback.selectionChanged()
                            
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedMood = mood
                            }
                        } label: {
                            Text(mood)
                                .font(.title)
                                .frame(width: 50, height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedMood == mood ?
                                              Color("XiaoHuangMain", bundle: nil).opacity(0.2) :
                                              Color(.systemBackground))
                                        .shadow(color: selectedMood == mood ?
                                                Color("XiaoHuangMain", bundle: nil).opacity(0.3) :
                                                Color.clear,
                                                radius: 4, x: 0, y: 2)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedMood == mood ?
                                                Color("XiaoHuangMain", bundle: nil) :
                                                Color.clear, lineWidth: 2)
                                )
                        }
                        .scaleEffect(selectedMood == mood ? 1.1 : 1.0)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }
    
    // MARK: - 内容输入区
    
    private var contentEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("想说点什么？")
                .font(.headline)
                .foregroundStyle(.primary)
            
            TextEditor(text: $content)
                .frame(minHeight: 120)
                .padding(12)
                .scrollContentBackground(.hidden)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
                .overlay(
                    Group {
                        if content.isEmpty {
                            Text("记录此刻的心情...")
                                .foregroundStyle(.tertiary)
                                .padding(.leading, 16)
                                .padding(.top, 20)
                        }
                    },
                    alignment: .topLeading
                )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }
    
    // MARK: - 图片选择器
    
    private var photoPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("添加图片（可选）")
                .font(.headline)
                .foregroundStyle(.primary)
            
            if let imageData, let uiImage = UIImage(data: imageData) {
                // 已选择图片 - 显示预览
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // 删除按钮
                    Button {
                        withAnimation {
                            self.imageData = nil
                            self.selectedPhoto = nil
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .shadow(radius: 2)
                    }
                    .padding(8)
                }
            } else {
                // 选择图片按钮
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.title2)
                        Text("选择图片")
                            .font(.body)
                    }
                    .foregroundStyle(Color("XiaoHuangMain", bundle: nil))
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color("XiaoHuangMain", bundle: nil), style: StrokeStyle(lineWidth: 2, dash: [8]))
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .onChange(of: selectedPhoto) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        withAnimation {
                            imageData = data
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 保存逻辑
    
    private func saveMoment() {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return }
        
        // Haptic 反馈
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
        
        let newMoment = Moment(
            content: trimmedContent,
            mood: selectedMood,
            imageData: imageData
        )
        
        modelContext.insert(newMoment)
        
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    AddMomentSheet()
        .modelContainer(for: Moment.self, inMemory: true)
}

// MARK: - 编辑碎碎念 Sheet

struct EditMomentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var moment: Moment
    
    @State private var content: String = ""
    @State private var selectedMood: String = "😊"
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: Data?
    
    // 可选的心情 Emoji
    private let moodOptions = ["😊", "😍", "🥰", "😋", "🤗", "😴", "🥺", "😢", "😤", "🤔"]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 心情选择器
                    moodPicker
                    
                    // 内容输入
                    contentEditor
                    
                    // 图片选择
                    photoPicker
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("编辑")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                content = moment.content
                selectedMood = moment.mood
                imageData = moment.imageData
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - 心情选择器
    
    private var moodPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今天心情如何？")
                .font(.headline)
                .foregroundStyle(.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(moodOptions, id: \.self) { mood in
                        Button {
                            let selectionFeedback = UISelectionFeedbackGenerator()
                            selectionFeedback.selectionChanged()
                            
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedMood = mood
                            }
                        } label: {
                            Text(mood)
                                .font(.title)
                                .frame(width: 50, height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedMood == mood ?
                                              Color("XiaoHuangMain", bundle: nil).opacity(0.2) :
                                              Color(.systemBackground))
                                        .shadow(color: selectedMood == mood ?
                                                Color("XiaoHuangMain", bundle: nil).opacity(0.3) :
                                                Color.clear,
                                                radius: 4, x: 0, y: 2)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedMood == mood ?
                                                Color("XiaoHuangMain", bundle: nil) :
                                                Color.clear, lineWidth: 2)
                                )
                        }
                        .scaleEffect(selectedMood == mood ? 1.1 : 1.0)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }
    
    // MARK: - 内容输入区
    
    private var contentEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("想说点什么？")
                .font(.headline)
                .foregroundStyle(.primary)
            
            TextEditor(text: $content)
                .frame(minHeight: 120)
                .padding(12)
                .scrollContentBackground(.hidden)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
                .overlay(
                    Group {
                        if content.isEmpty {
                            Text("记录此刻的心情...")
                                .foregroundStyle(.tertiary)
                                .padding(.leading, 16)
                                .padding(.top, 20)
                        }
                    },
                    alignment: .topLeading
                )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }
    
    // MARK: - 图片选择器
    
    private var photoPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("添加图片（可选）")
                .font(.headline)
                .foregroundStyle(.primary)
            
            if let imageData, let uiImage = UIImage(data: imageData) {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Button {
                        withAnimation {
                            self.imageData = nil
                            self.selectedPhoto = nil
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .shadow(radius: 2)
                    }
                    .padding(8)
                }
            } else {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.title2)
                        Text("选择图片")
                            .font(.body)
                    }
                    .foregroundStyle(Color("XiaoHuangMain", bundle: nil))
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color("XiaoHuangMain", bundle: nil), style: StrokeStyle(lineWidth: 2, dash: [8]))
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .onChange(of: selectedPhoto) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        withAnimation {
                            imageData = data
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 保存逻辑
    
    private func saveChanges() {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return }
        
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
        
        moment.content = trimmedContent
        moment.mood = selectedMood
        moment.imageData = imageData
        
        dismiss()
    }
}
