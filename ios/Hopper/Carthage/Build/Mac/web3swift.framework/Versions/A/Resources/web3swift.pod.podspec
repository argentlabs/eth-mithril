Pod::Spec.new do |spec|
    spec.name         = 'web3swift.pod'
    spec.version      = '2.1.10'
    spec.ios.deployment_target = "8.0"
    spec.osx.deployment_target = "10.10"
    spec.tvos.deployment_target = "9.0"
    spec.watchos.deployment_target = "2.0"
    spec.license      = { :type => 'Apache License 2.0', :file => 'LICENSE.md' }
    spec.summary      = 'Web3 implementation in pure Swift for iOS, macOS, tvOS, watchOS and Linux'
    spec.homepage     = 'https://github.com/bankex/web3swift'
    spec.author       = 'Bankex Foundation'
    spec.source       = { :git => 'https://github.com/bankex/web3swift.git', :tag => spec.version }
    spec.source_files = 'Sources/web3swift/**/*.swift'
    spec.swift_version = '4.2'
    spec.module_name = 'web3swift'
    spec.dependency 'PromiseKit', '~> 6.4'
    spec.dependency 'BigInt', '~> 3.1'
    spec.dependency 'secp256k1.c', '~> 0.1'
    spec.dependency 'keccak.c', '~> 0.1'
    spec.dependency 'scrypt.c', '~> 0.1'
end
