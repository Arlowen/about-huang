package com.xiaohuang.controller;

import com.xiaohuang.model.InteractionCard;
import com.xiaohuang.service.InteractionService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/cards")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class InteractionController {

    private final InteractionService service;

    /**
     * 发送互动卡片
     * POST /api/cards
     */
    @PostMapping
    public ResponseEntity<InteractionCard> sendCard(@RequestBody Map<String, String> request) {
        String senderRole = request.get("senderRole");
        String cardType = request.get("cardType");
        String title = request.get("title");
        String icon = request.get("icon");
        String message = request.getOrDefault("message", "");

        InteractionCard card = service.sendCard(senderRole, cardType, title, icon, message);
        return ResponseEntity.ok(card);
    }

    /**
     * 获取收到的卡片
     * GET /api/cards/{receiverRole}
     */
    @GetMapping("/{receiverRole}")
    public ResponseEntity<List<InteractionCard>> getReceivedCards(@PathVariable String receiverRole) {
        List<InteractionCard> cards = service.getReceivedCards(receiverRole);
        return ResponseEntity.ok(cards);
    }

    /**
     * 获取未读卡片
     * GET /api/cards/{receiverRole}/unread
     */
    @GetMapping("/{receiverRole}/unread")
    public ResponseEntity<List<InteractionCard>> getUnreadCards(@PathVariable String receiverRole) {
        List<InteractionCard> cards = service.getUnreadCards(receiverRole);
        return ResponseEntity.ok(cards);
    }

    /**
     * 获取未读数量
     * GET /api/cards/{receiverRole}/unread-count
     */
    @GetMapping("/{receiverRole}/unread-count")
    public ResponseEntity<Map<String, Long>> getUnreadCount(@PathVariable String receiverRole) {
        long count = service.getUnreadCount(receiverRole);
        return ResponseEntity.ok(Map.of("count", count));
    }

    /**
     * 标记卡片已读
     * PUT /api/cards/{cardId}/read
     */
    @PutMapping("/{cardId}/read")
    public ResponseEntity<InteractionCard> markAsRead(@PathVariable String cardId) {
        InteractionCard card = service.markAsRead(cardId);
        if (card != null) {
            return ResponseEntity.ok(card);
        }
        return ResponseEntity.notFound().build();
    }

    /**
     * 标记所有卡片已读
     * PUT /api/cards/{receiverRole}/read-all
     */
    @PutMapping("/{receiverRole}/read-all")
    public ResponseEntity<Void> markAllAsRead(@PathVariable String receiverRole) {
        service.markAllAsRead(receiverRole);
        return ResponseEntity.ok().build();
    }
}
