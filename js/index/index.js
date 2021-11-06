$(function () {
	if ($.config.from) {
		$("title").text($.config.chains[$.config.from.chain].name + " - Security Token Assets Router");
	} else {
		return;
	}
	
	// init
	$.init = function() {
		$("#img_from").attr("src", "img/chain/" + $.config.from.chain + "/" + $.config.from.coin + ".png");
		if ($.config.from.coin == "0x") {
			$("#img_from_chain").hide();
		} else {
			$("#img_from_chain").show();
			$("#img_from_chain").attr("src", "img/chain/" + $.config.from.chain + ".png");
		}
		$("#img_to").attr("src", "img/chain/" + $.config.to.chain + "/" + $.config.to.coin + ".png");
		if ($.config.to.coin == "0x") {
			$("#img_to_chain").hide();
		} else {
			$("#img_to_chain").show();
			$("#img_to_chain").attr("src", "img/chain/" + $.config.to.chain + ".png");
		}
	};
	$.init();
	
	// input event
	var rate = 1;
	$("#input_from_amount").on('input', function() {
		var value = $(this).val();
		value = $.toAmount(value);
		$(this).val(value);
		$("#input_to_amount").val(value * rate);
	});
	$.inputFromAddrUpdate = function(walletAddress) {
		var inputFromAddr = $("#input_from_addr");
		inputFromAddr.val(walletAddress);
		inputFromAddr.attr("disabled", "disabled");
		inputFromAddr.change();
	};
	$.inputFromAddrChange = function() {
		if (Number($.config.from.chain) > 0 && Number($.config.to.chain) > 0) {
			$("#input_to_addr").val($(this).val());
			$("#input_to_addr").attr("disabled", "disabled");
		}
	};
	$("#input_from_addr").on('input', $.inputFromAddrChange);
	$("#input_from_addr").on('change', $.inputFromAddrChange);
	
	// click event
	$(".div_from_btn").on('click', function(){
		$.showPopup("Swap from ...", function(content) {
			content.setTemplateElement("from_select_template");
			content.processTemplate($.config);
			content.find(".div_select_item").each(function(){
				var that = $(this);
				that.on('click', function() {
					$.updateFromTo($.config.from.chain, that.attr("coin"));
					$.updateToList();
					$.init();
					$.hidePopup();
				});
			});
		});
	});
	$(".div_to_btn").on('click', function(){
		$.showPopup("Swap to ...", function(content) {
			content.setTemplateElement("to_select_template");
			content.processTemplate($.config);
			content.find(".div_select_item").each(function(){
				var that = $(this);
				that.on('click', function(){
					$.config.to.chain = that.attr("chain");
					$.config.to.coin = that.attr("coin");
					$.init();
					if (Number($.config.to.chain) <= 0) {
						$("#input_to_addr").val("");
						$("#input_to_addr").removeAttr("disabled");
					} else if (Number($.config.from.chain) > 0) {
						$("#input_to_addr").val($("#input_from_addr").val());
						$("#input_to_addr").attr("disabled", "disabled");
					}
					$.hidePopup();
				});
			});
		});
	});
	$.bindSubmitEvent = function(callback) {
		$(".btn_submit").unbind('click').on('click', function() {
			$.applyPayment(callback);
		});
	};
	$.bindQrcodeWindow = function() {
		$.bindSubmitEvent(function(data){
			$.showPopup("Scanning QR code ...", function(content) {
				content.setTemplateElement("qrcode_window_template");
				content.processTemplate($.config);
				
				// qrcode
				var addressQr = $('#address_qr');
				addressQr.html("");
				addressQr.qrcode({
					text: data.paymentAddr,
					width: 150,
					height: 150,
					correctLevel: 0,
					background: "rgba(71, 89, 101)",
				    foreground: "#32b1f5"
				});
				
				// text
				$("#span_amount").text(data.fromAmount);
				$("#span_paymentAddr").text(data.paymentAddr);
				$.copy('.btn_copy');
				
				// submit
				$(".btn_qrcode_submit").on('click', function(){
					$.confirmPayment(data.key);
				});
			});
		});
	};
	
	$("#a_switchChain").on('click', function(){
		$.showPopup("Switch Chain", function(content) {
			content.setTemplateElement("switch_chain_template");
			content.processTemplate($.config);
			content.find(".div_select_item").each(function(){
				var that = $(this);
				that.on('click', function() {
					window.location.href = "./index.html?fromChain=" + that.attr("chain");
				});
			});
		});
	});
	
	// start
	if (Number($.config.from.chain) > 0) {
		$.connectWallet(Number($.config.from.chain), $.config.chains[$.config.from.chain].name, function() {
			$.inputFromAddrUpdate($.walletAddress);
			$.bindSubmitEvent($.transfer);
		}, $.bindQrcodeWindow, 3000, "please transfer by scanning QR code");
	} else {
		$.tips("The current chain only supports transfer by scanning QR code", 3000);
		$.bindQrcodeWindow();
	}
});