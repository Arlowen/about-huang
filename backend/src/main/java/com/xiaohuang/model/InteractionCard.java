package com.xiaohuang.model;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import java.time.LocalDateTime;

/**
 * 互动卡片实体
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "interaction_cards")
public class InteractionCard {

    @Id
    private String id;

    /** 发送者角色: xiaoHuang / xiaoZhang */
    private String senderRole;

    /** 接收者角色: xiaoHuang / xiaoZhang */
    private String receiverRole;

    /** 卡片类型: drink, hug, miss, food 等 */
    private String cardType;

    /** 卡片标题 */
    private String title;

    /** 卡片图标 (SF Symbol name) */
    private String icon;

    /** 附加消息 */
    private String message;

    /** 发送时间 */
    private LocalDateTime timestamp;

    /** 是否已读 */
    private Boolean isRead;

    public InteractionCard(String senderRole, String cardType, String title, String icon) {
        this.senderRole = senderRole;
        this.receiverRole = senderRole.equals("xiaoHuang") ? "xiaoZhang" : "xiaoHuang";
        this.cardType = cardType;
        this.title = title;
        this.icon = icon;
        this.timestamp = LocalDateTime.now();
        this.isRead = false;
    }
}
