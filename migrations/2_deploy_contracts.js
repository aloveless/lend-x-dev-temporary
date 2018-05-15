var Lend = artifacts.require("Lend");
var PaymentHandler = artifacts.require("PaymentHandler");
var ExternalStorage = artifacts.require("ExternalStorage");
var TokenRegistry = artifacts.require("TokenRegistry");

//Util Libraries
var ECRecovery = artifacts.require("ECRecovery");
var SafeMath = artifacts.require("SafeMath");

//ERC20 Protocol Token
var ProtocolToken = artifacts.require("ERC20");

//ERC20 Tokens for Testing
var WETH = artifacts.require("./test_tokens/WETH");
var HDOG = artifacts.require("./test_tokens/HDOG");


module.exports = function(deployer) {
	deployer.deploy([ECRecovery, SafeMath]);
	deployer.link(ECRecovery, Lend);
	deployer.link(SafeMath, [Lend, PaymentHandler]);

	deployer.deploy(ProtocolToken);

	deployer.deploy(WETH);
	deployer.deploy(HDOG);

	var paymentHandler, externalStorage, lendx;

	deployer.then(function(){
		return deployer.deploy(TokenRegistry);
	}).then(function(){
		return deployer.deploy(ExternalStorage);
	}).then(function(contract){
		externalStorage = contract;
		return deployer.deploy(PaymentHandler);
	}).then(function(contract){
		paymentHandler = contract;
		return deployer.deploy(Lend, ProtocolToken.address, ExternalStorage.address, PaymentHandler.address, TokenRegistry.address);
	}).then(function(contract){
		lendx = contract;
		externalStorage.addAuthorization(Lend.address);
		paymentHandler.addAuthorization(Lend.address);
	});
};
