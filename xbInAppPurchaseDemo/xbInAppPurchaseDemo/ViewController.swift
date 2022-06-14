//
//  ViewController.swift
//  xbInAppPurchaseDemo
//
//  Created by huadong on 2022/6/1.
//

import UIKit
import StoreKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
        let btn = UIButton(frame: CGRect(x: 50, y: 100, width: self.view.bounds.width - 100, height: 50.0))
        btn.setTitle("Apple Pay Start", for: .normal)
        btn.backgroundColor = UIColor.orange
        btn.addTarget(self, action: #selector(applePayAction(sender:)), for: .touchUpInside)
        self.view.addSubview(btn)
    }
    
    @objc func applePayAction(sender: UIButton) {
        
        let productId = ""
        if productId.count == 0 {
            debugPrint("--- 请添加要支付的内购商品ID ---")
            return
        }
        
        xbInAppPurchase.shared.applePayRequest(withProductId: productId, delegate: self, isDistribute: false)
    }


}

extension ViewController: xbInAppPurchaseDelegate {
    func updated(withTrans: SKPaymentTransaction, state: SKPaymentTransactionState) {
        
    }
    
    
    func serverVerifyReceipt(withTrans: SKPaymentTransaction, receiptStr: String) {
        debugPrint("----- 支付成功后 服务器再次验证 ----")
    }
    
    
    
}
