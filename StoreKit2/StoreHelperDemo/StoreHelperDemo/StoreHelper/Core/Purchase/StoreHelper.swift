//
//  StoreHelper.swift
//  StoreHelper
//
//  Created by 谢佳培 on 2022/6/8.
//

import StoreKit
import Collections

public typealias ProductId = String

/// 购买的状态
public enum PurchaseState { case notStarted, userCannotMakePayments, inProgress, purchased, pending, cancelled, failed, failedVerification, unknown }

/// 有关展开事务 VerificationResult 的结果的信息
@available(tvOS 15.0, *)
public struct UnwrappedVerificationResult<T> {
    /// 已验证或未验证的交易
    let transaction: T
    
    /// 如果StoreKit成功验证了事务，则为True
    let verified: Bool
    
    /// 如果 verified 为 false，则 verificationError 将保留验证错误，否则为零
    let verificationError: VerificationResult<T>.VerificationError?
}

/// StoreHelper 封装了 StoreKit2 的应用程序内购买功能，使其易于使用应用程序商店
@available(tvOS 15.0, *)
public class StoreHelper: ObservableObject {
    
    // MARK: - 公共财产
    
    /// 从应用商店检索到的可供购买的 Product 数组
    @Published public private(set) var products: [Product]?
    

    /// 已购买产品的ProductId数组。每个购买的非消耗性产品将只出现一次。消耗品可能出现多次。
    /// 此数组主要用于触发UI中的更新。当购买成功完成时，或当调用“isPurchased（product:）”时，它不会持久化，而是根据需要重新构建。
    ///
    /// 调用 isPurchased（product:）来查看是否购买了任何类型的产品并根据收据进行了验证
    /// 调用 StoreHelper.count(for:) 来查看可消耗品的购买次数
    @Published public private(set) var purchasedProducts = [ProductId]()
    
    /// 购买了的产品ID列表。当应用商店不可用时，此列表用作回退
    /// 当 products 为 nil 且 isAppStoreAvailable 为 false 时，调用 isPurchased（product:）方法将使用此列表
    public var purchasedProductsFallback = [ProductId]()
    
    /// 如果我们成功从应用商店检索可用产品列表，则设置为true
    public private(set) var isAppStoreAvailable = false
    
    /// 已从 Product.plist 配置文件中读取的 ProductId 的 OrderedSet
    /// 在属性列表文件中定义产品ID的顺序在集合中保持不变
    public private(set) var productIds: OrderedSet<ProductId>?
    
    /// 与订阅相关的助手方法
    public var subscriptionHelper: SubscriptionHelper!
    
    /// 如果StoreHelper已通过调用start（）正确初始化，则为True
    public var hasStarted: Bool { transactionListener != nil && isAppStoreAvailable }
    
    /// 替代动态字体大小的可选支持
    public var fontScaleFactor: Double {
        get { _fontScaleFactor ?? FontUtil.baseDynamicTypeSize(for: .large)}
        set { _fontScaleFactor = newValue }
    }
    
    /// 可选插件配置提供程序，用于覆盖配置的默认值。
    public var configurationProvider: ConfigurationProvider?
    
    // MARK: - 公共助手属性
    
    public var consumableProducts:            [Product]?   { products?.filter { $0.type == .consumable }}
    public var nonConsumableProducts:         [Product]?   { products?.filter { $0.type == .nonConsumable }}
    public var subscriptionProducts:          [Product]?   { products?.filter { $0.type == .autoRenewable }}
    public var nonSubscriptionProducts:       [Product]?   { products?.filter { $0.type == .nonRenewable }}
    public var consumableProductIds:          [ProductId]? { products?.filter { $0.type == .consumable }.map { $0.id }}
    public var nonConsumableProductIds:       [ProductId]? { products?.filter { $0.type == .nonConsumable }.map { $0.id }}
    public var subscriptionProductIds:        [ProductId]? { products?.filter { $0.type == .autoRenewable }.map { $0.id }}
    public var nonSubscriptionProductIds:     [ProductId]? { products?.filter { $0.type == .nonRenewable }.map { $0.id }}
    public var hasProducts:                   Bool         { products?.count ?? 0 > 0 ? true : false }
    public var hasConsumableProducts:         Bool         { consumableProducts?.count ?? 0 > 0 ? true : false }
    public var hasNonConsumableProducts:      Bool         { nonConsumableProducts?.count ?? 0 > 0 ? true : false }
    public var hasSubscriptionProducts:       Bool         { subscriptionProducts?.count ?? 0 > 0 ? true : false }
    public var hasNonSubscriptionProducts:    Bool         { nonSubscriptionProducts?.count ?? 0 > 0 ? true : false }
    public var hasConsumableProductIds:       Bool         { consumableProductIds?.count ?? 0 > 0 ? true : false }
    public var hasNonConsumableProductIds:    Bool         { nonConsumableProductIds?.count ?? 0 > 0 ? true : false }
    public var hasSubscriptionProductIds:     Bool         { subscriptionProductIds?.count ?? 0 > 0 ? true : false }
    public var hasNonSubscriptionProductIds:  Bool         { nonSubscriptionProducts?.count ?? 0 > 0 ? true : false }

    // MARK: - 私有属性
    
    /// 应用商店交易的监听器
    private var transactionListener: Task<Void, Error>? = nil
    
    /// StoreHelper的当前内部状态
    /// 如果purchaseState==inProgress，则尝试开始新购买将导致purchaseInProgressException被purchase(_:)引发
    private var purchaseState: PurchaseState = .unknown
    
    /// 支持App Store IAP 促销和 StoreKit1，仅用于直接从 App Store 购买 IAP
    private var appStoreHelper: AppStoreHelper?
    
    /// 支持覆盖动态字体比例
    private var _fontScaleFactor: Double? = nil
    
    // MARK: - 初始化
    
    /// StoreHelper 支持使用异步/等待模式处理应用内购买和 StoreKit2
    /// 此初始值设定项将开始支持从app store直接购买（IAP促销），并读取Products.plist配置文件以获取ProductId列表
    /// 该列表定义了我们将从应用商店请求的产品集
    /// 你的应用程序必须调用 StoreHelper.start（）在StoreHelper初始化后尽快启动
    public init() {
        
        // 为应用商店中基于StoreKit1的直接购买添加助手（IAP促销）
        appStoreHelper = AppStoreHelper(storeHelper: self)
        
        // 初始化订阅助手
        subscriptionHelper = SubscriptionHelper(storeHelper: self)
        
        // 读取我们的产品ID列表
        productIds = StoreConfiguration.readConfigFile()
        
        // 获取已购买产品的备用列表，以防应用商店不可用
        purchasedProductsFallback = readPurchasedProductsFallbackList()
    }
    
    deinit { transactionListener?.cancel() }
    
    // MARK: - 公共方法
    
    /// 在应用程序启动和StoreHelper初始化后，尽快调用此方法
    /// 未能调用 start（）可能会导致丢失事务
    /// 此方法开始侦听应用商店事务，并从应用商店请求本地化的产品信息
    @MainActor public func start() {
        guard !hasStarted else { return }
        
        // 侦听应用商店事务
        transactionListener = handleTransactions()
        
        // 从应用商店获取本地化产品信息
        refreshProductsFromAppStore()
    }
    
    /// 从应用商店请求刷新的本地化产品信息
    /// 通常，请优先使用此方法而不是 requestProductsFromAppStore（ProductId:）
    /// 因为您不需要提供一组有序的App Store定义的产品ID
    /// 此方法在主线程上运行，因为它可能会导致UI更新
    @MainActor public func refreshProductsFromAppStore() {
        Task.init {
            isAppStoreAvailable = false
            guard let pids = productIds else { return }
            products = await requestProductsFromAppStore(productIds: pids)
        }
    }
    
    /// 从应用商店请求本地化产品信息以获取一组ProductId
    ///
    /// 此方法在主线程上运行，因为它可能会导致UI更新
    /// - Parameter productIds: 需要本地化信息的产品ID
    /// - Returns: 返回 Product 数组，如果应用商店未返回任何产品信息，则返回nil
    @MainActor public func requestProductsFromAppStore(productIds: OrderedSet<ProductId>) async -> [Product]? {
        StoreLog.event(.requestProductsStarted)
        guard let localizedProducts = try? await Product.products(for: productIds) else {
            isAppStoreAvailable = false
            StoreLog.event(.requestProductsFailure)
            return nil
        }
        
        isAppStoreAvailable = true
        StoreLog.event(.requestProductsSuccess)
        return localizedProducts
    }
    
    /// 从App Store请求产品的最新交易，并确定之前是否购买过该产品
    ///
    /// 可能引发异常类型：StoreException.transactionVerificationFailed
    /// - Parameter productId: 产品的 ProductId
    /// - Returns: 如果产品已购买，则返回true，否则返回false
    @MainActor public func isPurchased(productId: ProductId) async throws -> Bool {
        
        var purchased = false
        
        guard hasStarted else {
            StoreLog.event("Please call StoreHelper.start() before use.")
            return false
        }
        
        guard isAppStoreAvailable, hasProducts else {
            // 应用商店不可用，或未返回本地化产品列表
            // 因此，我们使用采购产品的临时后备列表
            return purchasedProductsFallback.contains(productId)
        }
        
        guard let product = product(from: productId) else {
            updatePurchasedProductsFallbackList(for: productId, purchased: false)
            AppGroupSupport.syncPurchase(configProvider: self.configurationProvider, productId: productId, purchased: false)
            return false
        }
        
        // 我们需要区别对待消耗品，因为它们的交易记录没有存储在收据中
        if product.type == .consumable {
            purchased = KeychainHelper.count(for: productId) > 0
            await updatePurchasedIdentifiers(productId, insert: purchased)
            updatePurchasedProductsFallbackList(for: productId, purchased: purchased)
            AppGroupSupport.syncPurchase(configProvider: self.configurationProvider, productId: productId, purchased: purchased)
            return purchased
        }
        
        guard let currentEntitlement = await Transaction.currentEntitlement(for: productId) else {
            // 该产品没有交易，因此尚未购买
            AppGroupSupport.syncPurchase(configProvider: self.configurationProvider, productId: productId, purchased: false)
            updatePurchasedProductsFallbackList(for: productId, purchased: false)
            return false
        }
        
        // 查看事务是否通过了 StoreKit 的自动验证
        let result = checkVerificationResult(result: currentEntitlement)
        if !result.verified {
            StoreLog.transaction(.transactionValidationFailure, productId: result.transaction.productID)
            throw StoreException.transactionVerificationFailed
        }
        
        // 确保我们的内部购买Pid集与App Store同步
        await updatePurchasedIdentifiers(result.transaction)
        
        // 查看应用商店是否撤销了用户对产品的访问权限（例如，因为退款）
        // 如果此事务表示订阅，请查看用户是否升级到更高级别的订阅
        purchased = result.transaction.revocationDate == nil && !result.transaction.isUpgraded
        
        // U更新我们与组中其他成员共享的容器中的UserDefault： group.com.{developer}.{appname} AppGroup.
        // 目前，这样做是为了让widget可以知道购买了哪些iap。请注意，小部件不能直接使用StoreHelper
        // 因为就StoreKit而言，他们不购买任何东西，也不被认为是进行购买的应用程序的一部分
        AppGroupSupport.syncPurchase(configProvider: self.configurationProvider, productId: product.id, purchased: purchased)
        
        // 更新并保存我们的采购产品后备列表
        updatePurchasedProductsFallbackList(for: productId, purchased: purchased)
        
        return purchased
    }
    
    /// 从App Store请求产品的最新交易，并确定之前是否购买过该产品
    ///
    /// 可能引发异常类型：StoreException.transactionVerificationFailed
    /// - Parameter productId: 产品的 ProductId
    /// - Returns: 如果产品已购买，则返回true，否则返回false
    @MainActor public func isPurchased(product: Product) async throws -> Bool {
        
        return try await isPurchased(productId: product.id)
    }
    
    /// 使用StoreKit的 Transaction.currentEntitlements 属性来迭代 VerificationResult<Transaction>
    /// 表示用户当前有权使用的产品的所有交易，也就是说，所有当前订阅的交易以及所有购买（且未退款）的非消耗品
    /// 请注意，易耗品交易记录不在收据中
    /// - Returns: 用户有权访问的所有已验证的产品 Set<ProductId> 如果用户之前没有购买任何东西，则集合将为空
    @MainActor public func currentEntitlements() async -> Set<ProductId> {
        
        var entitledProductIds = Set<ProductId>()
        
        for await result in Transaction.currentEntitlements {
            
            if case .verified(let transaction) = result {
                entitledProductIds.insert(transaction.productID)  // 忽略未验证的交易
            }
        }
        
        return entitledProductIds
    }
    
    /// 购买之前调用requestProductsFromAppStore（）后从应用商店返回的产品
    ///
    /// 可能引发以下类型的异常：
    /// - StoreException.purchaseException：如果应用商店本身引发异常
    /// - StoreException.purchaseInProgressException：如果采购已经在进行中
    /// - StoreException.transactionVerificationFailed：如果采购交易记录验证失败
    ///
    /// - Parameter product: 要购买的产品
    /// - Parameter options: 购买选项. 参见 Product.PurchaseOption.
    /// - Returns: 返回一个元组，该元组由表示购买的交易事务对象和购买状态组成
    @MainActor public func purchase(_ product: Product, options: Set<Product.PurchaseOption> = []) async throws -> (transaction: Transaction?, purchaseState: PurchaseState)  {
        // 未启动 StoreHelper 来获取产品
        guard hasStarted else {
            StoreLog.event("请在使用前调用 StoreHelper.start() ")
            return (nil, .notStarted)
        }
        
        // 商店不支持购买
        guard AppStore.canMakePayments else {
            StoreLog.event(.purchaseUserCannotMakePayments)
            return (nil, .userCannotMakePayments)
        }
        
        // 已经处于购买流程之中
        guard purchaseState != .inProgress else {
            StoreLog.exception(.purchaseInProgressException, productId: product.id)
            throw StoreException.purchaseInProgressException
        }
        
        // 启动采购交易
        purchaseState = .inProgress
        StoreLog.event(.purchaseInProgress, productId: product.id)
        
        // 进行购买
        guard let result = try? await product.purchase(options: options) else {
            // 购买失败
            purchaseState = .failed
            StoreLog.event(.purchaseFailure, productId: product.id)
            throw StoreException.purchaseException
        }
        
        // 每次应用程序从StoreKit 2接收到交易事务时
        // 该交易事务都已通过验证过程以确认此设备的应用程序商店是否为我的应用程序签署了有效负载（payload）
        // 也就是说，Storekit2为您进行事务（收据）验证（不再使用OpenSSL或需要将收据发送到Apple服务器进行验证）
        
        // 我们现在有了PurchaseResult值查看购买是否成功、失败、取消或挂起
        switch result {
            case .success(let verificationResult):
                
                // 这次收购似乎成功了。StoreKit已自动尝试验证事务，并返回包装在VerificationResult中的验证结果
                // 我们现在需要检查VerificationResult<Transaction>以查看事务是否通过了App Store的验证过程，这相当于StoreKit1中的收据验证
                
                // 事务是否通过了StoreKit的自动验证？
                let checkResult = checkVerificationResult(result: verificationResult)
            
                // 交易验证失败
                if !checkResult.verified {
                    purchaseState = .failedVerification
                    StoreLog.transaction(.transactionValidationFailure, productId: checkResult.transaction.productID)
                    throw StoreException.transactionVerificationFailed
                }
                
                // 交易已成功验证
                let validatedTransaction = checkResult.transaction
                
                // 更新已购买id的列表。因为它是一个@ Published var，这将导致显示产品列表的UI更新
                await updatePurchasedIdentifiers(validatedTransaction)
                
                // 告诉应用商店我们已将购买的内容交付给用户
                await validatedTransaction.finish()
                
                // 让调用者知道购买成功，并且应该授予用户对产品的访问权限
                purchaseState = .purchased
                StoreLog.event(.purchaseSuccess, productId: product.id)
                            
                // 我们需要区别对待消耗性商品，因为它们的交易记录没有存储在收据中
                if validatedTransaction.productType == .consumable {
                    if KeychainHelper.purchase(product.id) { await updatePurchasedIdentifiers(product.id, insert: true) }
                    else { StoreLog.event(.consumableKeychainError) }
                }
                
            // 更新我们与组中其他成员共享的容器中的UserDefault。group.com.{developer}.{appname} AppGroup
            // 目前，这样做是为了让widget可以知道购买了哪些iap
            // 请注意，小部件不能直接使用StoreHelper，因为它们不购买任何东西，并且就StoreKit而言，它们不被视为进行购买的应用程序的一部分
                AppGroupSupport.syncPurchase(configProvider: self.configurationProvider, productId: product.id, purchased: true)
                
                return (transaction: validatedTransaction, purchaseState: .purchased)
                
            case .userCancelled:// 用户取消交易
                purchaseState = .cancelled
                StoreLog.event(.purchaseCancelled, productId: product.id)
                return (transaction: nil, .cancelled)
                
            case .pending:// 交易挂起
                purchaseState = .pending
                StoreLog.event(.purchasePending, productId: product.id)
                return (transaction: nil, .pending)
                
            default:
                purchaseState = .unknown
                StoreLog.event(.purchaseFailure, productId: product.id)
                return (transaction: nil, .unknown)
        }
    }
    
    /// 应仅在由基于StoreKit1的AppHelper处理购买时调用
    /// 这将是由于用户直接在应用商店的IAP中购买（IAP促销），而不是在我们的应用中购买
    /// - Parameter product: 所购买产品的ProductId
    @MainActor public func productPurchased(_ productId: ProductId)  {
        
        Task.init { await updatePurchasedIdentifiers(productId, insert: true)}
        purchaseState = .purchased
        StoreLog.event(.purchaseSuccess, productId: productId)
        AppGroupSupport.syncPurchase(configProvider: self.configurationProvider, productId: productId, purchased: true)
    }
    
    /// 与 ProductId 关联的“Product
    /// - Parameter productId: ProductId
    /// - Returns: 返回与ProductId关联的Product
    public func product(from productId: ProductId) -> Product? {
        
        guard let p = products else { return nil }
        
        let matchingProduct = p.filter { product in
            product.id == productId
        }
        
        guard matchingProduct.count == 1 else { return nil }
        return matchingProduct.first
    }
    
    /// 非消耗品信息
    /// - Parameter productId: 产品的 ProductId
    /// - Returns: 非消耗品信息
    /// 如果产品不是非消耗品，则返回nil
    @MainActor public func purchaseInfo(for productId: ProductId) async -> PurchaseInfo? {
        
        guard let p = product(from: productId) else { return nil }
        return await purchaseInfo(for: p)
    }
    
    /// 非消耗性产品的交易信息
    /// - Parameter product: 您想要了解的产品
    /// - Returns: 非消耗性产品的交易信息
    /// 如果产品不是非消耗品，则退回零
    @MainActor public func purchaseInfo(for product: Product) async -> PurchaseInfo? {
        
        guard product.type == .nonConsumable else { return nil }
        
        var purchaseInfo = PurchaseInfo(product: product)
        // 如果没有，则从未购买过产品
        guard let unverifiedTransaction = await product.latestTransaction else { return nil }
        
        let transactionResult = checkVerificationResult(result: unverifiedTransaction)
        guard transactionResult.verified else { return nil }
        
        purchaseInfo.latestVerifiedTransaction = transactionResult.transaction
        return purchaseInfo
    }
    
    /// 在订阅组中有关用户订阅的最高服务级别自动续订订阅的信息
    /// - Parameter subscriptionGroup: 订阅组的名称
    /// - Returns: 有关用户在 subscriptionGroup 中订阅的最高服务级别自动续订订阅的信息
    @MainActor public func subscriptionInfo(for subscriptionGroup: String) async -> SubscriptionInfo? {
        
        // 获取订阅组中所有产品的产品ID
        // 获取第一个id并将其转换为产品，以便我们可以访问组公共订阅状态数组
        guard let groupProductIds = subscriptionHelper.subscriptions(in: subscriptionGroup),
              let groupProductId = groupProductIds.first,
              let product = product(from: groupProductId),
              let subscription = product.subscription,
              let statusCollection = try? await subscription.status else { return nil }
        
        var subscriptionInfo = SubscriptionInfo()
        var highestServiceLevel: Int = -1
        var highestValueProduct: Product?
        var highestValueTransaction: Transaction?
        var highestValueStatus: Product.SubscriptionInfo.Status?
        var highestRenewalInfo: Product.SubscriptionInfo.RenewalInfo?
        
        for status in statusCollection {
            
            // 如果用户尚未订阅此产品，请继续查找
            guard status.state == .subscribed else { continue }
            
            // 检查交易验证
            let statusTransactionResult = checkVerificationResult(result: status.transaction)
            guard statusTransactionResult.verified else { continue }
            
            // 检查续订信息验证
            let renewalInfoResult = checkVerificationResult(result: status.renewalInfo)
            guard renewalInfoResult.verified else { continue }  // Subscription not verified by StoreKit so ignore it
            
            // 确保此产品与我们正在搜索的产品来自同一订阅组
            let currentGroup = subscriptionHelper.groupName(from: renewalInfoResult.transaction.currentProductID)
            guard currentGroup == subscriptionGroup else { continue }
            
            // 获取此订阅的产品
            guard let candidateSubscription = self.product(from: renewalInfoResult.transaction.currentProductID) else { continue }
            
            // 我们在目标订阅组中找到了产品的有效交易
            // 这是我们迄今为止遇到的最高服务级别吗？
            let currentServiceLevel = subscriptionHelper.subscriptionServiceLevel(in: subscriptionGroup, for: renewalInfoResult.transaction.currentProductID)
            if currentServiceLevel > highestServiceLevel {
                highestServiceLevel = currentServiceLevel
                highestValueProduct = candidateSubscription
                highestValueTransaction = statusTransactionResult.transaction
                highestValueStatus = status
                highestRenewalInfo = renewalInfoResult.transaction
            }
        }
        
        guard let selectedProduct = highestValueProduct, let selectedStatus = highestValueStatus else { return nil }
        
        subscriptionInfo.product = selectedProduct
        subscriptionInfo.subscriptionGroup = subscriptionGroup
        subscriptionInfo.latestVerifiedTransaction = highestValueTransaction
        subscriptionInfo.verifiedSubscriptionRenewalInfo = highestRenewalInfo
        subscriptionInfo.subscriptionStatus = selectedStatus
        
        return subscriptionInfo
    }
    
    /// 检查StoreKit是否能够通过检查验证结果自动验证交易
    ///
    /// - Parameter result: 要检查的交易验证结果
    /// - Returns: 返回 UnwrappedVerificationResult<T> 如果StoreKit成功验证了交易，则 verified 为 true，当 verified 为false时，verificationError将为非nil
    @MainActor public func checkVerificationResult<T>(result: VerificationResult<T>) -> UnwrappedVerificationResult<T> {
        
        switch result {
            case .unverified(let unverifiedTransaction, let error):
                // StoreKit无法自动验证交易
                return UnwrappedVerificationResult(transaction: unverifiedTransaction, verified: false, verificationError: error)
                
            case .verified(let verifiedTransaction):
                // StoreKit已成功自动验证交易
                return UnwrappedVerificationResult(transaction: verifiedTransaction, verified: true, verificationError: nil)
        }
    }
    
    /// 获取产品最新交易的唯一交易id
    /// - Parameter productId: 产品的唯一应用商店id
    /// - Returns: 返回产品最近交易的唯一交易id，如果从未购买过产品，则返回nil
    @MainActor public func mostRecentTransactionId(for productId: ProductId) async -> UInt64? {
        if let result = await Transaction.latest(for: productId) {
            let verificationResult = checkVerificationResult(result: result)
            if verificationResult.verified { return verificationResult.transaction.id }
        }
        
        return nil
    }
    
    /// 获取产品的最新事务
    /// - Parameter productId: 产品的唯一应用商店id
    /// - Returns: 返回产品的最新交易，如果从未购买过产品，则返回nil
    @MainActor public func mostRecentTransaction(for productId: ProductId) async -> Transaction? {
        if let result = await Transaction.latest(for: productId) {
            let verificationResult = checkVerificationResult(result: result)
            if verificationResult.verified { return verificationResult.transaction }
        }
        
        return nil
    }
    
    // MARK: - 内部方法
    
    /// 更新我们购买的产品标识符列表
    ///
    /// 此方法在主线程上运行，因为它将导致UI的更新
    /// - Parameter transaction: 将导致 purchasedProducts 更改的 Transaction
    @MainActor internal func updatePurchasedIdentifiers(_ transaction: Transaction) async {
        
        if transaction.revocationDate == nil {
            
            // 应用商店尚未撤销该交易，因此已购买该产品
            // 将ProductId添加到purchasedProducts列表中（这是一个集合，如果已经存在，则不会添加）
            await updatePurchasedIdentifiers(transaction.productID, insert: true)
            
        } else {
            
            // 应用商店撤销了此交易（例如退款），这意味着用户不应访问该交易
            // 从purchasedProducts列表中删除产品
            await updatePurchasedIdentifiers(transaction.productID, insert: false)
        }
    }
    
    /// 更新我们购买的产品标识符列表
    /// - Parameters:
    ///   - productId: 要插入/删除的 ProductId
    ///   - insert: 如果为true，则插入 ProductId ，否则将删除它
    @MainActor internal func updatePurchasedIdentifiers(_ productId: ProductId, insert: Bool) async {
        
        guard let product = product(from: productId) else { return }
        
        if insert {
            
            if product.type == .consumable {
                
                let count = KeychainHelper.count(for: productId)
                let products = purchasedProducts.filter({ $0 == productId })
                if count == products.count { return }
                
            } else {
                
                if purchasedProducts.contains(productId) { return }
            }
            
            purchasedProducts.append(productId)
            
        } else {
            
            if let index = purchasedProducts.firstIndex(where: { $0 == productId}) {
                purchasedProducts.remove(at: index)
            }
        }
    }
    
    // MARK: - Private methods
    
    /// 这是一个无限异步序列（循环）
    /// 它将继续等待事务，直到通过transactionListener调用cancel（）方法显式取消它为止
    /// - Returns: 返回事务处理循环任务的任务
    @MainActor private func handleTransactions() -> Task<Void, Error> {
        
        return Task.detached {
            
            for await verificationResult in Transaction.updates {
                
                // 查看StoreKit是否验证了事务
                let checkResult = await self.checkVerificationResult(result: verificationResult)
                StoreLog.transaction(.transactionReceived, productId: checkResult.transaction.productID)
                
                if checkResult.verified {
                    
                    let validatedTransaction = checkResult.transaction
                    
                    // 交易已验证，因此请更新用户有权访问的产品列表
                    await self.updatePurchasedIdentifiers(validatedTransaction)
                    await validatedTransaction.finish()
                    
                } else {
                    
                    // StoreKit尝试验证事务失败，不要向用户交付内容
                    StoreLog.transaction(.transactionFailure, productId: checkResult.transaction.productID)
                }
            }
        }
    }
    
    /// 读取从存储区购买的回退产品列表
    /// - Returns: 返回回退产品ID的列表，如果没有可用的，则返回nil
    private func readPurchasedProductsFallbackList() -> [ProductId] {
        if let collection = UserDefaults.standard.object(forKey: StoreConstants.PurchasedProductsFallbackKey) as? [ProductId] {
            return collection
        }
        
        return [ProductId]()
    }
    
    ///保存已购买产品ID的回退集合
    private func savePurchasedProductsFallbackList() {
        UserDefaults.standard.set(purchasedProductsFallback, forKey: StoreConstants.PurchasedProductsFallbackKey)
    }
    
    /// 从回退购买的产品ID列表中添加ProductId，然后将该列表持久化为UserDefaults
    /// - Parameter productId: 要添加的ProductId
    private func addToPurchasedProductsFallbackList(productId: ProductId) {
        if purchasedProductsFallback.contains(productId) { return }
        purchasedProductsFallback.append(productId)
        savePurchasedProductsFallbackList()
    }
    
    /// 从回退购买的产品ID列表中删除ProductId，然后将该列表持久化为UserDefaults
    /// - Parameter productId: 要删除的ProductId
    private func removeFromPurchasedProductsFallbackList(productId: ProductId) {
        purchasedProductsFallback.removeAll(where: { $0 == productId })
        savePurchasedProductsFallbackList()
    }
    
    /// 在回退购买的产品ID列表中添加或删除ProductId，然后将该列表持久化为UserDefaults
    /// - Parameters:
    ///   - productId: 要添加或删除的ProductId
    ///   - purchased: 如果购买了产品，则为true，否则为false
    private func updatePurchasedProductsFallbackList(for productId: ProductId, purchased: Bool) {
        if purchased { addToPurchasedProductsFallbackList(productId: productId)}
        else { removeFromPurchasedProductsFallbackList(productId: productId)}
    }
}





