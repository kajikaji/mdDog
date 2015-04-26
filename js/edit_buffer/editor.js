'use strict'
/*
 * マークダウンエディタの制御クラス
 */

define(function(){
    var editor = function(){};
    editor.prototype = {
        init: function() {
            require(['editBufferParagraphCtrl', 'editBufferDivideCtrl'], 
                $.proxy(function(ParagraphCtrl, DivideCtrl){
                    var cnt = 0;
                    $('.BufferEdit.Markdown .Document').children().each($.proxy(function(i, elm){
                        var paragraph = new ParagraphCtrl($(elm), getParam("fid"));
                        paragraph.init();
                        var mdObj = paragraph.getMdParagraph();
                        $(mdObj).attr("id", "md" + i);
                        $(mdObj).find('.Raw').text($('#raw' + i).text());
                        $('#raw' + i).remove();
                        $('.BufferEdit.Markdown .Document').append(mdObj);
                        cnt++;
                    }, this));
                    if( cnt == 0 ){
                        var paragraph = new ParagraphCtrl($('<div>').addClass('Blank'), getParam("fid"));
                        paragraph.init();
                        var mdObj = paragraph.getMdParagraph();
                        $(mdObj).attr("id", "md-1");

                        $('.BufferEdit.Markdown .Document').append(mdObj);
                    }

                    new DivideCtrl().init();
            }, this));
        }
    };

    return editor;
});
