//
//  KeychainHelper.swift
//  StoreHelper
//
//  Created by Russell Archer on 09/07/2021.
//

import Foundation
import Security

/// 消耗品id和相关计数值
///
/// 消耗品购买交易在苹果公司看来是暂时的，因此不会存储在App Store收据中
/// KeychainHelper 使用 ConsumableProductId 在密钥链中存储易耗产品ID集
/// 每次购买消耗品时，计数应增加。当购买到期时，计数将递减。当计数为零时，用户不再有权访问产品。
public struct ConsumableProductId: Hashable {
    let productId: ProductId
    let count: Int
}

/// KeychainHelper 提供了在密钥链中使用 ConsumableProductId 集合的一系列方法
public struct KeychainHelper {
    
    /// 将消耗品 ProductId 添加到钥匙链，并将其计数值设置为1
    /// 如果密钥链已经包含 ProductId，则其计数值将递增
    /// - Parameter productId: 计数值将递增的消耗品 ProductId
    /// - Returns: 如果购买已添加或更新，则返回true，否则返回false
    @MainActor public static func purchase(_ productId: ProductId) -> Bool {
        
        if has(productId) { return update(productId, purchase: true) }
        
        // 为要添加到钥匙链的内容创建查询
        let query: [String : Any] = [kSecClass as String  : kSecClassGenericPassword,
                                     kSecAttrAccount as String : productId,
                                     kSecValueData as String : "1".data(using: .utf8)!]
        
        // 将项目添加到钥匙链
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// 递减钥匙链中消耗品 ProductId 的购买计数。如果计数值已为零，则不采取任何操作
    /// - Parameter productId: 计数值将递减的消耗品 ProductId
    /// - Returns: 如果产品已过期（已删除），则返回true，否则返回false
    @MainActor public static func expire(_ productId: ProductId) -> Bool {
        update(productId, purchase: false)
    }
    
    /// 在钥匙链中搜索消耗品 ProductId
    /// - Parameter productId: 要搜索的消耗品 ProductId
    /// - Returns: 如果在钥匙链中找到消耗品的 ProductId ，则返回true，否则返回false
    @MainActor public static func has(_ productId: ProductId) -> Bool {
        
        // 创建要搜索内容的查询。注意，我们不限制搜索（kSecMatchLimitAll）
        let query = [kSecClass as String : kSecClassGenericPassword,
                     kSecAttrAccount as String : productId,
                     kSecMatchLimit as String: kSecMatchLimitOne] as CFDictionary
        
        // 在钥匙链中搜索项目
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query, &item)
        return status == errSecSuccess
    }
    
    /// 给出消费品的购买计数。不适用于非消费品和订阅
    /// - Parameter productId: 消耗品 ProductId
    /// - Returns: 返回计数的值，如果找不到，则返回0
    @MainActor public static func count(for productId: ProductId) -> Int {
        
        // 创建要搜索内容的查询
        let query = [kSecClass as String : kSecClassGenericPassword,
                     kSecAttrAccount as String : productId,
                     kSecMatchLimit as String: kSecMatchLimitOne,
                     kSecReturnAttributes as String: true,
                     kSecReturnData as String: true] as CFDictionary
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query, &item)
        guard status == errSecSuccess else { return 0 }
        
        // 提取计数值数据
        guard let foundItem = item as? [String : Any],
              let countData = foundItem[kSecValueData as String] as? Data,
              let countValue = String(data: countData, encoding: String.Encoding.utf8)
        else { return 0 }
        
        return Int(countValue) ?? 0
    }
    
    /// 更新与钥匙链中的消耗品 ProductId关联的计数值
    /// 如果钥匙链中不存在 ProductId，则会添加它并将其值设置为1
    /// - Parameters:
    ///   - productId: 消耗品 ProductId
    ///   - purchase: 如果已购买耗材，则为true；如果耗材已过期，则为false
    /// - Returns: 如果更新成功，则返回true，否则返回false
    @MainActor public static func update(_ productId: ProductId, purchase: Bool) -> Bool {
        
        if !has(productId) { return KeychainHelper.purchase(productId) }
        
        var count = count(for: productId)
        if count < 0 { count = 0 }
        
        // 创建一个查询，查询我们要在钥匙链中更改的内容
        let query: [String : Any] = [kSecClass as String : kSecClassGenericPassword,
                                     kSecAttrAccount as String : productId,
                                     kSecValueData as String : String(count).data(using: String.Encoding.utf8)!]
        
        // 为要进行的更改创建查询
        var newCount = purchase ? count+1 : count-1
        if newCount < 0 { newCount = 0 }
        
        let changes: [String: Any] = [kSecAttrAccount as String : productId,
                                      kSecValueData as String : String(newCount).data(using: String.Encoding.utf8)!]
        
        // 更新项目
        let status = SecItemUpdate(query as CFDictionary, changes as CFDictionary)
        return status == errSecSuccess
    }
    
    /// 搜索存储在钥匙链中的当前用户的所有消耗品ID
    /// - Parameter productIds: 一组 ProductId，用于将钥匙链中的条目与可用产品相匹配
    /// - Returns: 为存储在密钥链中的所有产品ID返回一组 ConsumableProductId
    @MainActor public static func all(productIds: Set<ProductId>) -> Set<ConsumableProductId>? {
        
        // 创建要搜索内容的查询。注意，我们不限制搜索（kSecMatchLimitAll）
        let query = [kSecClass as String : kSecClassGenericPassword,
                     kSecMatchLimit as String: kSecMatchLimitAll,
                     kSecReturnAttributes as String: true,
                     kSecReturnData as String: true] as CFDictionary
        
        // 在钥匙链中搜索此应用程序创建的所有项目
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query, &item)
        guard status == errSecSuccess else { return nil }
        
        // 变量是一个字典数组
        guard let entries = item as? [[String : Any]] else { return nil }
        
        var foundProducts = Set<ConsumableProductId>()
        for entry in entries {
            if  let pid = entry[kSecAttrAccount as String] as? String,
                productIds.contains(pid),
                let data = entry[kSecValueData as String] as? Data,
                let sValue = String(data: data, encoding: String.Encoding.utf8),
                let value = Int(sValue) {
                foundProducts.insert(ConsumableProductId(productId: pid, count: value))
            }
        }
        
        return foundProducts.count > 0 ? foundProducts : nil
    }
    
    /// 从钥匙链中删除 ProductId
    /// - Parameter productId: 要删除的ProductId
    /// - Returns: 如果删除了ProductId，则返回true，否则返回false
    @MainActor public static func delete(_ consumableProduct: ConsumableProductId) -> Bool {
        
        // 创建一个查询，查询我们要在密钥链中更改的内容
        let query: [String : Any] = [kSecClass as String : kSecClassGenericPassword,
                                     kSecAttrAccount as String : consumableProduct.productId,
                                     kSecValueData as String : String(consumableProduct.count).data(using: String.Encoding.utf8) as Any]
        
        // 在钥匙链中搜索项目
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
    
    /// 删除钥匙链中与消耗品采购相关的所有 ProductId 条目
    /// 应为返回的每个产品id更新已购买产品id的StoreHelper集合
    /// 比如, Task.init { await updatePurchasedIdentifiers(productId, insert: false) }.
    /// - Parameter consumableProductIds: 消耗品 ProductId的数组
    /// - Returns: 返回已从密钥链中删除的 ProductId 数组
    @MainActor public static func resetKeychainConsumables(for consumableProductIds: [ProductId]) -> [ProductId]? {
        
        guard let cids = KeychainHelper.all(productIds: Set(consumableProductIds)) else { return nil }
        var deletedPids = [ProductId]()
        cids.forEach { cid in
            if KeychainHelper.delete(cid) { deletedPids.append(cid.productId) }
        }
        
        return deletedPids.count > 0 ? deletedPids : nil
    }
}

