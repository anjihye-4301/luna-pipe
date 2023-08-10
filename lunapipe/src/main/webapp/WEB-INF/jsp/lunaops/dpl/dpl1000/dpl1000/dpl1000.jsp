<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="/WEB-INF/jsp/lunaops/top/header.jsp"%>

<link rel='stylesheet' href='<c:url value='/css/lunaops/dpl.css'/>' type='text/css'>
<link rel="stylesheet" type="text/css" href="<c:url value='/js/highlight/styles/ir-black.css'/>">
<script type="text/javascript" src="<c:url value='/js/highlight/highlight.pack.js'/>"></script>


<script type="text/javascript" src="<c:url value='/vendors/bootstrap-progressbar/bootstrap-progressbar.js'/>"></script>
<link href="/vendors/bootstrap-progressbar/css/bootstrap-progressbar-3.3.4.min.css" rel="stylesheet">

<style type="text/css">
	.search_select select {font-size: 0.85em;}
	.search_select {width: 124px;height: 28px;margin: 0 5px 5px 0;}
	.search_box_wrap {width: calc(100% - 404px);} 
	.req_right_box {border-radius: 5px;}
	.req_left_table_wrap {width: 73%;}
	.bg-blue {background: #3498DB !important;color: #fff; }
	.sub_progress {
	    float: right;
	    display: inline-block;
	    position: relative;
	    width: 340px;
	    height: 28px;
	    margin: 0 5px;
	    border: 1px solid #ccc;
	}
</style>

<script type="text/javascript">

var dplJobGrid;

var dplJobSearchObj;


var jobStatusWaitTime = 5000;


var buildResultWaitTime = 3000;


var selJobStatusFlag = true;

var userJobStatusFlag = true;


var buildStartItem = null;


var jobConsoleLog = {};


var jobBuildingConsoleLog = '';


var ciId = '<c:out value="${requestScope.ciId}"/>';
var ticketId = '<c:out value="${requestScope.ticketId}"/>';
var dplId = '<c:out value="${requestScope.dplId}"/>';


var consoleTimer;

$(document).ready(function() {
	
	
	
	
	
	
	fnAxGrid5View();
	fnDplJobSearchSetting();
	
	
	gfnGuideStack("add",fnDpl1000GuideShow);
	
	
	$(".bldLogBtn").click(function(){
		var logType = $(this).attr("logtype");
		
		
		var selJobInfo = dplJobGrid.getList('selected')[0];
		
		
		if(logType == "main"){
			
			if(jobConsoleLog.hasOwnProperty("bldConsoleLog")){
				
				if(gfnIsNull(jobConsoleLog.bldConsoleLog)){
					$('#buildConsoleLog').text("-");
				}else{
					
					$('#buildConsoleLog').html(jobConsoleLog.bldConsoleLog);
					$('#buildConsoleLog').each(function(i, block) {hljs.highlightBlock(block);});
					$("#buildConsoleLog").scrollTop(9999999);
				}
			}
		}
		
		else if(logType == "sub"){
			
			if(jobConsoleLog.hasOwnProperty("bldConsoleRestoreLog")){
				
				if(gfnIsNull(jobConsoleLog.bldConsoleRestoreLog)){
					$('#buildConsoleLog').text("-");
				}else{
					
					$('#buildConsoleLog').html(jobConsoleLog.bldConsoleRestoreLog);
					$('#buildConsoleLog').each(function(i, block) {hljs.highlightBlock(block);});
					$("#buildConsoleLog").scrollTop(9999999);
				}
			}
		}
		
		
		$("button.logBtnActive").removeClass("logBtnActive");
		
		$(this).addClass("logBtnActive");
	});
	
	
	$("#btn_update_dplAction").click(function(){
		var item = dplJobGrid.getList('selected')[0];
		if(gfnIsNull(item)){
			toast.push('실행(빌드)하려는 JOB을 선택해주세요.');
			return;
		}
		
		jConfirm("선택 JOB("+item.jobId+")을 수동 실행 하시겠습니까?","알림창",
			function(result) {
				if (result) {
					
					fnDplStart(item);
					return;
					
					
					
					var list = dplJobGrid.list;
					
					var bldProgressChk = false;
					
					
					if(!gfnIsNull(list)){
						$.each(list,function(idx, map){
							if(!gfnIsNull(map.bldResult)){
								var bldResult = map.bldResult.toLowerCase();
								
								if(bldResult == "progress" || bldResult == "start"){
									bldProgressChk = true;
								}
							}
						});
					}
					
					
					if(bldProgressChk){
						jAlert("이미 실행중인 JOB이 존재합니다.", "알림창");
					}else{
						
						fnDplStart(item);
					}
					
				}
			}
		);
		
	});
	
	
	$(".dplFullScreanBtn").click(function(){
		var $thisObj = $(this);
		
		var fullMode = $thisObj.attr("fullmode");
		
		var $targetObj = $("div.frame_contents[fullmode="+fullMode+"]");
		
		
		var fullCheck = $targetObj.hasClass("full_screen");
		
		
		if(fullCheck){
			$targetObj.removeClass("full_screen");
			$thisObj.children("i").addClass("fa-expand");
			$thisObj.children("i").removeClass("fa-compress");
			
			if($(".frame_contents.full_screen").length == 0){
				$("#bottomJobInfoFrame").addClass("bottomJobInfoFrame");
			}
		}else{
			
			if($(".frame_contents.full_screen").length == 0){
				$("#bottomJobInfoFrame").removeClass("bottomJobInfoFrame");
			}
			$targetObj.addClass("full_screen");
			$thisObj.children("i").removeClass("fa-expand");
			$thisObj.children("i").addClass("fa-compress");
		}
	});
	
	
	$("#btn_select_bldParam").click(function(){
		var jenId = $(this).data("jenId");
		var jobId = $(this).data("jobId");
		var bldNum = $(this).data("bldNum");
		
		var data = {
				"jenId" : jenId,
				"jobId" : jobId,
				"bldNum" : bldNum
		};
		
		
		gfnLayerPopupOpen('/jen/jen1000/jen1000/selectJen1006View.do',data,"840","300",'scroll');
	});
});


function fnJobStatusCheckLoop(){
	
	if(selJobStatusFlag && userJobStatusFlag && !gfnIsNull(dplJobGrid)){
	    
		var ajaxObj = new gfnAjaxRequestAction(
			{"url":"<c:url value='/dpl/dpl1000/dpl1000/selectDpl1100BldingJobList.do'/>","loadingShow":false}
			,"&pageNo="+dplJobGrid.page.currentPage+"&ciId="+ciId+"&ticketId="+ticketId+"&dplId="+dplId);
		
		ajaxObj.setFnSuccess(function(data){
			
			if(!gfnIsNull(data.bldingJobList) && data.bldingJobList.length > 0){
				
				var progressChk = false;

				
				var selJobInfo = dplJobGrid.getList('selected')[0];
				
				
				var bldingJobList = {};
				
				$.each(data.bldingJobList,function(idx, map){
					
					if(!bldingJobList.hasOwnProperty(map.jenId)){
						bldingJobList[map.jenId] = {};
					}
					
					if(!bldingJobList[map.jenId].hasOwnProperty(map.jobId)){
						bldingJobList[map.jenId][map.jobId] = {};
					}
					bldingJobList[map.jenId][map.jobId] = map;
				});
				
				
				$.each(dplJobGrid.list,function(idx, map){
					
					if(bldingJobList.hasOwnProperty(map.jenId) && bldingJobList[map.jenId].hasOwnProperty(map.jobId)){
						
						var bldJobInfoData = bldingJobList[map.jenId][map.jobId];
						
						
						if(!gfnIsNull(bldJobInfoData["bldResultCd"]) && map.bldResultCd != bldJobInfoData["bldResultCd"]){
							
							map.bldResultCd = bldJobInfoData["bldResultCd"];
							map.bldResult = bldJobInfoData["bldResult"];
							map.bldNum = bldJobInfoData["bldNum"];
							
							
							progressChk = true;
							
							
							if(!gfnIsNull(selJobInfo) && selJobInfo["jenId"] == map["jenId"] && selJobInfo["jobId"] == map["jobId"]) {
								fnJobBuildResultStatus(map);
							}
						}
					}
				});
				
				
				if(progressChk){
					dplJobGrid.repaint();
				}
			}
		   	
			
			setTimeout(fnJobStatusCheckLoop, jobStatusWaitTime);
		});
		
		
		ajaxObj.send();
	}else{
		
		setTimeout(fnJobStatusCheckLoop, jobStatusWaitTime);
	}
}


function fnJobBuildResultStatus(targetJobInfo){
	var targetJenId = targetJobInfo["jenId"];
	var targetJobId = targetJobInfo["jobId"];
	var targetBldNum = targetJobInfo["bldNum"];
	
	
	selJobStatusFlag = false;
	
	
	var selJobItem = dplJobGrid.getList('selected')[0];
	
	
	if(gfnIsNull(selJobItem) || targetJenId != selJobItem.jenId || !targetJobId == selJobItem.jobId){
		
		selJobStatusFlag = true;
		return true;
	}
	
	
	var ajaxObj = new gfnAjaxRequestAction(
			{"url":"<c:url value='/dpl/dpl1000/dpl1000/selectDpl1000JobConsoleLogAjax.do'/>","loadingShow":false}
			,{jenId: targetJobInfo.jenId, jobId: targetJobId, targetBldNum: targetBldNum});
	
	
	ajaxObj.setFnSuccess(function(data){
		if(data.errorYn == "Y"){
			jAlert("빌드 정보 조회 중 오류가 발생했습니다.</br>페이지를 새로고침해주세요.");
			return false;
		}
		
		
		var bldInfo = data.bldInfo;
		var bldChgList;
		var bldChgFileList;
		
		
		var jobInfo = data.jobMap;
		
		try{
			
			var consoleRefreshFlag = false;
			
			
			if(!gfnIsNull(bldInfo)){
				
				bldChgList = bldInfo["bldChgList"];
				bldChgFileList = bldInfo["bldChgFileList"];
			}else{
				
				fnBldFormDataReset();
				return false;
			}
			
			
			bldDetailFrameSet(jobInfo, bldInfo, bldChgList, bldChgFileList);
			
			
			if(!gfnIsNull(bldInfo["isBuilding"]) && bldInfo["isBuilding"]) {
				
				if(bldInfo["bldResultCd"] != selJobItem["bldResultCd"]){
					dplJobGrid.setValue(selJobItem.__original_index, "bldResult", bldInfo["bldResult"]);
					dplJobGrid.setValue(selJobItem.__original_index, "bldResultCd", bldInfo["bldResultCd"]);
				}
				
				
				$("#buildConsoleLog").append('<i class="fa fa-spinner fa-spin"></i>');
				$("#buildConsoleLog").scrollTop(9999999);
				
				
				var timestamp = bldInfo["bldStartDtm"];
				var estimatedDuration = bldInfo["bldEtmDurationTm"];
				
				
				var today = new Date().getTime();
				
				
				var durationTime = (today-parseInt(timestamp));
				
				
				var arriveDurationTime = estimatedDuration-durationTime;
				console.log("(estimatedDuration: "+estimatedDuration+") durationTime: "+durationTime+" / arriveDurationTime: "+arriveDurationTime );
				
				var arrTime = 99;
				
				
				if(arriveDurationTime > 0){
					
					var arrTime = (100*(durationTime/parseInt(estimatedDuration)));
					if(arrTime > 99){
						arrTime = 99;
					}
				}
				
				$("#bldProgressBar.progress .progress-bar").attr('data-transitiongoal', arrTime).progressbar2({display_text: 'center', percent_format: function(p) {return bldInfo["jobId"]+': ' + p+'%';}});
				
				
				consoleRefreshFlag = true;
			}else{
				
				if(!gfnIsNull(targetBldNum) && targetBldNum != bldInfo["bldNum"]){
					console.log("log 재 조회1");
					
					consoleRefreshFlag = true;
				}else{
					console.log("target bldnum: "+targetBldNum+" / bldnum: "+bldInfo["bldNum"]);
					
					console.log("기존 cd : "+selJobItem["bldResultCd"]+"  msg: "+selJobItem["bldResult"]);
					console.log("값 변경 cd : "+bldInfo["bldResultCd"]+"  msg: "+bldInfo["bldResult"]);
					
					dplJobGrid.setValue(selJobItem.__original_index, "bldResult", bldInfo["bldResult"]);
					dplJobGrid.setValue(selJobItem.__original_index, "bldResultCd", bldInfo["bldResultCd"]);
					
					$("#bldProgressBar.progress .progress-bar").attr('data-transitiongoal', 100).progressbar2({display_text: 'center', percent_format: function(p) {return bldInfo["jobId"]+': ' + p+'%';}});
					return false;
						
					
					$("#buildConsoleLog").scrollTop(9999999);
				}
			}
			
			
			if(consoleRefreshFlag){
				consoleTimer = setTimeout(function(){fnJobBuildResultStatus(targetJobInfo);}, buildResultWaitTime);
			}else{
				
				selJobStatusFlag = true;
				return false;
			}
		}catch(error){
			
			
			console.log(error);
			return false;
		}
		
	});
	
	
	ajaxObj.setFnError(function(xhr, status, err){
		
       	selJobStatusFlag = true;
	});
	
	
	ajaxObj.send();
}


function fnAxGrid5View(){
	dplJobGrid = new ax5.ui.grid();
 
        dplJobGrid.setConfig({
            target: $('[data-ax5grid="dplJobGrid"]'),
            showRowSelector: false,
            sortable:false,

            header: {align:"center",columnHeight: 30},
            columns: [
            	{key: "bldResultCd", label: " ", width: 30, align: "center"
					,formatter:function(){
						var result = this.item.bldResultCd;
						
						var faIcon = "circle";
						var iconColor = result;
						
						
						if(!gfnIsNull(result)){
							if(result == "04" || result == "10"){
								faIcon = "times-circle";
							}
							else if(result == "03"){
								faIcon = "check-circle";
							}else if(result == "01" || result == "02"){
								faIcon = "circle-notch fa-spin";
							}else if(result == "05"){
								faIcon = "exclamation-circle";
							}else{
								faIcon = "question-circle";
								iconColor = "etc";
							}
						}
						
						return '<i class="fas fa-'+faIcon+' result-'+result+'"></i>';
				}},
    			{key: "bldResult", label: "빌드 상태", width: 150, align: "center",
					formatter: function(){
						var result = this.item.bldResult;
						
						if(gfnIsNull(result)){
							result = "-";
						}
						return result;
					}},
    			{key: "bldNum", label: "빌드 번호", width: 80, align: "center"
    			},
    			{key: "jobStartOrd", label: "순서", width: 80, align: "center"},
              	{key: "jenNm", label: "JENKINS NAME", width: 211, align: "center"},
    			{key: "jobId", label: "JOB ID", width: 230, align: "center"},
    			{key: "jobTypeNm", label: "JOB TYPE", width: 95, align: "center"},
              	{key: "jenUrl", label: "JENKINS URL", width: 180, align: "center"},
              	{key: "jenDesc", label: "JENKINS 설명", width: 200, align: "center"},
    			{key: "jobDesc", label: "JOB 설명", width: 200, align: "center"},
          ],
            body: {
                align: "center",
                columnHeight: 30,
                onClick: function () {
                	
       				this.self.select(this.self.selectedDataIndexs[0]);
    				
    				
    				this.self.select(this.doindex);
                	
                	
                	$("#jobMaskFrame").hide();
                		
                	
               		fnJobBuildResultStatus(this.item);
                },onDBLClick:function(){
                	
					var data = {"jenId": this.item.jenId, "jobId": this.item.jobId};
					gfnLayerPopupOpen('/jen/jen1000/jen1000/selectJen1004JobDetailView.do',data,"1200", "870",'scroll');
                }
            },
            contextMenu: {
                iconWidth: 20,
                acceleratorWidth: 100,
                itemClickAndClose: false,
                icons: {
                    'arrow': '<i class="fa fa-caret-right"></i>'
                },
                items: [
                    {type: "detailPopup", label: "상세 정보", icon:"<i class='fa fa-info-circle' aria-hidden='true'></i>"},
                    {type: "detailParamPopup", label: "빌드 파라미터", icon:"<i class='fa fa-info-circle' aria-hidden='true'></i>"},
                ],
                popupFilter: function (item, param) {
                	var selItem = dplJobGrid.list[param.doindex];
                	
                	if(typeof selItem == "undefined"){
                		return false;
                	}
                	return true;
                },
                onClick: function (item, param) {
                	var selItem = dplJobGrid.list[param.doindex];

                    
					if(item.type == "detailPopup"){
						var data = {
							"jenId": selItem.jenId, "jobId": selItem.jobId
						};
						gfnLayerPopupOpen('/jen/jen1000/jen1000/selectJen1004JobDetailView.do',data,"1200", "870",'scroll');

						
					}else if(item.type == "detailParamPopup"){
						
						var data = {
								"ciId": selItem.ciId,
								"ticketId": selItem.ticketId,
								"dplId": selItem.dplId,
								"jenId" : selItem.jenId,
								"jobId" : selItem.jobId
						};
						
						
						gfnLayerPopupOpen('/dpl/dpl1000/dpl1000/selectDpl1001View.do',data,"840","300",'scroll');
					}
					dplJobGrid.contextMenu.close();
                    
                }
            },
            page: {
                navigationItemCount: 9,
                height: 30,
                display: true,
                firstIcon: '<i class="fa fa-step-backward" aria-hidden="true"></i>',
                prevIcon: '<i class="fa fa-caret-left" aria-hidden="true"></i>',
                nextIcon: '<i class="fa fa-caret-right" aria-hidden="true"></i>',
                lastIcon: '<i class="fa fa-step-forward" aria-hidden="true"></i>',
                onChange: function () {
                   fnInGridListSet(this.page.selectPage,dplJobSearchObj.getParam());
                }
            }
        });
        
 		fnInGridListSet();
}

function fnInGridListSet(_pageNo,ajaxParam){
   	
   	
   	if(gfnIsNull(ajaxParam)){
		ajaxParam = $('form#searchFrm').serialize();
	}
   	
   	
   	if(!gfnIsNull(_pageNo)){
   		ajaxParam += "&pageNo="+_pageNo;
   	}else if(typeof dplJobGrid.page.currentPage != "undefined"){
   		ajaxParam += "&pageNo="+dplJobGrid.page.currentPage;
   	}
   	
   	
   	ajaxParam += "&ciId="+ciId+"&ticketId="+ticketId+"&dplId="+dplId;
    	
    	
	var ajaxObj = new gfnAjaxRequestAction(
		{"url":"<c:url value='/dpl/dpl1000/dpl1000/selectDpl1100DplJobListAjax.do'/>","loadingShow":false}
		,ajaxParam);
	
	ajaxObj.setFnSuccess(function(data){
		
		var list = data.list;
		var page = data.page;
		
	   	dplJobGrid.setData({
			list:list,
			page: {
				currentPage: _pageNo || 0,
				pageSize: page.pageSize,
				totalElements: page.totalElements,
				totalPages: page.totalPages
			}
		});
	   	
	   	
		$("#buildConsoleLog").text("-");
	   	
	   	
		selJobStatusFlag = false;
	});
	
	
	ajaxObj.send();
}


function fnDplJobSearchSetting() {
	dplJobSearchObj = new AXSearch();

	var fnObjSearch = {
		pageStart : function() {
			
			dplJobSearchObj.setConfig({
				targetID : "dplJobSearch",
				theme : "AXSearch",
				rows : [ {
					display : true,
					addClass : "",
					style : "",
					list : [{label : "<i class='fa fa-search'></i>&nbsp;",labelWidth : "50",type : "selectBox",width : "",key : "searchSelect",addClass : "",valueBoxStyle : "",value : "all",
						options : [
							{optionValue : "rn",optionText : "전체 보기",optionAll : true}, 
							{optionValue : "jenNm",optionText : 'JENKINS 명'}, 
							{optionValue : "jenUrl",optionText : 'JENKINS URL'}, 
							{optionValue : "jobId",optionText : 'JOB ID'}, 
							{optionValue : "jobTypeCd", optionText : 'JOB 타입' , optionCommonCode:"DPL00002"},
						],
							onChange : function(selectedObject,value) {
									
									if (!gfnIsNull(selectedObject.optionAll) && selectedObject.optionAll == true) {
										axdom("#"+ dplJobSearchObj.getItemId("searchTxt")).attr("readonly","readonly");
										axdom("#"+ dplJobSearchObj.getItemId("searchTxt")).val('');
									} else {
										axdom("#"+ dplJobSearchObj.getItemId("searchTxt")).removeAttr("readonly");
									}
	
									
									if (!gfnIsNull(selectedObject.optionCommonCode)) {
										gfnCommonSetting(dplJobSearchObj,selectedObject.optionCommonCode,"searchCd","searchTxt");
									}  else {
										
										axdom("#"+ dplJobSearchObj.getItemId("searchTxt")).show();
										axdom("#"+ dplJobSearchObj.getItemId("searchCd")).hide();
									}
								}
								},
								{label : "",labelWidth : "",type : "inputText",width : "225",key : "searchTxt",addClass : "secondItem sendBtn",valueBoxStyle : "padding-left:0px;",value : "",
									onkeyup:function(e){
										if(e.keyCode == '13' ){
											axdom("#" + dplJobSearchObj.getItemId("btn_search_dlp")).click();
										}
									}
								},
								{label : "",labelWidth : "",type : "selectBox",width : "100",key : "searchCd",addClass : "selectBox",valueBoxStyle : "padding-left:0px;",value : "01",options : []},
								{label : "",labelWidth : "",type : "button",width : "70",key : "btn_print_newReqDemand",style : "float:right;",valueBoxStyle : "padding:5px;",value : "<i class='fa fa-print' aria-hidden='true'></i>&nbsp;<span>프린트</span>",
									onclick : function() {
										$(dplJobGrid.exportExcel()).printThis({importCSS: false,importStyle: false,loadCSS: "/css/common/printThis.css"});
									}
								},									
								{label : "",labelWidth : "",type : "button",width : "55",key : "btn_excel_newReqDemand",style : "float:right;",valueBoxStyle : "padding:5px;",value : "<i class='fa fa-file-excel' aria-hidden='true'></i>&nbsp;<span>엑셀</span>",
									onclick : function() {
										dplJobGrid.exportExcel("<c:out value='${sessionScope.selMenuNm }'/>.xls");
									}
								},
								{label : "",labelWidth : "",type : "button",width : "55",key : "btn_search_dlp",style : "float:right;",valueBoxStyle : "padding:5px;",value : "<i class='fa fa-list' aria-hidden='true'></i>&nbsp;<span>조회</span>",
									onclick : function() {
										
							            fnInGridListSet(0,dplJobSearchObj.getParam());
									}
								},
						]}]
					});
		}
	};

	jQuery(document.body).ready(
			function() {
				fnObjSearch.pageStart();
				
				axdom("#" + dplJobSearchObj.getItemId("searchTxt")).attr("readonly", "readonly");

				
				axdom("#" + dplJobSearchObj.getItemId("searchCd")).hide();

			});
	}
	

function fnDplStart(item){
	
	$(".progress .progress-bar").attr('data-transitiongoal', 0).progressbar2({display_text: 'center'});

	if(!gfnIsNull(item)){
		dplJobGrid.setValue(item.__original_index, "bldResultCd", "01");
		dplJobGrid.setValue(item.__original_index, "bldResult", "PROGRESS");
	}

	
	if(!gfnIsNull(consoleTimer)){
		clearTimeout(consoleTimer);
	}
	
	
	var ajaxObj = new gfnAjaxRequestAction(
			{"url":"<c:url value='/dpl/dpl1000/dpl1000/selectDpl1000JobBuildAjax.do'/>","loadingShow":false}
			,item);
	
	ajaxObj.setFnSuccess(function(data){
		if(data.errorYn == "Y"){
			jAlert(data.message, "알림창");
			
			dplJobGrid.setValue(item.__original_index, "bldResultCd", "10");
			dplJobGrid.setValue(item.__original_index, "bldResult", "SYSTEM ERROR");
			return false;
		}else{
			
			buildStartItem = item;

			
    		buildStartItem["bldNum"] = data.bldNum;
    		buildStartItem["estimatedDuration"] = data.estimatedDuration;
    		buildStartItem["bldActionLog"] = data.bldActionLog;

			
			dplJobGrid.setValue(item.__original_index, "bldResult", data.bldResult);
			dplJobGrid.setValue(item.__original_index, "bldResultCd", data.bldResultCd);
			dplJobGrid.setValue(item.__original_index, "bldNum", data.bldNum);
		}
		
		
		consoleTimer = setTimeout(function(){fnJobBuildResultStatus(dplJobGrid.getList('selected')[0]);}, buildResultWaitTime);
		
	});
	
	
	ajaxObj.send();
}


function fnDpl1000GuideShow(){
	var mainObj = $(".main_contents");
	
	
	if(mainObj.length == 0){
		return false;
	}
	
	var guideBoxInfo = globals_guideContents["dpl1000"];
	gfnGuideBoxDraw(true,mainObj,guideBoxInfo);
}


function fnJobAutoCheckMsgChg(successFlag, failureMsg){
	
	if(successFlag){
		$("#jobAutoCheckIcon").html('<i class="fas fa-spinner fa-spin  fa-blue"></i>');
		$("#jobAutoCheckMsg").html('JOB 실행 자동 모니터링 중');
		$("#jobAutoCheckTime").html("( 응답시간: 0 ms )");
		
		
		$("#btn_select_jobAutoCheckOn").hide();
		$("#btn_select_jobAutoCheckOff").show();
	}
	
	else{
		$("#jobAutoCheckIcon").html('<i class="fas fa-pause-circle fa-red"></i>');
		$("#jobAutoCheckMsg").html(failureMsg);
		$("#jobAutoCheckTime").html("( 응답시간: 0 ms )");
		
		
		$("#btn_select_jobAutoCheckOn").show();
		$("#btn_select_jobAutoCheckOff").hide();
	}
}


function fnJobAutoCheckSwitch(onOffValue){
	
	if(onOffValue){
		fnJobAutoCheckMsgChg(true);
		userJobStatusFlag = true;
	}
	
	else{
		fnJobAutoCheckMsgChg(false,"사용자에 의해 중지되었습니다.");
		
		
	}
}



function fnBldFormDataReset(){
	$("form#dpl1000JobInfoForm #jenNm").text("");
	$("form#dpl1000JobInfoForm #jenUrl").text("");
	$("form#dpl1000JobInfoForm #jobId").text("");
	$("form#dpl1000JobInfoForm #jobTypeNm").text("");
	$("#btn_select_bldParam").hide();
	
	
	$("form#dpl1000JobInfoForm #buildCauses").text("");
	$("form#dpl1000JobInfoForm #jobClass").text("");
	$("form#dpl1000JobInfoForm #building").text("");
	$("form#dpl1000JobInfoForm #buildDate").text("");
	$("form#dpl1000JobInfoForm #buildNumber").text("");
	$("form#dpl1000JobInfoForm #buildResult").text("");
	$("form#dpl1000JobInfoForm #buildDurationStr").text("");
	$("form#dpl1000JobInfoForm #buildEstimatedDurationStr").text("");
	$("form#dpl1000JobInfoForm #buildChgLog").html("");
	
	
	$("#buildConsoleLog").html("");
}


function bldDetailFrameSet(paramJobInfo, paramBldInfo, paramBldChgList, paramBldFileChgList){
	
	$("form#dpl1000JobInfoForm #jenNm").text(paramJobInfo.jenNm);
	$("form#dpl1000JobInfoForm #jenUrl").text(paramJobInfo.jenUrl);
	$("form#dpl1000JobInfoForm #jobId").text(paramJobInfo.jobId);
	$("form#dpl1000JobInfoForm #jobTypeNm").text(paramJobInfo.jobTypeNm);
	
	
	var ciIdStr = "-";
	var ticketIdStr = "-";
	var dplIdStr = "-";
	
	
	var buildCauses = "-";
	var building = false;
	var buildDate = "-";
	var buildNumber = "-";
	var buildResult = "-";
	var buildDurationStr = "-";
	var buildEstimatedDurationStr = "-";
	var buildChgLog = "-";
	var buildConsoleLog = "-";
	var jobClass = "-";
	$("#btn_select_bldParam").hide();
	
	if(!gfnIsNull(paramBldInfo)){
		try{
			
			ciIdStr = (paramBldInfo.hasOwnProperty("ciId"))?paramBldInfo["ciId"]:"-";
			ticketIdStr = (paramBldInfo.hasOwnProperty("ticketId"))?paramBldInfo["ticketId"]:"-";
			dplIdStr = (paramBldInfo.hasOwnProperty("dplId"))?paramBldInfo["dplId"]:"-";
		}catch(e){
			console.log(e);
		}
		try{
			
			jobClass = paramBldInfo["bldClass"];
			buildCauses = paramBldInfo["bldCauses"];
			buildDate = new Date(paramBldInfo["bldStartDtm"]).format("yyyy-MM-dd HH:mm:ss");
			buildNumber = paramBldInfo["bldNum"];
			buildResult = paramBldInfo["bldResult"];
			buildDurationStr = gfnHourCalc(paramBldInfo["bldDurationTm"]/1000);
			buildEstimatedDurationStr = gfnHourCalc(paramBldInfo["bldEtmDurationTm"]/1000);
			buildConsoleLog = paramBldInfo["bldConsoleLog"];
			
			
			if(paramBldInfo["bldParamCnt"] > 0){
				
				$("#btn_select_bldParam").data("bldNum", buildNumber);
				$("#btn_select_bldParam").data("jenId",paramBldInfo["jenId"]);
				$("#btn_select_bldParam").data("jobId",paramBldInfo["jobId"]);
				
				
				$("#btn_select_bldParam").show();
			}
		}catch(e){
			console.log(e);
		}
		try{
			
			var buildChgLogStr = "";
			
			
			if(!gfnIsNull(paramBldChgList)){
				
				var jobLastBuildFileChgMap = {};
				
				
				if(!gfnIsNull(paramBldFileChgList)){
					$.each(paramBldFileChgList, function(idx, map){
						
						if(!jobLastBuildFileChgMap.hasOwnProperty(map.bldNum)){
							jobLastBuildFileChgMap[map.bldNum] = {};
						}
						
						if(!jobLastBuildFileChgMap[map.bldNum].hasOwnProperty(map.chgRevision)){
							jobLastBuildFileChgMap[map.bldNum][map.chgRevision] = [];
						}
						
						
						jobLastBuildFileChgMap[map.bldNum][map.chgRevision].push(map);
					});
				}
				
				
				$.each(paramBldChgList, function(idx, map){
					
					var buildChgFileStr = "";
					
					buildChgLogStr += 
						'<div class="buildChgMainFrame">'
							+'<div class="buildChgHeader"><b>'+map.chgRevision+'</b> - '+map.chgUser+' ('+(new Date(parseInt(map.chgTimestamp)).format("yyyy-MM-dd HH:mm:ss"))+') </div>'
							+'<div class="buildChgBody">'+(map.chgMsg).replace(/\n/g,"</br>")+'</div>'
					
					
					if(jobLastBuildFileChgMap.hasOwnProperty(map.bldNum) && jobLastBuildFileChgMap[map.bldNum].hasOwnProperty(map.chgRevision)){
						
						$.each(jobLastBuildFileChgMap[map.bldNum][map.chgRevision], function(subIdx, subMap){
							buildChgFileStr += '<span class="buildFileChgLog fa '+subMap.editTypeCd+'">'+subMap.filePath+'</span>';
						});
						buildChgLogStr += '<div class="buildChgFooter">'+buildChgFileStr+'</div>';
					}
					buildChgLogStr += '</div>';
				});
				buildChgLog = buildChgLogStr;
			}
			
		}catch(e){
			console.log(e);
		}
		
		
		$("form#dpl1000JobInfoForm #buildCauses").text(buildCauses);
		$("form#dpl1000JobInfoForm #jobClass").text(jobClass);
		$("form#dpl1000JobInfoForm #building").text(building);
		$("form#dpl1000JobInfoForm #buildDate").text(buildDate);
		$("form#dpl1000JobInfoForm #buildNumber").text(buildNumber);
		$("form#dpl1000JobInfoForm #buildResult").text(buildResult);
		$("form#dpl1000JobInfoForm #buildDurationStr").text(buildDurationStr);
		$("form#dpl1000JobInfoForm #buildEstimatedDurationStr").text(buildEstimatedDurationStr);
		$("form#dpl1000JobInfoForm #buildChgLog").html(buildChgLog);
		
		
		$("#buildConsoleLog").html(buildConsoleLog);
		$("#buildConsoleLog").each(function(i, block) {hljs.highlightBlock(block);});
	}
}
</script>
<div class="main_contents" style="height: auto;">
	<div class="tab_contents menu" style="max-width: 1500px;position: relative;">
		<form:form commandName="dpl1000VO" id="searchFrm" name="searchFrm" method="post" onsubmit="return false"></form:form>
		<div id="dplJobSearch" style="border-top: 1px solid #ccc;" guide="dpl1000DplJobBtn"></div>
		<br />
		<div data-ax5grid="dplJobGrid" data-ax5grid-config="{}" style="height: 250px;" guide="dpl1000DplJobList"></div>
		<div class="main_frame middleJobInfoFrame">
			<div class="jobBuildAutoCheckDiv sub_title">
				<div class="jobAutoCheckIcon" id="jobAutoCheckIcon"></div>
				<div class="jobAutoCheckMsg" id="jobAutoCheckMsg"></div>
				<div class="jobAutoCheckTime" id="jobAutoCheckTime"></div>
				<button type="button" id="btn_select_jobAutoCheckOn" onclick="fnJobAutoCheckSwitch(true)" title="" placeholder="" style="width:120px;" class="AXButton searchButtonItem "><i class="fa fa-play-circle" aria-hidden="true"></i>&nbsp;<span>모니터링 재 시작</span></button>
				<button type="button" id="btn_select_jobAutoCheckOff" onclick="fnJobAutoCheckSwitch(false)" title="" placeholder="" style="width:120px;" class="AXButton searchButtonItem "><i class="fa fa-pause-circle" aria-hidden="true"></i>&nbsp;<span>모니터링 중지</span></button>
			</div>
		</div>
		<div class="main_frame bottomJobInfoFrame" id="bottomJobInfoFrame">
			<div class="jobMaskFrame" id="jobMaskFrame">상단의 배포계획을 선택해주세요.</div>
			<div class="frame_contents left" fullmode="1" guide="dpl1000DplJobBldInfo">
				<div class="sub_title">
					선택 JOB 정보
					<div class="sub_title_btn right">
						<div class="dplFullScreanBtn" fullmode="1"><i class="fas fa-expand"></i></div>
						<div class="progress progress_sm sub_progress" id="bldProgressBar">
							<div class="progress-bar bg-blue" role="progressbar" data-transitiongoal="100"></div>
						</div>
						<button type="button" id="btn_update_dplAction" title="" placeholder="" style="width:90px;" class="AXButton searchButtonItem "><i class="fa fa-play-circle" aria-hidden="true"></i>&nbsp;<span>수동 실행</span></button>
					</div>
				</div>
				<div class="jobDetailInfoFrame">
					<form name="dpl1000JobInfoForm" id="dpl1000JobInfoForm" onsubmit="return false;">
					<div class="descMainFrame">
						<div class="descSubFrame">
							<div class="descLabelFrame"><label>CI ID</label></div>
							<div class="descValueFrame">
								<span id="ciId"><c:out value="${requestScope.ciId}"/></span>
							</div>
						</div>
						<div class="descSubFrame">
							<div class="descLabelFrame"><label>TICKET ID</label></div>
							<div class="descValueFrame">
								<span id="ticketId"><c:out value="${requestScope.ticketId}"/></span>
							</div>
						</div>
					</div>
					<div class="descMainFrame">
						<div class="descSubFrame">
							<div class="descLabelFrame"><label>DPL ID</label></div>
							<div class="descValueFrame">
								<span id="dplId"><c:out value="${requestScope.dplId}"/></span>
							</div>
						</div>
						<div class="descSubFrame">
							<div class="descLabelFrame"><label>빌드 파라미터 값</label></div>
							<div class="descValueFrame">
								<button type="button" id="btn_select_bldParam" style="width:125px;display:none;" class="AXButton searchButtonItem"><i class="fa fa-external-link"></i>&nbsp;<span>보기</span></button>
							</div>
						</div>
					</div>
					<div class="descMainFrame">
						<div class="descLabelFrame"><label>JENKINS 명</label></div>
						<div class="descValueFrame">
							<span id="jenNm"></span>
						</div>
					</div>
					<div class="descMainFrame">
						<div class="descLabelFrame"><label>JENKINS URL</label></div>
						<div class="descValueFrame">
							<span id="jenUrl"></span>
						</div>
					</div>
					<div class="descMainFrame">
						<div class="descLabelFrame"><label>JOB ID</label></div>
						<div class="descValueFrame">
							<span id="jobId"></span>
						</div>
					</div>
					<div class="descMainFrame">
						<div class="descLabelFrame"><label>JOB _class</label></div>
						<div class="descValueFrame">
							<span id="jobClass"></span>
						</div>
					</div>
					<div class="descMainFrame">
						<div class="descSubFrame">
							<div class="descLabelFrame"><label></label></div>
							<div class="descValueFrame">
								<span></span>
							</div>
						</div>
						<div class="descSubFrame">
							<div class="descLabelFrame"><label>JOB 타입</label></div>
							<div class="descValueFrame">
								<span id="jobTypeNm"></span>
							</div>
						</div>
					</div>
					<div class="descMainFrame">
						<div class="descSubFrame">
							<div class="descLabelFrame"><label>building</label></div>
							<div class="descValueFrame">
								<span id="building""></span>
							</div>
						</div>
						<div class="descSubFrame">
							<div class="descLabelFrame"><label>빌드 일시</label></div>
							<div class="descValueFrame">
								<span id="buildDate"></span>
							</div>
						</div>
					</div>
					<div class="descMainFrame">
						<div class="descSubFrame">
							<div class="descLabelFrame"><label>빌드번호</label></div>
							<div class="descValueFrame">
								<span id="buildNumber"></span>
							</div>
						</div>
						<div class="descSubFrame">
							<div class="descLabelFrame"><label>빌드 결과</label></div>
							<div class="descValueFrame">
								<span id="buildResult"></span>
							</div>
						</div>
					</div>
					<div class="descMainFrame">
						<div class="descSubFrame">
							<div class="descLabelFrame"><label>예상 소요시간</label></div>
							<div class="descValueFrame">
								<span id="buildEstimatedDurationStr"></span>
							</div>
						</div>
						<div class="descSubFrame">
							<div class="descLabelFrame"><label>소요시간</label></div>
							<div class="descValueFrame">
								<span id="buildDurationStr"></span>
							</div>
						</div>
					</div>
					<div class="descMainFrame">
						<div class="descHeaderLabelFrame"><label>변경 내용</label></div>
						<div class="descBodyValueFrame" id="buildChgLog"></div>
					</div>
					</form>
				</div>
			</div>
			<div class="frame_contents right" fullmode="2" guide="dpl1000JobConsolLog">
				<div class="sub_title">
					빌드 실행 Console Log
					<div class="sub_title_btn right">
						<button type="button" id="btn_bldMainLog" title="" style="width:150px;" class="AXButton searchButtonItem bldLogBtn" logtype="main"><i class="fa fa-desktop" aria-hidden="true"></i>&nbsp;<span id="bldMainConsoleLog"></span></button>
						<button type="button" id="btn_bldSubLog" title="" style="width:150px;" class="AXButton searchButtonItem bldLogBtn" logtype="sub"><i class="fa fa-desktop" aria-hidden="true"></i>&nbsp;<span id="bldSubConsoleLog"></span></button>
						<div class="dplFullScreanBtn" fullmode="2"><i class="fas fa-expand"></i></div>
					</div>
				</div>
				<div id="contentsFrame">
					<pre>
						<code id="buildConsoleLog">-</code>
					</pre>
				</div>
			</div>
		</div>
	</div>
</div>

<jsp:include page="/WEB-INF/jsp/lunaops/bottom/footer.jsp" />