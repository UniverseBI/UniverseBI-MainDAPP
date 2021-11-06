$(function () {
	$.config = {
		chains : {
			"-3": {name: "Doge Blockchain", coins: {
				"0x": {name: "DOGE"}
			}},
			"1": {name: "Ethereum", coins: {
				"0x": {name: "ETH"},
				"0xdac17f958d2ee523a2206206994597c13d831ec7": {name: "USDT", unit: "Mwei"}
			}},
			"188": {name: "Universe BI", coins: {
				"0x": {name: "BI"},
				"0x75CF02680c90FF4069fC2c2dA86ead4416F0e18f": {name: "DOGX"},
				"0xed216d044B969Fba124f3fbFaa28eAFcD4f865e4": {name: "0xDOG"},
				"0xFAeCCAe83A0eb7266C6B87070bf2ad4EcDc1Fc0e": {name: "USDT"},
			}}
		},
		pairs : [
			[
				{chain: "-3", coin: "0x"},
				{chain: "188", coin: "0xed216d044B969Fba124f3fbFaa28eAFcD4f865e4"}
			],
			[
				{chain: "1", coin: "0xdac17f958d2ee523a2206206994597c13d831ec7"},
				{chain: "188", coin: "0xFAeCCAe83A0eb7266C6B87070bf2ad4EcDc1Fc0e"}
			] 
		]
	};
	
	// param
	var fromCoin = $.getParam("fromCoin");
	var fromChain = $.getParam("fromChain");
	if (! fromChain) fromChain = $.getCookie("chain");
	
	// default from/to
	$.updateFromTo = function(fromChain, fromCoin) {
		for(var pair of $.config.pairs) {
			if ((! fromChain || pair[0].chain == fromChain) && (! fromCoin || pair[0].coin == fromCoin)) {
				$.config.from = pair[0];
				$.config.to = pair[1];
				break;
			}
			if ((! fromChain || pair[1].chain == fromChain) && (! fromCoin || pair[1].coin == fromCoin)) {
				$.config.from = pair[1];
				$.config.to = pair[0];
				break;
			}
		}
	};
	$.updateFromTo(fromChain, fromCoin);
	
	// Cookie & No pair
	if ($.config.from) {
		$.setCookie("chain", $.config.from.chain);
	} else {
		$.tips("The current chain has no trading pairs");
		return;
	}
	
	// default from list
	var fromMap = {};
	for(var pair of $.config.pairs) {
		if (pair[0].chain == $.config.from.chain) {
			fromMap[pair[0].chain + "_" + pair[0].coin] = pair[0];
		}
		if (pair[1].chain == $.config.from.chain) {
			fromMap[pair[1].chain + "_" + pair[1].coin] = pair[1];
		}
	}
	$.config.fromList = Object.values(fromMap);
	
	// default to list
	$.updateToList = function() {
		$.config.toList = [];
		var toMap = {};
		for(var pair of $.config.pairs) {
			if (pair[0].chain == $.config.from.chain && pair[0].coin == $.config.from.coin) {
				toMap[pair[1].chain + "_" + pair[1].coin] = pair[1];
			} else if (pair[1].chain == $.config.from.chain && pair[1].coin == $.config.from.coin) {
				toMap[pair[0].chain + "_" + pair[0].coin] = pair[0];
			}
		}
		$.config.toList = Object.values(toMap);
	};
	$.updateToList();
	
	// switch chain
	var chainMap = {};
	for(var pair of $.config.pairs) {
		chainMap[pair[0].chain] = "";
		chainMap[pair[1].chain] = "";
	}
	$.config.chainIds = Object.keys(chainMap);
});