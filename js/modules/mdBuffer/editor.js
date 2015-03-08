'use strict'
/*
 * マークダウンエディタの制御クラス
 */

define(function(){
    var editor = function(){};
    editor.prototype = {
        init: function() {
            require(['mdBufferFormCtrl', 'mdBufferDivideCtrl'], 
                $.proxy(function(FormCtrl, DivideCtrl){
                    var cnt = 0;
                    $('.BufferEdit.Markdown .Document').children().each($.proxy(function(i, elm){
                        var formCtrl = new FormCtrl($(elm), getParam("fid"));
                        formCtrl.init();
                        var mdObj = formCtrl.getMdParagraph();
                        $(mdObj).attr("id", "md" + i);

                        $('.BufferEdit.Markdown .Document').append(mdObj);
                        cnt++;
                    }, this));
                    if( cnt == 0 ){
                        var formCtrl = new FormCtrl($('<div>').addClass('Blank'), getParam("fid"));
                        formCtrl.init();
                        var mdObj = formCtrl.getMdParagraph();
                        $(mdObj).attr("id", "md-1");

                        $('.BufferEdit.Markdown .Document').append(mdObj);
                    }

                    new DivideCtrl().init();
            }, this));
        }
    };

    return editor;
});
