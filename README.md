# lend-x-dev-temporary
The Lend-X Protocol is cool

## [Contracts](/contracts)

### Protocol
##### [Lend.sol](/contracts/Lend.sol)
##### [PaymentHandler.sol](/contracts/PaymentHandler.sol)
##### [ExternalStorage.sol](/contracts/ExternalStorage.sol)
##### [ERC20Interface.sol](/contracts/ERC20Interface.sol)

### Registry
##### [TokenRegistry.sol](/contracts/TokenRegistry.sol)

### Access Control
##### [MultiSigWallet.sol](/contracts/MultiSigWallet.sol)
Using MultiSigWallet developed by the Gnosis team  
https://github.com/gnosis/MultiSigWallet  
Wallet is being used by several projects with significant funds and has been audited by the OpenZeppelin team, audit results:  
https://blog.zeppelin.solutions/gnosis-multisig-wallet-audit-d702ff0e2b1e  

##### [Ownable.sol](/contracts/Ownable.sol)
##### [Authorized.sol](/contracts/Authorized.sol)

### Utility
##### [ECRecovery.sol](/contracts/ECRecovery.sol)
##### [SafeMath.sol](/contracts/SafeMath.sol)


### ICO Related Contracts that are not part of the protocol
##### [ERC20.sol](/ico/ERC20.sol)
The ERC20.sol contract is not part of the protocol, just storing our ICO token contract here for now.
