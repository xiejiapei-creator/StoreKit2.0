//
//  StoreNotification.swift
//  StoreHelper
//
//  Created by 谢佳培 on 2022/6/8.
//

import Foundation

/// StoreHelper异常
public enum StoreException: Error, Equatable {
    case purchaseException
    case purchaseInProgressException
    case transactionVerificationFailed
    
    public func shortDescription() -> String {
        switch self {
            case .purchaseException:                    return "Exception. StoreKit在处理购买时引发异常"
            case .purchaseInProgressException:          return "Exception. 您还不能开始另一次购买，一次已在进行中"
            case .transactionVerificationFailed:        return "Exception. 事务未能通过StoreKit的自动验证"
        }
    }
}

/// StoreHelper发出的信息性日志记录通知
public enum StoreNotification: Error, Equatable {
    
    case configurationNotFound
    case configurationEmpty
    case configurationSuccess
    case configurationFailure
    
    case requestProductsStarted
    case requestProductsSuccess
    case requestProductsFailure
    
    case purchaseUserCannotMakePayments
    case purchaseAlreadyInProgress
    case purchaseInProgress
    case purchaseCancelled
    case purchasePending
    case purchaseSuccess
    case purchaseFailure
    
    case transactionReceived
    case transactionValidationSuccess
    case transactionValidationFailure
    case transactionFailure
    case transactionSuccess
    case transactionRevoked
    case transactionRefundRequested
    case transactionRefundFailed
    
    case consumableSavedInKeychain
    case consumableKeychainError
    
    /// 通知的简短描述
    /// - Returns: 返回通知的简短描述
    public func shortDescription() -> String {
        switch self {
                
            case .configurationNotFound:           return "在主捆绑包中找不到配置文件"
            case .configurationEmpty:              return "配置文件不包含任何产品定义"
            case .configurationSuccess:            return "配置成功"
            case .configurationFailure:            return "配置失败"
                
            case .requestProductsStarted:          return "已开始从应用商店请求产品"
            case .requestProductsSuccess:          return "从应用商店请求产品成功"
            case .requestProductsFailure:          return "从应用商店请求产品失败"
                
            case .purchaseUserCannotMakePayments:  return "购买失败，因为用户无法付款"
            case .purchaseAlreadyInProgress:       return "采购已在进行中"
            case .purchaseInProgress:              return "正在购买"
            case .purchasePending:                 return "正在购买，正在等待授权"
            case .purchaseCancelled:               return "已取消购买"
            case .purchaseSuccess:                 return "购买成功"
            case .purchaseFailure:                 return "购买失败"
                
            case .transactionReceived:             return "收到的交易记录"
            case .transactionValidationSuccess:    return "事务验证成功"
            case .transactionValidationFailure:    return "事务验证失败"
            case .transactionFailure:              return "交易失败"
            case .transactionSuccess:              return "交易成功"
            case .transactionRevoked:              return "交易已被应用商店撤销（退款）"
            case .transactionRefundRequested:      return "已成功请求交易退款"
            case .transactionRefundFailed:         return "交易退款请求失败"
                
            case .consumableSavedInKeychain:       return "成功购买消耗品并保存到钥匙链"
            case .consumableKeychainError:         return "钥匙链错误"
        }
    }
}
