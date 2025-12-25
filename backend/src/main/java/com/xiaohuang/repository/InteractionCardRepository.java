package com.xiaohuang.repository;

import com.xiaohuang.model.InteractionCard;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface InteractionCardRepository extends MongoRepository<InteractionCard, String> {

    /** 查找某角色收到的所有卡片 */
    List<InteractionCard> findByReceiverRoleOrderByTimestampDesc(String receiverRole);

    /** 查找某角色收到的未读卡片 */
    List<InteractionCard> findByReceiverRoleAndIsReadFalseOrderByTimestampDesc(String receiverRole);

    /** 统计未读卡片数量 */
    long countByReceiverRoleAndIsReadFalse(String receiverRole);
}
