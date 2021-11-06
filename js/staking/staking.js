$(function(){
	$("title").text($.config.currChain.name + " - Staking");
	$("#title").text("Staking For " + $.config.currChain.name);
	$(".div_main").setTemplateElement("project_template");
	$(".div_main").processTemplate($.config.currChain);
	var ref = $.getParam("ref");
	if (ref) $.setCookie("ref", ref);
	
	$.queryContract = function(index) {
		$.queryUser($.config.currChain.projects[index], function(obj) {
			var div = $("#index_" + index);
			div.find(".stake_coin_balance").text($.setScale(obj.stakedBalance, 6));
			div.find(".reward_coin_balance").text($.setScale(obj.rewardBalance, 6));
			if (index < $.config.currChain.projects.length - 1) {
				$.queryContract(++index);
			} else {
				$.hideTips();
			}
		});
	};
	$.init = function() {
		if ($.config.currChain.projects.length > 0) {
			$("#a_invitation").show();
			$.tips("Query user info");
			$.queryContract(0);
		}
	};
	$.connectWallet($.config.currChain.chainId, $.config.currChain.name, $.init);
	
	$.popupInit = function(content, project) {
		// show
		content.setTemplateElement("details_template");
		content.processTemplate(project);
		if (project.queryUser.stakedAllowance == 0) {
			$("#btn_deposit").hide();
			$("#btn_withdraw").hide();
		} else {
			$("#btn_withdraw").hide();
			$("#btn_approve").hide();
		}
		if (project.queryUser.amount == 0) {
			$("#tabs_withdraw").hide();
			$("#tabs_deposit").hide();
			$("#tabs_s").hide();
		}
		
		// bind event
		$("#input_amount").on('input', function(){
			var value = $(this).val();
			var max = $("#btn_max").attr("max");
			value = $.toAmount(value, max);
			$(this).val(value);
		});
		
		$("#btn_max").on('click', function(){
			var max = $(this).attr("max");
			if (max > 0) {
				if (project.stake.address == "0x") {
					$.tips("Please reserve 1 " + $.config.currChain.nativeCurrencyName + " gas fee", 2000);
					if (max < 1) {
						$("#input_amount").val(0);
					} else {
						$("#input_amount").val(max - 1);
					}
				} else {
					$("#input_amount").val(max);
				}
			} else {
				$.tips("Insufficient balance", 2000);
			}
		});
		
		$("#btn_refresh").on('click', function(){
			$.tips("query user info");
			$.queryUser(project, function(obj){
				$.popupInit(content, project);
				$.hideTips();
			});
		});
		
		if (project.queryUser.pendingReward > 0) {
			$("#btn_claim").on('click', function(){
				$.deposit(project, "0", project.ref);
			});
		} else {
			$("#btn_claim").hide();
		}
		
		$("#tabs_deposit").on('click', function(){
			$("#tabs_withdraw").removeClass("span_method");
			$("#tabs_deposit").addClass("span_method");
			$("#btn_max").show();
			$("#btn_withdraw").hide();
			$("#btn_deposit").show();
			$("#input_amount").val("");
			$("#input_amount").removeAttr("disabled");
		});
		
		$("#tabs_withdraw").on('click', function(){
			$("#tabs_deposit").removeClass("span_method");
			$("#tabs_withdraw").addClass("span_method");
			$("#btn_max").hide();
			$("#btn_deposit").hide();
			$("#btn_withdraw").show();
			$("#input_amount").val(project.queryUser.amount);
			$("#input_amount").attr("disabled", "disabled");
		});
		
		$("#btn_approve").on('click', function(){
			$.approve(project);
		});
		
		$("#btn_deposit").on('click', function(){
			// amount
			var amount = $("#input_amount").val();
			if (! amount) {
				$.tips("amount is null", 2000);
				return;
			}
			
			// ref
			var ref = $.getCookie("ref");
			if (ref && ref != ""){
				if(! $.web3.utils.isAddress(ref)){
					$.tips("referrer address error", 2000);
					return;
				}
			} else {
				ref = project.ref;
			}
			$.deposit(project, amount, ref);
		});
		
		$("#btn_withdraw").on('click', function(){
			$.withdraw(project);
		});
	};
	
	$(".div_content").on('click', function(){
		var id = $(this).attr("id");
		var index = id.substring(id.indexOf("_") + 1, id.length);
		var project = $.config.currChain.projects[index];
		$.showPopup($(this).find("label").text(), function(content) {
			$.popupInit(content, project);
		});
	});
	
	$("#a_invitation").on('click', function(){
		$.showPopup("Invitation link", function(content) {
			content.setTemplateElement("invitation_template");
			content.processTemplate();
			
			// text
			var ref_url = window.location.protocol + "//" + window.location.host + "/staking.html?ref=" + $.walletAddress;
			$("#span_link").text(ref_url);
			$.copy('.btn_copy');
			
			// qr
			$('#ref_qr').qrcode({
				text: ref_url,
				width: 150,
				height: 150,
				correctLevel: 0,
				background: "rgba(71, 89, 101)",
			    foreground: "#32b1f5"
			});
		});
	});
});