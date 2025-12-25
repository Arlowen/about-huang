//
//  NetworkService.swift
//  about-huang
//
//  网络服务 - 与后端 API 通信
//

import Foundation

/// 互动卡片 DTO
struct InteractionCardDTO: Codable, Identifiable {
    let id: String?
    let senderRole: String
    let receiverRole: String?
    let cardType: String
    let title: String
    let icon: String
    let message: String?
    let timestamp: String?
    let isRead: Bool?
    
    var formattedTime: String {
        guard let timestamp = timestamp else { return "" }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: timestamp) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MM-dd HH:mm"
            return displayFormatter.string(from: date)
        }
        return timestamp
    }
}

/// 网络服务
class NetworkService {
    static let shared = NetworkService()
    
    // TODO: 替换为实际的后端地址
    private let baseURL = "http://localhost:8080/api"
    
    private init() {}
    
    /// 发送互动卡片
    func sendCard(senderRole: String, cardType: String, title: String, icon: String, message: String? = nil) async throws -> InteractionCardDTO {
        let url = URL(string: "\(baseURL)/cards")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: String] = [
            "senderRole": senderRole,
            "cardType": cardType,
            "title": title,
            "icon": icon
        ]
        if let message = message {
            body["message"] = message
        }
        
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(InteractionCardDTO.self, from: data)
    }
    
    /// 获取收到的卡片
    func getReceivedCards(receiverRole: String) async throws -> [InteractionCardDTO] {
        let url = URL(string: "\(baseURL)/cards/\(receiverRole)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([InteractionCardDTO].self, from: data)
    }
    
    /// 获取未读卡片数量
    func getUnreadCount(receiverRole: String) async throws -> Int {
        let url = URL(string: "\(baseURL)/cards/\(receiverRole)/unread-count")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let result = try JSONDecoder().decode([String: Int].self, from: data)
        return result["count"] ?? 0
    }
    
    /// 标记卡片已读
    func markAsRead(cardId: String) async throws {
        let url = URL(string: "\(baseURL)/cards/\(cardId)/read")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        _ = try await URLSession.shared.data(for: request)
    }
    
    /// 标记所有卡片已读
    func markAllAsRead(receiverRole: String) async throws {
        let url = URL(string: "\(baseURL)/cards/\(receiverRole)/read-all")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        _ = try await URLSession.shared.data(for: request)
    }
}
