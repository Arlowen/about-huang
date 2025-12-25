package com.xiaohuang.service;

import com.xiaohuang.model.InteractionCard;
import com.xiaohuang.repository.InteractionCardRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class InteractionService {

    private final InteractionCardRepository repository;

    /**
     * 发送互动卡片
     */
    public InteractionCard sendCard(String senderRole, String cardType, String title, String icon, String message) {
        InteractionCard card = new InteractionCard(senderRole, cardType, title, icon);
        card.setMessage(message);
        card.setTimestamp(LocalDateTime.now());
        return repository.save(card);
    }

    /**
     * 获取收到的卡片
     */
    public List<InteractionCard> getReceivedCards(String receiverRole) {
        return repository.findByReceiverRoleOrderByTimestampDesc(receiverRole);
    }

    /**
     * 获取未读卡片
     */
    public List<InteractionCard> getUnreadCards(String receiverRole) {
        return repository.findByReceiverRoleAndIsReadFalseOrderByTimestampDesc(receiverRole);
    }

    /**
     * 标记卡片已读
     */
    public InteractionCard markAsRead(String cardId) {
        return repository.findById(cardId).map(card -> {
            card.setIsRead(true);
            return repository.save(card);
        }).orElse(null);
    }

    /**
     * 标记所有卡片已读
     */
    public void markAllAsRead(String receiverRole) {
        List<InteractionCard> unreadCards = repository
                .findByReceiverRoleAndIsReadFalseOrderByTimestampDesc(receiverRole);
        unreadCards.forEach(card -> card.setIsRead(true));
        repository.saveAll(unreadCards);
    }

    /**
     * 获取未读数量
     */
    public long getUnreadCount(String receiverRole) {
        return repository.countByReceiverRoleAndIsReadFalse(receiverRole);
    }
}
