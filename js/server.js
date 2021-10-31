$(function () {
	// request
	$.getSubmitData = function(paymentAddr) {
		// from address
		var fromAmount = $("#input_from_amount").val();
		if (! fromAmount) {
			$.dialog('No from amount entered', 1000);
			return null;
		}
		
		// to address
		var toAmount = $("#input_to_amount").val();
		if (! toAmount) {
			$.dialog('No to amount entered', 1000);
			return null;
		}
		
		// from address
		var fromAddr = $("#input_from_addr").val();
		if (! fromAddr) {
			$.dialog("No from address entered", 1000);
			return null;
		}
		
		// to address
		var toAddr = $("#input_to_addr").val();
		if (! toAddr) {
			$.dialog("No to address entered", 1000);
			return null;
		}
		
		// data
		var data = {
				paymentAddr: paymentAddr,
				fromChain: $.config.fromChain.coin, 
				toChain: $.config.toChain.coin,
				fromAmount: fromAmount,
				toAmount: toAmount,
				fromAddr: fromAddr,
				toAddr: toAddr
		};
		return data;
	};
	
	$.submit = function(data) {
		// $.ajax({
		// 	type: "post",
		// 	url: "/api/save",
		// 	data: data,
		// 	dataType : "jsonp",
		// 	traditional: true,
		// 	success: function(msg){
		// 	}
		// });
	};
	
	$.queryPaymentAddr = function(callback){
		callback("0xe77777f0F3F35F1FF34ccC22AB84AFaFA7777777");
		
		// $.ajax({
		// 	type: "get",
		// 	url: "/api/paymentAddr",
		// 	data: {chain: "BNB"},
		// 	dataType : "jsonp",
		// 	traditional: true,
		// 	success: function(paymentAddr){
		// 		callback(paymentAddr);
		// 	}
		// });
	};
});