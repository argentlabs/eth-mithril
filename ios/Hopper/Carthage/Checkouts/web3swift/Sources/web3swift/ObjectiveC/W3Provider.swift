//
//  W3Provider.swift
//  web3swift
//
//  Created by Dmitry on 11/9/18.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation

extension Web3HttpProvider {
    public var objc: W3Web3HttpProvider {
		return W3Web3HttpProvider(self)
	}
}
@objc public class W3Web3HttpProvider: NSObject, SwiftContainer {
	public let swift: Web3HttpProvider
	public required init(_ swift: Web3HttpProvider) {
		self.swift = swift
	}
	
	@objc public var url: URL {
		get { return swift.url }
		set { swift.url = newValue }
	}
	
	@objc public var network: W3NetworkId? {
		get { return swift.network?.objc }
		set { swift.network = newValue?.swift }
	}
	
	@objc public var attachedKeystoreManager: W3KeystoreManager {
		get { return swift.attachedKeystoreManager.objc }
        set { swift.attachedKeystoreManager = newValue.swift }
	}
	
	@objc public var session: URLSession {
		get { return swift.session }
		set { swift.session = newValue }
	}
	
	@objc public init?(_ httpProviderURL: URL, network net: W3NetworkId? = nil, keystoreManager manager: W3KeystoreManager = W3KeystoreManager()) {
		guard let swift = Web3HttpProvider(httpProviderURL, network: net?.swift, keystoreManager: manager.swift) else { return nil }
		self.swift = swift
	}
}


@objc public class W3InfuraProvider: W3Web3HttpProvider {
	@objc public init?(_ net: W3NetworkId, accessToken token: String? = nil, keystoreManager manager: W3KeystoreManager = W3KeystoreManager()) {
		guard let swift = InfuraProvider(net.swift, accessToken: token, keystoreManager: manager.swift) else { return nil }
		super.init(swift)
	}
    
    public required init(_ swift: Web3HttpProvider) {
        super.init(swift)
    }
}
