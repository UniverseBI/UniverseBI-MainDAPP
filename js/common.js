$(function(){
	$.getParam = function (name) {
		var reg = new RegExp("(^|&)" + name + "=([^&]*)(&|$)","i");
		var r = window.location.search.substr(1).match(reg);
		if (r != null) {
			return decodeURI(r[2]);
		} else {
			return "";
		}
	};
	
	$.addParam = function (name, value) {
		var url = window.location.href;
		var s = url.indexOf("?") == -1 ? "?" : "&";
		window.history.pushState({}, 0, url + s + name +"=" + value);
	};
	
	$.setCookie = function (name, value) {
		var expires = (arguments.length > 2) ? arguments[2] : null;
		document.cookie = name + "=" + encodeURIComponent(value) + ((expires == null) ? "" : ("; expires=" + expires.toGMTString())) + ";path=/";
	};

	$.getCookie = function (name) {
		var value = document.cookie.match(new RegExp("(^| )" + name + "=([^;]*)(;|$)"));
		if (value != null) {
			return decodeURIComponent(decodeURIComponent(value[2]));
	    } else {
			return null;
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
	
	$.floatDiv = function (arg1, arg2) {
		var t1 = 0, t2 = 0, r1, r2;    
		try {
			t1 = arg1.toString().split(".")[1].length;
		} catch(e) {}
		try {
			t2 = arg2.toString().split(".")[1].length;
		} catch(e) {}
		with(Math) {
			r1 = Number(arg1.toString().replace(".", ""));
			r2 = Number(arg2.toString().replace(".", ""));
			return (r1 / r2) * pow(10, t2 - t1);
		}
	};
	
	$.setScale = function (value, scale, roundingMode) {
		if (roundingMode) {
			if (roundingMode.toLowerCase() == "roundhalfup") {
				return (Math.round(value * Math.pow(10, scale)) / Math.pow(10, scale)).toFixed(scale);
			} else if (roundingMode.toLowerCase() == "roundup") {
				return (Math.ceil(value * Math.pow(10, scale)) / Math.pow(10, scale)).toFixed(scale);
			}
		}
		return (Math.floor(value * Math.pow(10, scale)) / Math.pow(10, scale)).toFixed(scale);
	};
	
	$.copy = function(selecter) {
		if ($(selecter).length == 0) {
			return;
		}
		var clipboard = new ClipboardJS(selecter);
		clipboard.on('success', function(e) {
			$.tips("Copy success", 2000);
			e.clearSelection();
		});
		clipboard.on('error', function(e) {
			$.tips("Copy error", 2000);
		});
	};
	
	$.uuid = function () {
		function S4() {
			return (((1 + Math.random()) * 0x10000) | 0).toString(16).substring(1);
		}
		return (S4() + S4() + S4() + S4() + S4() + S4() + S4() + S4());
	};
	
	$.sleep = function(ms) {
		return new Promise((resolve) => {
			setTimeout(resolve, ms);
		});
	};
	
	$.loading = function(msg) {
		$.hideTips();
		var id = "id_div_loading";
		var loading = $('#' + id);
		if (loading.text().length == 0) {
			// loading
			loading = $("<div>");
			loading.css({
				"position": "fixed",
				"top": 0,
				"left": 0,
				"width": "100%",
				"height": "100%",
				"background-color": "rgba(0,0,0,.7)",
				"color": "#fff",
				"font-size": "14px",
				"display": "flex",
				"flex-direction": "column",
				"justify-content": "center",
				"align-items": "center",
				"z-index": 10002
			});
			loading.attr("id", id);
			loading.appendTo($("body"));
			
			var iconWarp = $("<span>");
			iconWarp.appendTo(loading);
			
			// icon
			var icon = $("<i>");
			icon.addClass("fa");
			icon.addClass("fa-spinner");
			icon.addClass("fa-pulse");
			icon.addClass("fa-3x");
			icon.addClass("fa-fw");
			icon.appendTo(iconWarp);
			
			// text
			var text = $("<div>");
			text.css("margin-top", "8px");
			text.text(msg);
			text.appendTo(loading);
		} else {
			var text = loading.children("div");
			text.text(msg)
			loading.show();
		}
	};
	
	$.hideLoading = function() {
		$('#id_div_loading').hide();
	};
	
	$.dialog = function(msg, ms) {
		$.hideTips();
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
			
			// text
			var text = $("<div>");
			text.text(msg);
			text.appendTo(dialog);
		} else {
			var text = dialog.children("div");
			text.text(msg);
			dialog.show();
		}
		
		// public
		if (ms > 0) {
			setTimeout(function () {
				dialog.hide();
			}, ms);
		}
	};
	
	$.hideDialog = function() {
		$('#id_div_dialog').hide();
	};
	
	$.tips = function(msg, ms) {
		if (ms) {
			$.dialog(msg, ms);
		} else {
			$.loading(msg);
		}
	};
	
	$.hideTips = function() {
		$.hideDialog();
		$.hideLoading();
	};
	
	$.showOverlay = function() {
		var id = "id_div_overlay";
		var overlay = $('#' + id);
		if (! overlay.css("display")) {
			overlay = $("<div>");
			overlay.css({
				"position": "fixed",
				"top": 0,
				"left": 0,
				"width": "100%",
				"height": "100%",
				"background-color": "rgba(0,0,0,.5)",
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
			var header = $("<div>");
			header.css({
				"font-size": "20px",
				"color": "#fff",
				"line-height": 1.5,
				"text-align": "left",
				"border-bottom": "1px solid rgba(71,89,101,.3)",
				"padding": "1rem"
			});
			header.appendTo(popup);
			
			// title
			var titleSpan = $("<span>");
			titleSpan.text(title);
			titleSpan.appendTo(header);
			
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
	
});