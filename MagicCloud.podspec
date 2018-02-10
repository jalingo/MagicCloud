
Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.name         = "MagicCloud"
  s.version      = "2.2.1"
  s.summary      = "A CloudKit framework that makes database interactions a breeze."

s.description  = <<-DESC
The MagicCloud framework makes using CloudKit simple and easy, and has been used in iOS Apps that have been approved by Apple's App Store submission process.

Any data types that need to be saved as database records conform to the MCRecordable prototype. Generic MCReceiver classes maintain a local repository for your app to access, and mirrors that to CloudKit databases for you.

Default setup covers error handling, subscriptions, account changes and more. Can be configured / customized for optimized performance.

Checkout escapeChaos.com/MagicCloud for how-to videos and documentation.
                   DESC

  s.homepage     = "https://github.com/jalingo/MagicCloud"

  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.license      = { :type => "BSD-new", :file => "LICENSE" }

  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.author             = { "JA Lingo" => "James@EscapeChaos.com" }
#  s.social_media_url   = "https://www.linkedin.com/in/jalingo"

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.platform     = :ios, "10.0"

  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.source       = { :git => "https://github.com/jalingo/MagicCloud.git", :tag => "#{s.version}" }

  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.source_files  = "MagicCloud", "MagicCloud/**/*.{h,m}"

  # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  # s.resources = "*.png"

  # ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.frameworks = "CloudKit", "UIKit"

  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.requires_arc = true
  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '4' }

end
