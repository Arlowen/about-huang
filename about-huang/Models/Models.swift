//
//  Models.swift
//  about-huang
//
//  SwiftData Models for 关于小黄 App
//

import Foundation
import SwiftData

// MARK: - Moment (碎碎念)

@Model
final class Moment {
    @Attribute(.unique) var id: UUID
    var content: String
    var timestamp: Date
    var mood: String
    @Attribute(.externalStorage) var imageData: Data?
    
    init(
        id: UUID = UUID(),
        content: String,
        timestamp: Date = .now,
        mood: String = "😊",
        imageData: Data? = nil
    ) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
        self.mood = mood
        self.imageData = imageData
    }
    
    static var preview: [Moment] {
        [
            Moment(content: "今天一起去看了电影，很开心！🎬", mood: "😍"),
            Moment(content: "周末在家做了火锅，小黄吃了好多肉肉", timestamp: Date().addingTimeInterval(-86400), mood: "🥰"),
            Moment(content: "下班路上买了她喜欢的草莓蛋糕", timestamp: Date().addingTimeInterval(-172800), mood: "🍰"),
            Moment(content: "今天有点不开心，需要抱抱", timestamp: Date().addingTimeInterval(-259200), mood: "🥺")
        ]
    }
}

// MARK: - CycleRecord (周期记录)

@Model
final class CycleRecord {
    @Attribute(.unique) var id: UUID
    var startDate: Date
    var endDate: Date?
    var isPainful: Bool
    var note: String
    
    /// 默认周期天数
    static let defaultCycleLength: Int = 28
    
    init(
        id: UUID = UUID(),
        startDate: Date,
        endDate: Date? = nil,
        isPainful: Bool = false,
        note: String = ""
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.isPainful = isPainful
        self.note = note
    }
    
    /// 计算经期持续天数
    var durationDays: Int? {
        guard let endDate = endDate else { return nil }
        return Calendar.current.dateComponents([.day], from: startDate, to: endDate).day
    }
    
    /// 预测下一次经期开始日期（基于本次开始日期 + 默认周期）
    var predictedNextStartDate: Date {
        Calendar.current.date(byAdding: .day, value: CycleRecord.defaultCycleLength, to: startDate) ?? startDate
    }
    
    /// 距离下一次经期的天数
    var daysUntilNextCycle: Int {
        let today = Calendar.current.startOfDay(for: Date())
        let predicted = Calendar.current.startOfDay(for: predictedNextStartDate)
        return Calendar.current.dateComponents([.day], from: today, to: predicted).day ?? 0
    }
    
    /// 经期是否正在进行中
    var isOngoing: Bool {
        endDate == nil
    }
    
    static var preview: [CycleRecord] {
        let calendar = Calendar.current
        return [
            CycleRecord(
                startDate: calendar.date(byAdding: .day, value: -5, to: Date())!,
                endDate: Date(),
                isPainful: true,
                note: "第一天有点难受，喝了红糖水"
            ),
            CycleRecord(
                startDate: calendar.date(byAdding: .day, value: -33, to: Date())!,
                endDate: calendar.date(byAdding: .day, value: -28, to: Date())!,
                isPainful: false,
                note: "这次挺顺利的"
            ),
            CycleRecord(
                startDate: calendar.date(byAdding: .day, value: -61, to: Date())!,
                endDate: calendar.date(byAdding: .day, value: -56, to: Date())!,
                isPainful: true,
                note: "需要热水袋"
            )
        ]
    }
}

// MARK: - Wish (愿望)

/// 愿望类型
enum WishType: String, Codable, CaseIterable {
    case normal = "普通愿望"
    case coupon = "兑换券"
    
    var icon: String {
        switch self {
        case .normal: return "star.fill"
        case .coupon: return "ticket.fill"
        }
    }
}

/// 愿望状态
enum WishStatus: String, Codable, CaseIterable {
    case todo = "进行中"
    case completed = "已完成"
    case used = "已核销"
    
    var color: String {
        switch self {
        case .todo: return "orange"
        case .completed: return "green"
        case .used: return "gray"
        }
    }
}

@Model
final class Wish {
    @Attribute(.unique) var id: UUID
    var title: String
    var icon: String
    var typeRawValue: String
    var statusRawValue: String
    var progress: Double
    var totalCount: Int
    var usedCount: Int
    var createdAt: Date
    
    var type: WishType {
        get { WishType(rawValue: typeRawValue) ?? .normal }
        set { typeRawValue = newValue.rawValue }
    }
    
    var status: WishStatus {
        get { WishStatus(rawValue: statusRawValue) ?? .todo }
        set { statusRawValue = newValue.rawValue }
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        icon: String = "star.fill",
        type: WishType = .normal,
        status: WishStatus = .todo,
        progress: Double = 0.0,
        totalCount: Int = 1,
        usedCount: Int = 0,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.typeRawValue = type.rawValue
        self.statusRawValue = status.rawValue
        self.progress = progress
        self.totalCount = totalCount
        self.usedCount = usedCount
        self.createdAt = createdAt
    }
    
    /// 兑换券剩余次数
    var remainingCount: Int {
        max(0, totalCount - usedCount)
    }
    
    /// 使用一次兑换券
    func useCoupon() {
        guard type == .coupon, usedCount < totalCount else { return }
        usedCount += 1
        if usedCount >= totalCount {
            status = .used
        }
    }
    
    /// 更新普通愿望进度
    func updateProgress(_ newProgress: Double) {
        guard type == .normal else { return }
        progress = min(1.0, max(0.0, newProgress))
        if progress >= 1.0 {
            status = .completed
        }
    }
    
    static var preview: [Wish] {
        [
            Wish(title: "一起去迪士尼", icon: "sparkles", type: .normal, progress: 0.6),
            Wish(title: "想要新款 AirPods", icon: "airpodspro", type: .normal, progress: 0.3),
            Wish(title: "免费按摩券", icon: "hand.raised.fill", type: .coupon, totalCount: 5, usedCount: 2),
            Wish(title: "任选奶茶券", icon: "cup.and.saucer.fill", type: .coupon, totalCount: 10, usedCount: 3),
            Wish(title: "电影之夜", icon: "film.fill", type: .normal, status: .completed, progress: 1.0)
        ]
    }
}

// MARK: - ProfileItem (说明书条目)

@Model
final class ProfileItem {
    @Attribute(.unique) var id: UUID
    var section: String
    var title: String
    var content: String
    var lastUpdated: Date
    
    init(
        id: UUID = UUID(),
        section: String,
        title: String,
        content: String,
        lastUpdated: Date = .now
    ) {
        self.id = id
        self.section = section
        self.title = title
        self.content = content
        self.lastUpdated = lastUpdated
    }
    
    /// 预定义的分组
    static let predefinedSections = [
        "基础档案",
        "饮食偏好",
        "生存指南",
        "兴趣爱好",
        "禁忌雷区"
    ]
    
    static var preview: [ProfileItem] {
        [
            // 基础档案
            ProfileItem(section: "基础档案", title: "生日", content: "12月25日 🎄"),
            ProfileItem(section: "基础档案", title: "纪念日", content: "2020年5月20日 💕"),
            ProfileItem(section: "基础档案", title: "星座", content: "摩羯座 ♑"),
            
            // 饮食偏好
            ProfileItem(section: "饮食偏好", title: "奶茶偏好", content: "三分糖，去冰，燕麦奶"),
            ProfileItem(section: "饮食偏好", title: "最爱水果", content: "草莓 🍓 > 车厘子 🍒 > 芒果 🥭"),
            ProfileItem(section: "饮食偏好", title: "火锅锅底", content: "番茄锅 + 菌汤锅，绝不要辣锅！"),
            ProfileItem(section: "饮食偏好", title: "不吃的食物", content: "香菜、苦瓜、皮蛋"),
            
            // 生存指南
            ProfileItem(section: "生存指南", title: "生气时怎么哄", content: "先道歉，买奶茶，抱抱不说话"),
            ProfileItem(section: "生存指南", title: "经期关怀", content: "准备红糖水、热水袋、多陪伴少说话"),
            ProfileItem(section: "生存指南", title: "睡眠习惯", content: "需要完全黑暗和安静的环境"),
            
            // 兴趣爱好
            ProfileItem(section: "兴趣爱好", title: "喜欢的电影类型", content: "浪漫喜剧、治愈系动画"),
            ProfileItem(section: "兴趣爱好", title: "最爱的歌手", content: "Taylor Swift、周杰伦"),
            
            // 禁忌雷区
            ProfileItem(section: "禁忌雷区", title: "绝对不能说的话", content: "「你又怎么了」「随便」「你觉得呢」"),
            ProfileItem(section: "禁忌雷区", title: "讨厌的行为", content: "玩手机不回消息、迟到不提前说")
        ]
    }
}
