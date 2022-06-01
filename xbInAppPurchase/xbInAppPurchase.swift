//
//  xbInAppPurchase.swift
//  FSCycleSwift
//
//  Created by huadong on 2022/5/30.
//

import UIKit
import StoreKit

public protocol xbInAppPurchaseDelegate: NSObjectProtocol {
    
    /** 服务器验证支付凭证 （ 验证成功后记得结束交易：SKPaymentQueue.default().finishTransaction(transaction)）*/
    func serverVerifyReceipt(withTrans: SKPaymentTransaction, receiptStr: String)
   
}

public final class xbInAppPurchase: NSObject {
    
    /** 单例*/
    static let shared = xbInAppPurchase()
    private override init() {
        // 不要忘记把构造器变成私有
        super.init()
        
        /// 添加 设置支付服务
        addObserver()
    }
    
    /** 外部可设置此参数， 可以是userId，也可以是订单id，跟你自己需要而定*/
    var applicationUsername: String?
    
    /** 当前支付完成后需要验证凭证的交易对象*/
    fileprivate var currentNeedVerifyTrans: SKPaymentTransaction?
    
    /** 是否是发布环境 默认FALSE，默认为测试环境*/
    fileprivate var isDistribute: Bool = false
    
    /** 当前要支付的商品ID*/
    fileprivate var currentProductID: String?

    weak var xbDelegate: xbInAppPurchaseDelegate?
    
    deinit {
        removerObserver()
    }
    
    // 添加内购监听
    func addObserver() {
        SKPaymentQueue.default().add(self)
    }
    
    // 解除内购监听
    func removerObserver() {
        SKPaymentQueue.default().remove(self)
    }
    
    
    /** 判断app是否允许apple pay*/
    func canPayments() -> Bool{
        return SKPaymentQueue.canMakePayments()
    }
    
    // 请求商品 内购商品id 集合
   
    /**
     withProductId: 内购商品id
     isDistribute: 是否是发布环境 默认FALSE，默认为测试环境
     */
    func applePayRequest(withProductId: String, isDistribute: Bool = false){
        currentProductID = withProductId
        self.isDistribute = isDistribute
        
        let productIds = [withProductId]
        let set: Set<String> = Set(productIds)
        let request = SKProductsRequest(productIdentifiers: set)
        request.delegate = self
        request.start()
    }
    
    
    /**
     异步。
     将当前用户的已完成事务添加回待重新完成的队列。 将要求用户进行身份验证。
     观察者将收到 0 个或多个 -paymentQueue:updatedTransactions:，
     然后是 -paymentQueueRestoreCompletedTransactionsFinished:成功
     或 -paymentQueue:restoreCompletedTransactionsFailedWithError: 失败。
     在部分成功的情况下，一些交易可能仍会交付。
     }
     */
    // 恢复购买 恢复之前已完成的内购项目
    func restoreCompletedTransactions() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
   
    /** 获取内购成功后的交易凭证数据*/
    func receiptData() -> NSData? {
        let receiptURL = Bundle.main.appStoreReceiptURL
        var data:NSData? = nil
        if let url = receiptURL {
            data = NSData(contentsOf: url)
        }
        return data
    }
    
    /** 获取内购成功后的交易凭证数据*/
    func receiptString() -> String? {
        let data = receiptData()
        return data?.base64EncodedString(options: .endLineWithLineFeed)
    }
   
}

// MARK: 请求内购商品回调
extension xbInAppPurchase: SKProductsRequestDelegate {
    
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        
        let myProductList = response.products
        if myProductList.count == 0 {
            debugPrint("----------无法获得商品信息，购买失败---------")
            if response.invalidProductIdentifiers.count > 0 {
                debugPrint("========== 无效的id: \(response.invalidProductIdentifiers)")
            }
            return
        }
        debugPrint("产品Product ID: \(myProductList)")
        debugPrint("产品付费数量: \(myProductList.count)")
        
        var requestProduct : SKProduct?
        for  product in myProductList {
            debugPrint("SKProduct 描述信息\(product.description)")
            debugPrint("产品标题:\(product.localizedTitle)")
            debugPrint("产品描述信息:\(product.localizedDescription)")
            debugPrint("价格 描述信息:\(product.price)")
            debugPrint("Product id:\(product.productIdentifier)")
            
            /// 如果后台消费条目的ID与我这里需要请求的一样（用于确保订单的正确性）
            if product.productIdentifier == self.currentProductID {
                requestProduct = product
            }
        }
        /// 发送购买请求
        guard let reqProduct = requestProduct else { return }
        let payment = SKMutablePayment(product: reqProduct)
        payment.quantity = 1
        //可以是userId，也可以是订单id，跟你自己需要而定
        payment.applicationUsername = applicationUsername
        SKPaymentQueue.default().add(payment)
    }
    
    public func requestDidFinish(_ request: SKRequest) {
        if  request.isKind(of: SKProductsRequest.self) {
            debugPrint("内购商品请求成功 request: \(request)")
            
        }else if request.isKind(of: SKReceiptRefreshRequest.self) {
            debugPrint("刷新本地凭证请求成功 request: \(request)")
            // 开始本地内购支付凭证验证
            if let trans = currentNeedVerifyTrans {
                completedHandle(withTrans: trans)
            }
        }
        
    }

    public func request(_ request: SKRequest, didFailWithError error: Error) {
        if  request.isKind(of: SKProductsRequest.self) {
            debugPrint("内购商品请求失败 error: \(error)")
            
        }else if request.isKind(of: SKReceiptRefreshRequest.self) {
            debugPrint("刷新本地凭证请求失败 error: \(error)")
        }
    }
  
}


// MARK: 购买内购商品回调 监听购买结果
extension xbInAppPurchase: SKPaymentTransactionObserver {
    
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        
        for transaction in transactions{
            
            switch transaction.transactionState {
            case .purchasing:   // 正在将事务添加到服务器队列。
                debugPrint("------ updatedTransactions 商品正在添加进列表 purchasing -----")
                break
                
            case .purchased:    // 交易在队列中，用户已付费。 客户应完成交易。
                debugPrint("------ updatedTransactions 交易完成 purchased -----")
                // 交易完成后需要验证处理
                completedHandle(withTrans: transaction)
//                SKPaymentQueue.default().finishTransaction(transaction)
                
                break
                
            case .failed:       // 事务在添加到服务器队列之前被取消或失败。
                debugPrint("------ updatedTransactions 购买失败 failed -----")
                SKPaymentQueue.default().finishTransaction(transaction)
                break
                
            case .restored:     // 交易从用户的购买历史中恢复。 客户应完成交易。
                debugPrint("------ updatedTransactions 恢复购买 - 已经购买过商品 restored ------")
                // 消耗型商品不用写
//                SKPaymentQueue.default().finishTransaction(transaction)
                
                break
                
            case .deferred:     // 事务在队列中，但它的最终状态是等待外部操作。
                debugPrint("------ updatedTransactions 延时支付 deferred -----")
                break
                
            default:
                break
            }
            
        }
    }
    
    // 交易完成后需要验证处理 (也可以使用moya网络请求库来完成验证网络请求 parmeters["receipt-data"] = receiptString)
    func completedHandle(withTrans: SKPaymentTransaction) {
        currentNeedVerifyTrans = withTrans
        
        let receiptURL = Bundle.main.appStoreReceiptURL
        var receiptData:NSData? = nil
        if let url = receiptURL {
            receiptData = NSData(contentsOf: url)
        }
        
        let receiptString = receiptData?.base64EncodedString(options: .endLineWithLineFeed)
        if let receiptStr = receiptString {
            // 自己验证
            selfVerifyReceipt(withTrans: withTrans, receiptStr: receiptStr)
            
        }else{
            // ***** 若获取不到本地凭证，则调取刷新凭证的方法刷新凭证 *****
            let req = SKReceiptRefreshRequest()
            req.delegate = self
            req.start()
        }
    }
    
    
    // 自己到苹果的服务器验证
    func selfVerifyReceipt(withTrans: SKPaymentTransaction, receiptStr: String) {
        //发送POST请求，对购买凭据进行验证
        //测试验证地址：https://sandbox.itunes.apple.com/verifyReceipt
        //正式验证地址：https://buy.itunes.apple.com/verifyReceipt
        
        /**
         
         
         21000 App Store无法读取你提供的JSON数据
         21002 收据数据不符合格式
         21003 收据无法被验证
         21004 你提供的共享密钥和账户的共享密钥不一致
         21005 收据服务器当前不可用
         21006 收据是有效的，但订阅服务已经过期。当收到这个信息时，解码后的收据信息也包含在返回内容中
         21007 收据信息是测试用（sandbox），但却被发送到产品环境中验证
         21008 收据信息是产品环境中使用，但却被发送到测试环境中验证
         }*/
        
        // 是否是正式环境 默认为测试沙盒环境
        var verUrlStr = "https://sandbox.itunes.apple.com/verifyReceipt"
        if isDistribute {
            verUrlStr = "https://buy.itunes.apple.com/verifyReceipt"
        }
        
        // 直接使用字符串拼接一个 JSON 出来，然后请求苹果服务器即可
        let bodyString = String(format: "{\"receipt-data\" : \"%s\"}", receiptStr)
        let bodyData = bodyString.data(using: .utf8)
        
        if let verUrl = URL(string: verUrlStr) {
            var request = URLRequest(url: verUrl)
            request.httpMethod = "POST"
            request.httpBody = bodyData
            
            let config =  URLSessionConfiguration.default
            let session = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue.main)
            
            let task = session.dataTask(with: request) { data , response, error in
                
                if let resultData = data {
                    let resultDic : [String : Any]? = try? JSONSerialization.jsonObject(with: resultData, options: .allowFragments) as? [String : Any]
                
                    let stateInt: Int = (resultDic?["state"] ?? 0) as! Int
                    let environment: String = (resultDic?["environment"] ?? "") as! String
                    debugPrint("---- 内购自验证 环境 ：\(environment)")
                    if stateInt == 0 {
                        // 本地验证成功后
                        debugPrint("---- 本地验证成功 ---")
                        // 进行公司服务器再次验证 成功后完成交易 SKPaymentQueue.default().finishTransaction(transaction)
                        self.serverVerifyReceipt(withTrans: withTrans, receiptStr: receiptStr)
                        
                    }else{
                        // 本地验证失败 结束交易
                        debugPrint("---- 本地验证失败 ---")
                        SKPaymentQueue.default().finishTransaction(withTrans)
                    }
                }
            }
            task.resume()
        }
    }
    
    // 公司的服务器验证
    func serverVerifyReceipt(withTrans: SKPaymentTransaction, receiptStr: String) {

        //获取transaction_id
        //let transaction_id = withTrans.transactionIdentifier;
        //获取product_id
        //let productId = withTrans.payment.productIdentifier
        // 订单号
        let applicationUsername =  withTrans.payment.applicationUsername
        
//        if success {
//            SKPaymentQueue.default().finishTransaction(transaction)
//        }
        
        // 网络请求
        
        xbDelegate?.serverVerifyReceipt(withTrans: withTrans, receiptStr: receiptStr)
        
    }
    
}

extension xbInAppPurchase: URLSessionDelegate {
    
    
}



