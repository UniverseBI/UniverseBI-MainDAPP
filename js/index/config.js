$(function () {
	$.config = {
		chains : {
			"1000": {name: "Universe BI", coins: {
				"0x": {name: "BI"},
				"0xd3E8E3f2D688773474475275c287bff41a0e7085": {name: "DOGEX"},
				"0x6Bf654F5873AAeCaee75e328B7977c256D906829": {name: "SDOG"},
				"0x45328dB9cf9ece8Cc2418D295A38872fee5D7Dfb": {name: "0xDOG"},
				"0x834178C4e237755F5d9064a31E7eaf7ab4174cFf": {name: "USDT"},
				"0xF58FD25968e19F203Cf41231835FDA0e95Fa635D": {name: "LBI"}
			}},
			"-3": {name: "Doge Blockchain", coins: {
				"0x": {name: "DOGE"}
			}},
			"1": {name: "Ethereum", coins: {
				"0x": {name: "ETH"},
				"0xdac17f958d2ee523a2206206994597c13d831ec7": {name: "USDT", unit: "Mwei"}
			}},
			"56": {name: "Smart Chain", coins: {
				"0x": {name: "BNB"},
				"0xba2ae424d960c26247dd6c32edc70b295c744c43": {name: "DOGE", decimals: 8},
				"0x55d398326f99059ff775485246999027b3197955": {name: "USDT"}
			}},
			"518": {name: "Dogethereum OB", coins: {
				"0x": {name: "BI"},
				"0x3C8a7B3e97060Ad50E257ae2d27576bF53D9e10C": {name: "DOGE"},
				"0x7d8f299A092fccFa0876E511786262c42a423598": {name: "USDT"},
				"0xBd90EfDf4c5543bc9be1033F84e1162E40F61365": {name: "SDOG"},
				"0x3e5fb1db43139d6bc086d3275038d249ead3c23d": {name: "LBI"}
			}}
		},
		pairs : [
			[	// 518 BI : 1000 BI
				{chain: "518", coin: "0x"},
				{chain: "1000", coin: "0x"}
			], 
			[	// 518 DOGE : 1000 DOGE
				{chain: "518", coin: "0x3C8a7B3e97060Ad50E257ae2d27576bF53D9e10C"},
				{chain: "1000", coin: "0x45328dB9cf9ece8Cc2418D295A38872fee5D7Dfb"}
			], 
			[	// 518 LBI : 1000 LBI
				{chain: "518", coin: "0x3e5fb1db43139d6bc086d3275038d249ead3c23d"},
				{chain: "1000", coin: "0xF58FD25968e19F203Cf41231835FDA0e95Fa635D"}
			], 
			[	// 518 SDOG : 1000 DOGEX
			    {chain: "518", coin: "0xBd90EfDf4c5543bc9be1033F84e1162E40F61365"},
				{chain: "1000", coin: "0xd3E8E3f2D688773474475275c287bff41a0e7085"}

			], 
			[	// 1000 SDOG : 1000 DOGEX
				{chain: "1000", coin: "0xd3E8E3f2D688773474475275c287bff41a0e7085"},
				{chain: "1000", coin: "0x6Bf654F5873AAeCaee75e328B7977c256D906829"}
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