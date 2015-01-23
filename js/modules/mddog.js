'use strict'

$(function(){
    if($('.MdBuffer').find('.BufferEdit.Source').length){
	var changeFlg = false;
	$(window).on('beforeunload', function(){
	    if(changeFlg){
                 //変更があったときはAJAXで一時保存します
//		return '!!!';
		return;
	    }
	});
	$('.Canvas').find('textarea').change(function(){
	    changeFlg = true;
	});
    }
});
