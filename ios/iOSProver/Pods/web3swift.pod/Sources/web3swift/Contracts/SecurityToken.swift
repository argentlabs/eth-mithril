//
//  SecurityToken.swift
//  web3swift
//
//  Created by Dmitry on 12/11/2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation
import PromiseKit
import BigInt

/** ISecurityToken.sol
 * ERC20 events
 ``` solidity
 event Transfer(address indexed from, address indexed to, uint256 value);
 event Approval(address indexed owner, address indexed spender, uint256 value);
 ```
 
 * Mint events
 ``` solidity
 event Minted(address indexed _to, uint256 _value);
 event Burnt(address indexed _burner, uint256 _value);
 ```
 */
public class SecurityToken {
    /// Token address
    public let address: Address
    /// Transaction Options
    public var options: Web3Options = .default
    /// Password to unlock private key for sender address
    public var password: String = "BANKEXFOUNDATION"
    
    /// Represents Address as SecurityToken token (with standard password and options)
    /// - Parameter address: Token address
    public init(_ address: Address) {
        self.address = address
    }
    
    /// Represents Address as SecurityToken token
    /// - Parameter address: Token address
    /// - Parameter from: Sender address
    /// - Parameter address: Password to decrypt sender's private key
    public init(_ address: Address, from: Address, password: String) {
        self.address = address
        options.from = from
        self.password = password
    }
    /// Returns token decimals
    public func decimals() throws -> BigUInt {
        return try address.call("decimals()").wait().uint256()
    }
    
    /// Returns token total supply
    public func totalSupply() throws -> BigUInt {
        return try address.call("totalSupply()").wait().uint256()
    }
    
    /// - Returns: User balance in wei
    public func balance(of owner: Address) throws -> BigUInt {
        return try address.call("balanceOf(address)", owner).wait().uint256()
    }
    
    /**
     Shows how much balance you approved spender to get from your account.
     
     - Returns: Balance that one user can take from another user
     - Parameter owner: Balance holder
     - Parameter spender: Spender address
     
     Solidity interface:
     ``` solidity
     allowance(address,address)
     ```
     */
    public func allowance(owner: Address, spender: Address) throws -> BigUInt {
        return try address.call("allowance(address,address)", owner, spender).wait().uint256()
    }
    
    /**
     Transfers to user amount of balance
     
     - Important: Transaction | Requires password
     - Returns: TransactionSendingResult
     - Parameter user: Recipient address
     - Parameter amount: Amount in wei to send. If you want to send 1 token (not 0.00000000001) use NaturalUnits(amount) instead
     
     Solidity interface:
     ``` solidity
     transfer(address,uint256)
     ```
     */
    public func transfer(to: Address, amount: BigUInt) throws -> TransactionSendingResult {
        return try address.send("transfer(address,uint256)", to, amount).wait()
    }
    
    /**
     Transfers from user1 to user2
     NaturalUnits is user readable representaion of tokens (like "0.01" / "1.543634")
     - Important: Transaction | Requires password | Contract owner only.
     ```
     SecurityToken(address, from: me).transfer(to: user, amount: NaturalUnits(0.1))
     ```
     is not the same as
     ```
     SecurityToken(address).transferFrom(owner: me, to: user, amount: NaturalUnits(0.1))
     ```
     - Returns: TransactionSendingResult
     */
    public func transfer(from: Address, to: Address, amount: BigUInt) throws -> TransactionSendingResult {
        return try address.send("transferFrom(address,address,uint256)", from, to, amount).wait()
    }
    
    /**
     Approves user to take \(amount) tokens from your account.
     
     - Important: Transaction | Requires password
     - Returns: TransactionSendingResult
     - Parameter user: Recipient address
     - Parameter amount: Amount in wei to send. If you want to send 1 token (not 0.00000000001) use NaturalUnits(amount) instead
     
     Solidity interface:
     ``` solidity
     approve(address,uint256)
     ```
     */
    public func approve(spender: Address, amount: BigUInt) throws -> TransactionSendingResult {
        return try address.send("approve(address,uint256)", spender, amount).wait()
    }
    
    /// Decrease approved balance that spender can take from your address
    public func decreaseApproval(spender: Address, subtractedValue: BigUInt) throws -> TransactionSendingResult {
        return try address.send("decreaseApproval(address,uint256)", spender, subtractedValue).wait()
    }
    
    /// Increase approved balance that spender can take from your address
    public func increaseApproval(spender: Address, addedValue: BigUInt) throws -> TransactionSendingResult {
        return try address.send("increaseApproval(address,uint256)", spender, addedValue).wait()
    }
    
    /**
     transfer, transferFrom must respect the result of verifyTransfer
     Solidity interface:
     ``` solidity
     function verifyTransfer(address _from, address _to, uint256 _value) external returns (bool success);
     ```
     */
    public func verifyTransfer(from: Address, to: Address, value: BigUInt) throws -> TransactionSendingResult {
        return try address.send("verifyTransfer(address,address,value)", from, to, value).wait()
    }
    
    /**
     Mints new tokens and assigns them to the target _investor.
     Can only be called by the STO attached to the token (Or by the ST owner if there's no STO attached yet)
     - Parameter investor: Address the tokens will be minted to
     - Parameter value: is the amount of tokens that will be minted to the investor
     
     Solidity interface:
     ``` solidity
     function mint(address _investor, uint256 _value) external returns (bool success);
     ```
     */
    public func mint(investor: Address, value: BigUInt) throws -> TransactionSendingResult {
        return try address.send("mint(address,uint256)", investor, value).wait()
    }
    
    /**
     Mints new tokens and assigns them to the target _investor.
     Can only be called by the STO attached to the token (Or by the ST owner if there's no STO attached yet)
     - Parameter investor: Address the tokens will be minted to
     - Parameter value: is The amount of tokens that will be minted to the investor
     - Parameter data: Data to indicate validation
     
     Solidity interface:
     ``` solidity
     function mintWithData(address _investor, uint256 _value, bytes _data) external returns (bool success);
     ```
     */
    public func mint(investor: Address, value: BigUInt, data: Data) throws -> TransactionSendingResult {
        return try address.send("mintWithData(address,uint256,bytes)", investor, value, data).wait()
    }
    
    
    /**
     Used to burn the securityToken on behalf of someone else
     - Parameter from: Address for whom to burn tokens
     - Parameter value: No. of tokens to be burned
     - Parameter data: Data to indicate validation
     
     Solidity interface:
     ``` solidity
     function burnFromWithData(address _from, uint256 _value, bytes _data) external;
     ```
     */
    public func burn(from: Address, value: BigUInt, data: Data) throws -> TransactionSendingResult {
        return try address.send("burnFromWithData(address,uint256,bytes)", from, value, data).wait()
    }
    
    
    /**
     Used to burn the securityToken
     - Parameter value: No. of tokens to be burned
     - Parameter data: Data to indicate validation
     
     Solidity interface:
     ``` solidity
     function burnWithData(uint256 _value, bytes _data) external;
     ```
     */
    public func burn(value: BigUInt, data: Data) throws -> TransactionSendingResult {
        return try address.send("burnWithData(uint256 _value, bytes _data)", value, data).wait()
    }
    
    /**
     Permissions this to a Permission module, which has a key of 1
     If no Permission return false - note that IModule withPerm will allow ST owner all permissions anyway
     this allows individual modules to override this logic if needed (to not allow ST owner all permissions)
     
     Solidity interface:
     ``` solidity
     function checkPermission(address _delegate, address _module, bytes32 _perm) external view returns (bool);
     ```
     */
    public func checkPermission(delegate: Address, module: Address, perm: Data) throws -> Bool {
        return try address.call("checkPermission(address,address,bytes32)", delegate, module, perm).wait().bool()
    }
    
    /// Module
    public struct Module {
        /// Module name
        public var name: String
        /// Module address
        public var address: Address
        /// Module factory address
        public var factoryAddress: Address
        /// Module archived
        public var isArchived: Bool
        /// Module type
        public var type: UInt8
        /// Module index
        public var index: BigUInt
        /// Name index
        public var nameIndex: BigUInt
        /// Init with contract response
        public init(_ response: SolidityDataReader) throws {
            name = try response.string()
            address = try response.address()
            factoryAddress = try response.address()
            isArchived = try response.bool()
            type = try response.uint8()
            index = try response.uint256()
            nameIndex = try response.uint256()
        }
    }
    /**
     Returns module list for a module type
     - Parameter address: Address of the module
     
     Solidity interface:
     ``` solidity
     function getModule(address _module) external view returns(bytes32, address, address, bool, uint8, uint256, uint256);
     ```
     */
    public func module(at address: Address) throws -> Module {
        let result = try self.address.call("getModule(address)", address).wait()
        let module = try Module(result)
        return module
    }
    
    /**
     Returns module list for a module name
     - Parameter name: Name of the module
     - Returns: address[] List of modules with this name
     
     Solidity interface:
     ``` solidity
     function getModulesByName(bytes32 _name) external view returns (address[]);
     ```
     */
    public func modules(with name: String) throws -> [Address] {
        return try address.call("getModulesByName(bytes32)", name).wait().array { try $0.address() }
    }
    
    /**
     Returns module list for a module type
     - Parameter type: Type of the module
     - Returns: address[] List of modules with this type
     
     Solidity interface:
     ``` solidity
     function getModulesByType(uint8 _type) external view returns (address[]);
     ```
     */
    public func modules(with type: UInt8) throws -> [Address] {
        return try address.call("getModulesByType(uint8)", type).wait().array { try $0.address() }
    }
    
    
    /**
     Queries totalSupply at a specified checkpoint
     - Parameter checkpointId: Checkpoint ID to query as of
     
     Solidity interface:
     ``` solidity
     function totalSupplyAt(uint256 _checkpointId) external view returns (uint256);
     ```
     */
    public func totalSupply(at checkpointId: BigUInt) throws -> BigUInt {
        return try address.call("totalSupplyAt(uint256)", checkpointId).wait().uint256()
    }
    
    /**
     Queries balance at a specified checkpoint
     - Parameter investor: Investor to query balance for
     - Parameter checkpointId: Checkpoint ID to query as of
     
     Solidity interface:
     ``` solidity
     function balanceOfAt(address _investor, uint256 _checkpointId) external view returns (uint256);
     ```
     */
    public func balance(at investor: Address, checkpointId: BigUInt) throws -> BigUInt {
        return try address.call("balanceOfAt(address,uint256)").wait().uint256()
    }
    
    /**
     Creates a checkpoint that can be used to query historical balances / totalSuppy
     
     Solidity interface:
     ``` solidity
     function createCheckpoint() external returns (uint256);
     ```
     */
    public func createCheckpoint() throws -> TransactionSendingResult {
        return try address.send("createCheckpoint()").wait()
    }
    
    
    /**
     Gets length of investors array
     NB - this length may differ from investorCount if the list has not been pruned of zero-balance investors
     - Returns: Length
     
     Solidity interface:
     ``` solidity
     function getInvestors() external view returns (address[]);
     ```
     */
    public func investors() throws -> [Address] {
        return try address.call("getInvestors()").wait().array { try $0.address() }
    }
    
    /**
     returns an array of investors at a given checkpoint
     NB - this length may differ from investorCount as it contains all investors that ever held tokens
     - Parameter checkpointId: Checkpoint id at which investor list is to be populated
     - Returns: list of investors
     
     Solidity interface:
     ``` solidity
     function getInvestorsAt(uint256 _checkpointId) external view returns(address[]);
     ```
     */
    public func investors(at checkpointId: BigUInt) throws -> [Address] {
        return try address.call("getInvestorsAt(uint256)").wait().array { try $0.address() }
    }
    
    /**
     generates subset of investors
     NB - can be used in batches if investor list is large
     - Parameter start: Position of investor to start iteration from
     - Parameter end: Position of investor to stop iteration at
     - Returns: list of investors
     
     Solidity interface:
     ``` solidity
     function iterateInvestors(uint256 _start, uint256 _end) external view returns(address[]);
     ```
     */
    public func iterateInvestors(start: BigUInt, end: BigUInt) throws -> [Address] {
        return try address.call("iterateInvestors(uint256,uint256)",start,end).wait().array { try $0.address() }
    }
    
    /**
     Gets current checkpoint ID
     - Returns: Id
     
     Solidity interface:
     ``` solidity
     function currentCheckpointId() external view returns (uint256);
     ```
     */
    public func currentCheckpointId() throws -> BigUInt {
        return try address.call("currentCheckpointId()").wait().uint256()
    }
    
    /**
     Gets an investor at a particular index
     - Parameter index: Index to return address from
     - Returns: Investor address
     
     Solidity interface:
     ``` solidity
     function investors(uint256 _index) external view returns (address);
     ```
     */
    public func investors(index: BigUInt) throws -> Address {
        return try address.call("investors(uint256)", index).wait().address()
    }
    
    /**
     Allows the owner to withdraw unspent POLY stored by them on the ST or any ERC20 token.
     @dev Owner can transfer POLY to the ST which will be used to pay for modules that require a POLY fee.
     - Parameter tokenContract: Address of the ERC20Basic compliance token
     - Parameter value: Amount of POLY to withdraw
     
     Solidity interface:
     ``` solidity
     function withdrawERC20(address _tokenContract, uint256 _value) external;
     ```
     */
    public func withdrawERC20(tokenContract: Address, value: BigUInt) throws -> TransactionSendingResult {
        return try address.send("withdrawERC20(address,uint256)", tokenContract, value).wait()
    }
    
    /**
     Allows owner to approve more POLY to one of the modules
     - Parameter module: Module address
     - Parameter budget: New budget
     
     Solidity interface:
     ``` solidity
     function changeModuleBudget(address _module, uint256 _budget) external;
     ```
     */
    public func changeModuleBudget(module: Address, budget: BigUInt) throws -> TransactionSendingResult {
        return try address.send("changeModuleBudget(address,uint256)", module, budget).wait()
    }
    
    /**
     Changes the tokenDetails
     - Parameter newTokenDetails: New token details
     
     Solidity interface:
     ``` solidity
     function updateTokenDetails(string _newTokenDetails) external;
     ```
     */
    public func updateTokenDetails(newTokenDetails: String) throws -> TransactionSendingResult {
        return try address.send("updateTokenDetails(string)", newTokenDetails).wait()
    }
    
    /**
     Allows the owner to change token granularity
     - Parameter granularity: Granularity level of the token
     
     Solidity interface:
     ``` solidity
     function changeGranularity(uint256 _granularity) external;
     ```
     */
    public func changeGranularity(granularity: BigUInt) throws -> TransactionSendingResult {
        return try address.send("changeGranularity(uint256)", granularity).wait()
    }
    
    /**
     Removes addresses with zero balances from the investors list
     - Parameter start: Index in investors list at which to start removing zero balances
     - Parameter iters: Max number of iterations of the for loop
     NB - pruning this list will mean you may not be able to iterate over investors on-chain as of a historical checkpoint
     
     Solidity interface:
     ``` solidity
     function pruneInvestors(uint256 _start, uint256 _iters) external;
     ```
     */
    public func pruneInvestors(start: BigUInt, iters: BigUInt) throws -> TransactionSendingResult {
        return try address.send("pruneInvestors(uint256,uint256)", start, iters).wait()
    }
    
    /**
     Freezes all the transfers
     
     Solidity interface:
     ``` solidity
     function freezeTransfers() external;
     ```
     */
    public func freezeTransfers() throws -> TransactionSendingResult {
        return try address.send("freezeTransfers()").wait()
    }
    
    /**
     Un-freezes all the transfers
     
     Solidity interface:
     ``` solidity
     function unfreezeTransfers() external;
     ```
     */
    public func unfreezeTransfers() throws -> TransactionSendingResult {
        return try address.send("unfreezeTransfers()").wait()
    }
    
    /**
     Ends token minting period permanently
     
     Solidity interface:
     ``` solidity
     function freezeMinting() external;
     ```
     */
    public func freezeMinting() throws -> TransactionSendingResult {
        return try address.send("freezeMinting()").wait()
    }
    
    /**
     Mints new tokens and assigns them to the target investors.
     Can only be called by the STO attached to the token or by the Issuer (Security Token contract owner)
     - Parameter investors: A list of addresses to whom the minted tokens will be delivered
     - Parameter values: A list of the amount of tokens to mint to corresponding addresses from _investor[] list
     - Returns: Success
     
     Solidity interface:
     ``` solidity
     function mintMulti(address[] _investors, uint256[] _values) external returns (bool success);
     ```
     */
    public func mintMulti(investors: [Address], values: [BigUInt]) throws -> TransactionSendingResult {
        return try address.send("mintMulti(address[],uint256[])", investors, values).wait()
    }
    
    /**
     function used to attach a module to the security token
     E.G.: On deployment (through the STR) ST gets a TransferManager module attached to it
     to control restrictions on transfers.
     You are allowed to add a new moduleType if:
     - there is no existing module of that type yet added
     - the last member of the module list is replacable
     - Parameter moduleFactory: Is the address of the module factory to be added
     - Parameter data: Is data packed into bytes used to further configure the module (See STO usage)
     - Parameter maxCost: Max amount of POLY willing to pay to module. (WIP)
     
     
     Solidity interface:
     ``` solidity
     function addModule(
     address _moduleFactory,
     bytes _data,
     uint256 _maxCost,
     uint256 _budget
     ) external;
     ```
     */
    public func addModule(moduleFactory: Address, data: Data, maxCost: BigUInt, budget: BigUInt) throws -> TransactionSendingResult {
        return try address.send("addModule(address,bytes,uint256,uint256)", moduleFactory, data, maxCost, budget).wait()
    }
    
    /**
     Archives a module attached to the SecurityToken
     - Parameter module: Address of module to archive
     
     Solidity interface:
     ``` solidity
     function archiveModule(address _module) external;
     ```
     */
    public func archive(module: Address) throws -> TransactionSendingResult {
        return try address.send("archiveModule(address)", module).wait()
    }
    
    /**
     Unarchives a module attached to the SecurityToken
     - Parameter module: Address of module to unarchive
     
     Solidity interface:
     ``` solidity
     function unarchiveModule(address _module) external;
     ```
     */
    public func unarchive(module: Address) throws -> TransactionSendingResult {
        return try address.send("unarchiveModule(address)", module).wait()
    }
    
    /**
     Removes a module attached to the SecurityToken
     - Parameter module: Address of module to archive
     
     Solidity interface:
     ``` solidity
     function removeModule(address _module) external;
     ```
     */
    public func remove(module: Address) throws -> TransactionSendingResult {
        return try address.send("removeModule(address)", module).wait()
    }
    
    /**
     Used by the issuer to set the controller addresses
     - Parameter controller: Address of the controller
     
     Solidity interface:
     ``` solidity
     function setController(address _controller) external;
     ```
     */
    public func set(controller: Address) throws -> TransactionSendingResult {
        return try address.send("setController(address)", module).wait()
    }
    
    /**
     Used by a controller to execute a forced transfer
     - Parameter from: Address from which to take tokens
     - Parameter to: Address where to send tokens
     - Parameter value: Amount of tokens to transfer
     - Parameter data: Data to indicate validation
     - Parameter log: Data attached to the transfer by controller to emit in event
     
     Solidity interface:
     ``` solidity
     function forceTransfer(address _from, address _to, uint256 _value, bytes _data, bytes _log) external;
     ```
     */
    public func forceTransfer(from: Address, to: Address, value: BigUInt, data: Data, log: Data) throws -> TransactionSendingResult {
        return try address.send("forceTransfer(address,address,uint256,bytes,bytes)", from, to, value, data, log).wait()
    }
    
    /**
     Used by a controller to execute a foced burn
     - Parameter from: Address from which to take tokens
     - Parameter value: Amount of tokens to transfer
     - Parameter data: Data to indicate validation
     - Parameter log: Data attached to the transfer by controller to emit in event
     
     Solidity interface:
     ``` solidity
     function forceBurn(address _from, uint256 _value, bytes _data, bytes _log) external;
     ```
     */
    public func forceBurn(from: Address, value: BigUInt, data: Data, log: Data) throws -> TransactionSendingResult {
        return try address.send("forceBurn(address,uint256,bytes,bytes)", from, value, data, log).wait()
    }
    
    /**
     Used by the issuer to permanently disable controller functionality
     @dev enabled via feature switch "disableControllerAllowed"
     
     Solidity interface:
     ``` solidity
     function disableController() external;
     ```
     */
    public func disableController() throws -> TransactionSendingResult {
        return try address.send("disableController()").wait()
    }
    
    
    /**
     Used to get the version of the securityToken
     
     Solidity interface:
     ``` solidity
     function getVersion() external view returns(uint8[]);
     ```
     */
    public func version() throws -> [UInt8] {
        return try address.call("getVersion()").wait().array { try $0.uint8() }
    }
    
    /**
     Gets the investor count
     
     Solidity interface:
     ``` solidity
     function getInvestorCount() external view returns(uint256);
     ```
     */
    public func investorsCount() throws -> BigUInt {
        return try address.call("getInvestorCount()").wait().uint256()
    }
    
    /**
     Overloaded version of the transfer function
     - Parameter to: Receiver of transfer
     - Parameter value: Value of transfer
     - Parameter data: Data to indicate validation
     - Returns: Bool success
     
     Solidity interface:
     ``` solidity
     function transferWithData(address _to, uint256 _value, bytes _data) external returns (bool success);
     ```
     */
    public func transfer(to: Address, value: BigUInt, data: Data) throws -> TransactionSendingResult {
        return try address.send("transferWithData(address,uint256,bytes)", to, value, data).wait()
    }
    /**
     Overloaded version of the transferFrom function
     - Parameter from: Sender of transfer
     - Parameter to: Receiver of transfer
     - Parameter value: Value of transfer
     - Parameter data: Data to indicate validation
     - Returns: Bool success
     
     Solidity interface:
     ``` solidity
     function transferFromWithData(address _from, address _to, uint256 _value, bytes _data) external returns(bool);
     ```
     */
    public func transfer(from: Address, to: Address, value: BigUInt, data: Data) throws -> TransactionSendingResult {
        return try address.send("transferFromWithData(address,address,uint256,bytes)", from, to, value, data).wait()
    }
    
    /**
     Provides the granularity of the token
     - Returns: Token granularity
     
     Solidity interface:
     ``` solidity
     function granularity() external view returns(uint256);
     ```
     */
    public func granularity() throws -> BigUInt {
        return try address.call("granularity()").wait().uint256()
    }
}
