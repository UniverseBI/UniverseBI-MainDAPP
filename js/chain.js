$(function(){
	var web3;
	var walletAddress;
	var ERC20_ABI = [{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"spender","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Transfer","type":"event"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"spender","type":"address"}],"name":"allowance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"approve","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"decimals","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"symbol","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transfer","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"sender","type":"address"},{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transferFrom","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"}];
	var ETH_USDT_ABI = [{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"spender","type":"address"}],"name":"allowance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"}],"name":"approve","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"decimals","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transfer","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"sender","type":"address"},{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"}];
	
	// 1.verify chainId
	$.verifyChainId = async function(chainId, callback, errorCallback) {
		const currChainIdHex = await window.ethereum.request({ method: 'eth_chainId' });
		var currChainId;
		switch (currChainIdHex) {
			case "0x1" : currChainId = 1; break;
			case "0x38" : currChainId = 56; break;		// BNB
			case "0x206" : currChainId = 518; break;	// DFC
			case "0x3e6" : currChainId = 998; break;	// EKTA
		}
		if (chainId == currChainId) {
			$.hideDialog();
			if (callback) callback();
		} else {
			$.dialog("Not in " + $.config.fromChain.chain.toLowerCase() + " network, please transfer by scanning QR code", 3000);
			if (errorCallback) errorCallback();
		}
	}
	
	// 2.connect wallet
	$.connectWallet = function(address) {
		walletAddress = address;
		$.inputFromAddrUpdate(address);
	};
	
	// 3.access chain
	$.transfer = function(data) {
		if ($.config.swapCoin == $.config.fromChain.coin) {
			var message = {from: walletAddress, to: data.paymentAddr, value: web3.utils.toWei(data.fromAmount, 'ether')};
			web3.eth.sendTransaction(message, (error, res) => {
				$.errorProcess(error);
		    }).then(function(tx) {
				$.resultProcess(tx, function(){
					$.submit(data);
				});
			});
		} else {
			var isEthUsdt = $.config.swapCoin == "USDT" && $.config.fromChain.coin == "ETH" ? true : false;
			var coininfo = $.config.fromChain.coins[$.config.swapCoin];
			var contract = new web3.eth.Contract(isEthUsdt ? ETH_USDT_ABI : ERC20_ABI, coininfo.address);
			var amount = web3.utils.toWei(data.fromAmount, isEthUsdt ? "Mwei" : "ether");
			if (coininfo.decimals) amount = $.floatMul(data.fromAmount, Math.pow(10, coininfo.decimals));
			contract.methods
				.transfer(data.paymentAddr, amount)
				.send({from: walletAddress}, function(error) {
					$.errorProcess(error);
				})
				.then(function(tx) {
					$.resultProcess(tx, function(){
						$.submit(data);
					});
				});
		}
	};
	
	// 4.error process
	$.errorProcess = function(error){
		if (error) {
			if (error.code == 4001) {
				$.dialog(error.message, 2000);
			}
		}
	};
	
	// 5.result process
	$.resultProcess = function(tx, callback) {
		$.waitForReceipt(tx.transactionHash, 6, (receipt) => {
			callback();
		});
	};
	
	// 6.wait for receipt
	$.waitForReceipt = async function(tx_hash, max_try, callback) {
		if (max_try <= 0) {
			$.dialog("Wait for receipt timeout", 2000);
			return;
		}
		let receipt = await web3.eth.getTransactionReceipt(tx_hash);
		if (receipt != null) {
			callback(receipt);
		} else {
			await $.sleep(1500);
			$.waitForReceipt(tx_hash, max_try - 1, callback);
		}
	};
	
	// start
	if ($.config.fromChain.chainId > 0) {
		if (window.ethereum) {
			try {
				$.dialog("Connect Wallet...", 0, true);
				window.ethereum.enable().then(accounts => {
					window.ethereum.on("networkChanged", function (networkId) {
						location.reload();
					});
					$.verifyChainId($.config.fromChain.chainId, function(){
						web3 = new Web3(window.ethereum);
						window.ethereum.on("accountsChanged", function(accounts) {
							$.connectWallet(accounts[0]);
						});
						$.connectWallet(accounts[0]);
						$.bindSubmitEvent($.transfer);
					}, $.bindQrcodeWindow);
				});
			} catch (error) {
				$.dialog(error + ", please transfer by scanning QR code", 3000);
				$.bindQrcodeWindow();
			}
		} else {
			$.dialog("Not in dapp browser, please transfer by scanning QR code", 3000);
			$.bindQrcodeWindow();
		}
	} else {
		$.dialog("The current chain only supports transfer by scanning QR code", 3000);
		$.bindQrcodeWindow();
	}
	
});