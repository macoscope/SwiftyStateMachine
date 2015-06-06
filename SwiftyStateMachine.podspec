Pod::Spec.new do |s|
  s.name         = "SwiftyStateMachine"
  s.version      = "0.2.0"
  s.summary      = "A Swift µframework for creating finite-state machines, designed for clarity and maintainability."
  s.homepage     = "https://github.com/macoscope/SwiftyStateMachine"
  s.license      = "MIT"
  s.author             = { "Maciej Konieczny" => "hello@narf.pl" }
  s.social_media_url   = "https://twitter.com/narfdotpl"
  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.9"
  s.source       = { :git => "https://github.com/macoscope/SwiftyStateMachine.git", :tag => "#{s.version}" }
  s.source_files = "StateMachine/*.swift"
  s.requires_arc = true
end
