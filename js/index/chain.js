$(function(){
	
	$.transfer = function(data) {
		if (data.fromCoin == "0x") {
			var message = {from: $.walletAddress, to: data.paymentAddr, value: $.toWei(data.fromAmount)};
			$.web3.eth.sendTransaction(message, (error, res) => {
				$.errorProcess(error);
		    }).then(function(tx) {
				$.confirmPayment(data.key, tx.transactionHash);
				$.resultProcess(tx, function(){
				});
			});
		} else {
			var coininfo = $.config.chains[data.fromChain].coins[data.fromCoin];
			var amount = $.toWei(data.fromAmount, coininfo.unit, coininfo.decimals);
			$.coinContract(data.fromChain, data.fromCoin).methods
				.transfer(data.paymentAddr, amount)
				.send({from: $.walletAddress}, $.errorProcess)
				.then(function(tx) {
					$.confirmPayment(data.key, tx.transactionHash);
					$.resultProcess(tx, function(){
					});
				});
		}
		$.tips("Already submitted, waiting for confirmation.");
	};
	
});