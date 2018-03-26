# lend-x-dev-temporary
The Lend-X Protocol provides a high degree of decoupling of Business Logic, Storage, and Access Control layers. Additional layers of abstraction are introduced to isolate specialized logic and storage which allows the protocol usage in a modular fashion in that non-core functionality can be easily removed or extended without impact to core functionality. This flexibility also provides a certain level of frictionless upgradeability to core contracts while preserving state and keeping redeployment gas costs to a minimum.

## [Contracts](/contracts)

##### [Authorized.sol](/contracts/Authorized.sol)
##### [ECRecovery.sol](/contracts/ECRecovery.sol)
##### [ERC20.sol](/contracts/ERC20.sol)
##### [ERC20Interface.sol](/contracts/ERC20Interface.sol)
##### [ExternalStorage.sol](/contracts/ExternalStorage.sol)
##### [Lend.sol](/contracts/Lend.sol)
##### [Ownable.sol](/contracts/Ownable.sol)
##### [PaymentHandler.sol](/contracts/PaymentHandler.sol)
##### [SafeMath.sol](/contracts/SafeMath.sol)
##### [TokenRegistry.sol](/contracts/TokenRegistry.sol)
