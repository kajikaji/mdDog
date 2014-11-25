/***********************************************
 * 関数定義
 ***********************************************/
function activeBufferList(uid) {
    $('#buffer-list').find('li').each(function(){
        var id = Number($(this).attr("id").substr(7));
        if(uid === id){
            $(this).addClass("active");
        }else{
            $(this).removeClass("active");
        }
    });
}

function showLog(uid) {
    $('.gitlog .logtable').each(function(){
        var id = $(this).attr("id").substr(11);
        if(uid != id && !$(this).is(":hidden")){
              $(this).hide();
        }else if(uid == id && $(this).is(":hidden")){
            $(this).show();
        }
    });
    activeBufferList(uid);
}

function getParam(key) {
    var url = location.href;
    var param = url.split("?");
    var params = param[1].split("&");
    for( var i=0; i < params.length; i++ ){
	var pCols = params[i].split("=");
	if(pCols[0] === key){
	    return pCols[1];
	}
    }
    return null;
}

var mdEditForm = function(obj){
    this.src = obj;
    this.id;
    this.elmId;
    this.mdId;
    this.formId;
    this.formtmpl = 'editform';
    this.api = 'api/mdEditor.cgi';
};
mdEditForm.prototype = {
    init: function() {
        this.id = this.src.attr('id').slice(2);
        this.elmId = 'elm-' + this.id;
        this.mdId = 'md' + this.id;
        this.formId = 'edit-' + this.id;

        var newForm = $('#' + this.formtmpl).clone().attr('id', this.formId);
        var data= $('#' + this.elmId).text();
        var n = data.match(/\n/g).length + 1;
        newForm.find('textarea.editdata').text(data).attr('rows', n);
        this.src.after(newForm);
        newForm.show(); this.src.hide();

        this.attachButton();
    },

    attachButton: function(){
        $('#' + this.formId).find('button.update').click($.proxy(function(){
            this.btnUpdate();
        }, this));
        $('#' + this.formId).find('button.delete').click($.proxy(function(){
            this.btnDelete();
        }, this));
        $('#' + this.formId).find('button.cancel').click($.proxy(function(){
            this.btnCancel();
        }, this));
    },

    btnUpdate: function(){
	var fid = getParam("fid");
	var editdata = $('#' + this.formId).find('textarea.editdata').val();
	$.ajax({
	    url: this.api,
	    type: 'POST',
	    data:{
                fid: fid, 
                eid: this.id,
                action: 'update', 
                data: editdata
            }
	}).done($.proxy(function(res){
            this.updateSuccess(res);
	}, this));
    },
    btnDelete: function(){
	var fid = getParam("fid");
	$.ajax({
	    url: this.api,
	    type: 'POST',
	    data:{
                fid: fid, 
                eid: this.id,
                action: 'delete',
            }
	}).done($.proxy(function(res){
            this.deleteSuccess(res);
	}, this));
    },
    btnCancel: function(){
	$('#' + this.formId).remove();
	$(this.src).show();
    },

    updateSuccess: function(res){
	$('#' + this.formId).remove();
	var $newObj = $(res.md);
        $('#' + this.mdId).attr('id', this.mdId + 'org');
	$newObj.attr('id', this.mdId);
	$('#' + this.mdId + 'org').after($newObj);
	$('#' + this.mdId + 'org').remove();
	$newObj.show();
	$('#' + this.elmId).text(res.data);
    },
    deleteSuccess: function(res) {
	$('#' + this.formId).remove();
        $('#' + this.mdId).remove();
        $('#' + this.elmId).remove();
    }
};

/***********************************************
 * 初回実行
 ***********************************************/
$(function(){
    $('div.document').children().each(function(){
        $(this).hover(
            function(){ $(this).addClass('focus'); },
            function(){ $(this).removeClass('focus'); }
        );
        $(this).click(function(){
            var eForm = new mdEditForm($(this));
            eForm.init();
        });
    });
});
