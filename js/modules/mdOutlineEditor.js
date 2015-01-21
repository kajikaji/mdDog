'use strict'
/*
 * アウトラインエディターの制御クラス
 */

define(function(){
    var mdOutlineEditor = function(){};
    mdOutlineEditor.prototype = {
        init: function(){
            $('.OutlineEditor div.Document').children('.Md').each(function(){
                var id = $(this).attr("id");
                if(id === "blkTmpl" || id == "divideInfo"){
                    return;
                }
                var num = id.substr(2);
                var tag = this.tagName;
                var digest = $(this).text().substr(0, 6);
                $(this).hide();
                var blk = $('#blkTmpl').clone().removeAttr("id");
                blk.find('.Tagname').text(tag);
                blk.find('.Digest').text(digest);
                blk.find('a.BtnExpand').click(function(){
                    $('#'+id).toggle();
                });
                blk.find('button.DivideCtrl').attr('id', 'divide' + num).click(function(){
                    var action = 'divide';
                    if($(this).parent().next().next().hasClass('OutlineDivide')){
                        action = 'undivide';
                    }
                    $.ajax({
                        url: 'api/outlineEditor.cgi',
                        type: 'POST',
                        data: {
                            fid: getParam('fid'),
                            action: action,
                            num: parseInt(num) + 1,
                        }
                    }).done(function(res){
                        var num = res.num;
                        var target = $('#md' + num).prev('div.Blk');
                        if(action === 'divide'){
                            var divideObj = $('<div>').addClass('OutlineDivide');
                            target.before(divideObj);
                        }else if(action === 'undivide'){
                            target.prev('div.OutlineDivide').remove();
                        }

                        //メッセージを表示
                        if($('section.Message').is(":hidden")){
                            var info = $('<div>').addClass('Info').text("コミットされていないバッファがあります");
                            $('section.Message').append(info);
                            $('section.Message').show();
                        }
                    });
                });
                $(this).before(blk);
            });
            $('.OutlineEditor div.Document .DivideInfo').find('.Divide').each(function(){
                var num = $(this).text();
                var target = $('#md' + num).prev('div.Blk');
                var divideObj = $('<div>').addClass('OutlineDivide');
                target.before(divideObj);
            });
        }
    };

    return mdOutlineEditor;
});