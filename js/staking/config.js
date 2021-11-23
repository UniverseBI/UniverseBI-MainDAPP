$(function () {
	
	$.config = {
		chains : [
		
			{name: "Universe BI", nativeCurrencyName: "BI", chainId: 1000, projects: [
				{
				    index:0,
					name: "Stake BI to earn DOGEX", 
					stake: {name: "BI", address: "0x"}, 
					reward: {name: "DOGEX", address: "0x8888888888888888888888888888888888888888"}, 
					apy: "200%", 
					fee: "5%", 
					address: "0x8888888888888888888888888888888888888888", 
					ref: "0x8888888888888888888888888888888888888888"
				},{
				    index:1,
					name: "Stake 0xDOG to earn DOGEX", 
					stake: {name: "0xDOG", address: "0x8888888888888888888888888888888888888888"}, 
					reward: {name: "DOGEX", address: "0x8888888888888888888888888888888888888888"}, 
					apy: "200%", 
					fee: "5%", 
					address: "0x8888888888888888888888888888888888888888", 
					ref: "0x8888888888888888888888888888888888888888"
				},{
				    index:2,
					name: "Stake DOGE to earn DOGEX", 
					stake: {name: "DOGE", address: "0x8888888888888888888888888888888888888888"}, 
					reward: {name: "DOGEX", address: "0x8888888888888888888888888888888888888888"}, 
					apy: "200%", 
					fee: "5%", 
					address: "0x8888888888888888888888888888888888888888", 
					ref: "0x8888888888888888888888888888888888888888"
				},{
				    index:4,
					name: "Stake LBI to earn DOGEX", 
					stake: {name: "LBI", address: "0x8888888888888888888888888888888888888888"}, 
					reward: {name: "DOGEX", address: "0x8888888888888888888888888888888888888888"}, 
					apy: "200%", 
					fee: "5%", 
					address: "0x8888888888888888888888888888888888888888", 
					ref: "0x8888888888888888888888888888888888888888"
				}
			]}
		]
	};
	
	// default from chain
	var chain = $.getParam("chain");
	if (! chain) {
		chain = $.getCookie("chain");
	}
	if (chain) {
		for (var currChain of $.config.chains) {
			if (Number(chain) == currChain.chainId) {
				$.config.currChain = currChain;
				break;
			}
		}
	} else {
		$.config.currChain = $.config.chains[0];
	}
	$.setCookie("chain", $.config.currChain.chainId + "");
});
