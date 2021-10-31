$(function () {
	
	$.getRate = function(callback) {
		$.ajax({
			type: "get",
			url: "https://api.foo.com/index/index/getPrice",
			data: {
				chain0: $.config.from.chain,
				coin0: $.config.from.coin,
				chain1: $.config.to.chain,
				coin1: $.config.to.coin
			},
			success: function(rate) {
				callback(rate);
			}
		});
	};
	
	$.applyPayment = function(callback) {
		// from address
		var fromAmount = $("#input_from_amount").val();
		if (! fromAmount) {
			$.tips('No from amount entered', 2000);
			return null;
		}
		
		// to address
		var toAmount = $("#input_to_amount").val();
		if (! toAmount) {
			$.tips('No to amount entered', 2000);
			return null;
		}
		
		// from address
		var fromAddr = $("#input_from_addr").val();
		if (! fromAddr) {
			$.tips("No from address entered", 2000);
			return null;
		}
		
		// to address
		var toAddr = $("#input_to_addr").val();
		if (! toAddr) {
			$.tips("No to address entered", 2000);
			return null;
		}
		
		// data
		var data = {
				fromChain: $.config.from.chain, 
				fromCoin: $.config.from.coin,
				fromAmount: fromAmount,
				fromAddr: fromAddr,
				toChain: $.config.to.chain,
				toCoin: $.config.to.coin,
				toAmount: toAmount,
				toAddr: toAddr,
				applyTime: new Date().getTime()
		};
		$.ajax({
		 	type: "post",
		 	url: "https://api.foo.com/index/index/applyPayment",
		 	data: data,
		 	success: function(msg){
		 		if (msg.key && msg.paymentAddr) {
		 			data.key = msg.key;
		 			data.paymentAddr = msg.paymentAddr;
		 			callback(data);
		 		} else {
		 			$.tips("Failed", 2000);
		 		}
		 	}
		});
	};
	
	$.confirmPayment = function(key, txHash) {
		var data = {
			key: key,
			confirmTime: new Date().getTime()
		};
		if (txHash) data.txHash = txHash; 
		$.ajax({
		 	type: "post",
		 	url: "https://api.foo.com/index/index/confirmPayment",
		 	data: data,
		 	success: function(res){
		 		$.hidePopup();
				$.hideTips();
		 		if (res == 0) $.tips("Failed", 2000);
		 	}
		});
	};

});