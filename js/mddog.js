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

/***********************************************
 * 初回実行
 ***********************************************/
$(function(){

    $('div.document').children().each(function(){
        $(this).hover(
            function(){ $(this).addClass('forcus'); },
            function(){ $(this).removeClass('forcus'); }
        );
        $(this).click(function(){
            var obj = $(this);
            var id = obj.attr('id').slice(2); // id='md*'
	    var data = $('#elm-' + id).text();
	    var editform = $('#editform').clone().attr('id','edit-' + id);
	    var ta = editform.find('textarea.editdata');
            ta.text(data);
	    var n = data.match(/\n/g).length + 1;
	    ta.attr('rows', n);
	    editform.show();
	    obj.after(editform);
	    obj.hide();

            //更新
	    editform.find('button.update').click(function(){
		var editform = $(this).parent();
		var fid = getParam("fid");
		var eid = editform.attr('id').slice(5);
		var data = editform.find('textarea.editdata').val();
		$.ajax({
		    url: 'api/mdEditor.cgi',
		    type: 'POST',
		    data:{fid: fid, eid: eid, data: data}
		}).done(function(res){
		    $('#edit-' + res.eid).remove();
		    var $newObj = $(res.md);
                    $('#md' + res.eid).attr('id', 'md' + res.eid + 'org');
		    $newObj.attr('id', 'md' + res.eid);
		    $('#md' + res.eid + 'org').after($newObj);
		    $('#md' + res.eid + 'org').remove();
		    $newObj.show();
		    $('#elm-' + res.eid).text(res.data);
		});
	    });

            //削除
	    editform.find('button.delete').click(function(){

	    });

            //キャンセル
	    editform.find('button.cancel').click(function(){
		var editform = $(this).parent();
		var id = editform.attr('id').slice(5);		
		editform.remove();
		$('#md' + id).show();
	    });
        });
    });
});
