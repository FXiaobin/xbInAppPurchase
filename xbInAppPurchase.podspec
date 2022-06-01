
Pod::Spec.new do |spec|


  spec.name         = "xbInAppPurchase"
  spec.version      = "0.0.1"
  spec.summary      = "xbInAppPurchase."
  spec.description  = "苹果内购封装，xbInAppPurchase"

  spec.license      = "MIT"
  spec.swift_version = "5.0"

  spec.platform     = :ios
  spec.platform     = :ios, "9.0"
  # spec.ios.deployment_target = "5.0"

  spec.author             = { "FXiaobin" => "527256662@qq.com" }
  spec.homepage     = "https://github.com/FXiaobin/xbInAppPurchase"
  spec.source       = { :git => "https://github.com/FXiaobin/xbInAppPurchase.git", :tag => "#{spec.version}" }

  spec.source_files  = "xbInAppPurchase", "xbInAppPurchase/*.{swift}"

  spec.requires_arc = true


end
