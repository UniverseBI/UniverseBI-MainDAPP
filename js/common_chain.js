$(function(){
	const networks = {
		1: [{
			chainId: '0x1'
		}],
		3: [{	// Ropsten test network
			chainId: '0x3'
		}],
		4: [{	// Rinkeby test network
			chainId: '0x4'
		}],
		5: [{	// Goerli test network
			chainId: '0x5'
		}],
		42: [{	// Kovan test network
			chainId: '0x2a'
		}],
		56: [{
			chainId: '0x38',
			chainName: 'Binance Smart Chain',
			nativeCurrency: {
				name: 'BNB',
				symbol: 'BNB',
				decimals: 18
			},
			rpcUrls: ['https://bsc-dataseed.binance.org/'],
			blockExplorerUrls: ['https://bscscan.com/']
		}],
		97: [{
			chainId: '0x61',
			chainName: 'Binance Smart Chain - Testnet',
			nativeCurrency: {
				name: 'BNB',
				symbol: 'BNB',
				decimals: 18
			},
			rpcUrls: ['https://data-seed-prebsc-1-s1.binance.org:8545/'],
			blockExplorerUrls: ['https://testnet.bscscan.com']
		}],
		128: [{
			chainId: '0x80',
			chainName: 'Heco',
			nativeCurrency: {
				name: 'HT',
				symbol: 'HT',
				decimals: 18
			},
			rpcUrls: ['https://http-mainnet.hecochain.com/'],
			blockExplorerUrls: ['https://scan.hecochain.com']
		}],
		518: [{
			chainId: '0x206',
			chainName: 'DeFi Chain',
			nativeCurrency: {
				name: 'DFC',
				symbol: 'DFC',
				decimals: 18
			},
			rpcUrls: ['https://mainnet.defi.dev/'],
			blockExplorerUrls: ['https://defi.518.bi/']
		}],
		1000: [{
			chainId: '0x3e8',
			chainName: 'Routereum',
			nativeCurrency: {
				name: 'RDFC',
				symbol: 'RDFC',
				decimals: 18
			},
			rpcUrls: ['https://defi.518.bi/'],
			blockExplorerUrls: ['https://defi.518.bi/']
		}]
	};
	
	var ERC20_ABI = [{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"spender","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Transfer","type":"event"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"spender","type":"address"}],"name":"allowance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"approve","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"decimals","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"symbol","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transfer","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"sender","type":"address"},{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transferFrom","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"}];
	var ETH_USDT_ABI = [{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"spender","type":"address"}],"name":"allowance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"}],"name":"approve","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"decimals","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transfer","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"sender","type":"address"},{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"}];
	$.coinContract = function(fromChain, fromCoin){
		if (Number(fromChain) == 1 && fromCoin == "0xdac17f958d2ee523a2206206994597c13d831ec7") {
			return new $.web3.eth.Contract(ETH_USDT_ABI, fromCoin);
		} else {
			return new $.web3.eth.Contract(ERC20_ABI, fromCoin);
		}
	};
	
	$.toAmount = function(value, max) {
		value = value == "." ? "" : value;
		value = value == "00" ? "0" : value;
		value = value.indexOf(".") == value.lastIndexOf(".") ? value : value.substring(0, value.lastIndexOf("."));
		value = value.replace(/[^\d.]/g, '');						// clear not number & points
		value = value.replace(/^(\-)*(\d+)\.(\d{6}).*$/, '$1$2.$3');// decimals limit
		value = Number(value) >= 10000000000 ? "9999999999.999999" : value;
		if (max) {
			value = Number(max) < Number(value) ? max : value;
			if (Number(max) == 0) {
				value = "";
				$.tips("Insufficient balance", 2000);
			}
		}
		return value;
	};
	
	$.fromWei = function(amount, unit, decimals) {
		if (unit) {
			return $.web3.utils.fromWei(amount, unit);
		} else if (decimals) {
			return $.floatDiv(amount, Math.pow(10, decimals));
		} else {
			return $.web3.utils.fromWei(amount);
		}
	};
	
	$.toWei = function(amount, unit, decimals) {
		if (unit) {
			return $.web3.utils.toWei(amount, unit);
		} else if (decimals) {
			return $.floatMul(amount, Math.pow(10, decimals));
		} else {
			return $.web3.utils.toWei(amount);
		}
	};
	
	$.errorProcess = function(error){
		if (error) {
			if (error.code == 4001) {
				$.tips(error.message, 2000);
			}
		}
	};
	
	$.resultProcess = function(tx, callback) {
		$.waitForReceipt(tx.transactionHash, 6, (receipt) => {
			$.hideTips();
			callback();
		});
	};
	
	$.waitForReceipt = async function(tx_hash, max_try, callback) {
		if (max_try <= 0) {
			$.tips("Wait for receipt timeout", 2000);
			return;
		}
		let receipt = await $.web3.eth.getTransactionReceipt(tx_hash);
		if (receipt != null) {
			callback(receipt);
		} else {
			await $.sleep(1500);
			$.waitForReceipt(tx_hash, max_try - 1, callback);
		}
	};
	
	$.switchNetwork = async function(chainId) {
		var data = networks[chainId];
		if (data[0].rpcUrls) {
			await ethereum.request({method: 'wallet_addEthereumChain', params: data}).catch();
		} else {
			await ethereum.request({method: 'wallet_switchEthereumChain', params: data}).catch();
		}
	};
	
	$.connectWallet = function(chainId, chainName, callback, errorCallback, errorMsgTimeout, errorMsgAppend) {
		errorMsgTimeout = errorMsgTimeout ? errorMsgTimeout : 0;
		errorMsgAppend = errorMsgAppend ? ", " + errorMsgAppend : "";
		if (ethereum) {
			try {
				// connect wallet
				$.loading("Connect Wallet...", 0, true);
				ethereum.enable().then(accounts => {
					$.hideLoading();
					$.web3 = new Web3(ethereum);
					
					// network changed
					ethereum.on("chainChanged", function (chainId) {	// chainId=0x**
						location.reload();
					});
					
					// verify chainId
					$.web3.eth.getChainId().then(currChainId => {
						if (chainId == currChainId) {
							// accounts changed
							ethereum.on("accountsChanged", function(accounts) {
								$.walletAddress = accounts[0];
								if (callback) callback();
							});
							
							// bind
							$.walletAddress = accounts[0];
							if (callback) callback();
						} else {
							$.switchNetwork(chainId);
							$.tips("Not in \"" + chainName.toLowerCase() + "\"  network" + errorMsgAppend, errorMsgTimeout);
							if (errorCallback) errorCallback();
						}
					});
				});
			} catch (error) {
				$.tips(error + errorMsgAppend, errorMsgTimeout);
				if (errorCallback) errorCallback();
			}
		} else {
			$.tips("Not in dapp browser" + errorMsgAppend, errorMsgTimeout);
			if (errorCallback) errorCallback();
		}
	};
});