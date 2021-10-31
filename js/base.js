$(function(){
	// base
	$.getParam = function (name) {
		var reg = new RegExp("(^|&)" + name + "=([^&]*)(&|$)","i");
		var r = window.location.search.substr(1).match(reg);
		if (r != null) {
			return decodeURI(r[2]);
		} else {
			return "";
		}
	};
	
	$.floatMul = function (arg1, arg2) {
		var m = 0, s1 = arg1.toString(), s2 = arg2.toString();
		try {
			m += s1.split(".")[1].length;
		} catch(e) {}
		try {
			m += s2.split(".")[1].length;
		} catch(e) {}
		return Number(s1.replace(".", "")) * Number(s2.replace(".", "")) / Math.pow(10, m);
	};
	
	$.copy = function(selecter, successCallback) {
		if ($(selecter).length == 0) {
			return;
		}
		var clipboard = new ClipboardJS(selecter);
		clipboard.on('success', function(e) {
			$.dialog("Copy success", 1000);
			e.clearSelection();
		});
		clipboard.on('error', function(e) {
			$.dialog("Copy error", 1000);
		});
	};
	
	$.sleep = function(ms) {
		return new Promise((resolve) => {
			setTimeout(resolve, ms);
		});
	};
	
	$.logo = function(coin){
		return "img/coin/" + coin + ".png";
	};
	
	$.dialog = function(msg, ms, lodding) {
		$.hideDialog();
		var id = "id_div_dialog";
		var dialog = $('#' + id);
		if (dialog.text().length == 0) {
			// dialog
			dialog = $("<div>");
			dialog.css({
				"position": "fixed",
				"top": "50%",
				"left": "50%",
				"margin-left": "-90px",
				"margin-top": "-39px",
				"width": "150px",
				"padding": "15px",
				"color": "#fff",
				"font-size": "14px",
				"line-height": "20px",
				"text-align": "center",
				"background-color": "rgba(0,0,0,.7)",
				"border-radius": "8px",
				"z-index": 10002
			});
			dialog.attr("id", id);
			dialog.appendTo($("body"));
			
			// icon
			var icon = $("<i>");
			icon.addClass("fa");
			icon.addClass("fa-spinner");
			icon.addClass("fa-pulse");
			icon.addClass("fa-3x");
			icon.addClass("fa-fw");
			icon.appendTo(dialog);
			
			// text
			var text = $("<div>");
			text.css("margin-top", "8px");
			text.text(msg);
			text.appendTo(dialog);
		} else {
			var text = dialog.children("div");
			text.text(msg)
			dialog.show();
		}
		
		// public
		if (lodding) {
			dialog.find("i").show();
		} else {
			dialog.find("i").hide();
		}
		if (ms > 0) {
			setTimeout(function () {
				dialog.hide();
			}, ms);
		}
	};
	
	$.hideDialog = function() {
		$('#id_div_dialog').hide();
	};
	
	$.showOverlay = function() {
		var id = "id_div_overlay";
		var overlay = $('#' + id);
		if (overlay.text().length == 0) {
			overlay = $("<div>");
			overlay.css({
				"position": "fixed",
				"top": 0,
				"left": 0,
				"width": "100%",
				"height": "100%",
				"background-color": "rgba(0,0,0,.7)",
				"z-index": 10000
			});
			overlay.addClass("class_div_popup");
			overlay.attr("id", id);
			overlay.appendTo($("body"));
			overlay.on('click', function(){
				$.hidePopup();
			});
		} else {
			overlay.show();
		}
	};
	
	$.showPopup = function(title, callback) {
		$.showOverlay();
		var id = "id_div_popup";
		var popup = $('#' + id);
		if (popup.text().length == 0) {
			// popup
			popup = $("<div>");
			popup.css({
				"background-color": "#2c313b",
				"border-radius": "16px 16px 0 0",
				"bottom": 0,
				"left": 0,
				"right": 0,
				"width": "100%",
				"position": "fixed",
				"z-index": 10001,
				"max-width": "450px",
				"margin": "auto",
				"font-family": "Ubuntu,Roboto,sans-serif"
			});
			popup.addClass("class_div_popup");
			popup.attr("id", id);
			popup.appendTo($("body"));
			
			// header
			var header = $("<div><span>" + title + "</span><i class='fa fa-times' aria-hidden='true'></i></div>");
			header.text(title);
			header.css({
				"font-size": "20px",
				"color": "#fff",
				"line-height": 1.5,
				"text-align": "left",
				"border-bottom": "1px solid rgba(71,89,101,.3)",
				"padding": "1rem"
			});
			header.appendTo(popup);
			
			// close
			var close = $("<i>");
			close.addClass("fa");
			close.addClass("fa-times");
			close.attr("aria-hidden", true);
			close.css({
				"top": "1rem",
				"position": "absolute",
				"right": "0",
				"padding": "0 16px",
				"color": "#c8c9cc",
				"font-size": "22px",
				"line-height": "inherit"
			});
			close.appendTo(header);
			close.on('click', function(){
				$.hidePopup();
			});
			
			// content
			var content = $("<div>");
			content.appendTo(popup);
			callback(content);
		} else {
			var children = popup.children("div");
			var header = children.first();
			header.children("span").text(title);
			var content = children.last();
			callback(content);
			popup.show();
		}
	};
	
	$.hidePopup = function() {
		$(".class_div_popup").hide();
	};
	
	/* *********************** page ************************* */
	
	$.bindSubmitEvent = function(callback) {
		$(".btn_submit").on('click', function() {
			$.queryPaymentAddr(function(paymentAddr){
				var data = $.getSubmitData(paymentAddr);
				if (! data) return;
				callback(data);
			});
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
				$("#input_paymentAddr").val(data.paymentAddr);
				$.copy('.btn_copy');
			});
		});
	};
	
	$.inputFromAddrUpdate = function(walletAddress) {
		var inputFromAddr = $("#input_from_addr");
		inputFromAddr.val(walletAddress);
		inputFromAddr.attr("disabled", "disabled");
		inputFromAddr.change();
	};
});