'use strict'
/*
 * マークダウンエディタの制御クラス
 */

define(function(){
    var editor = function(){};
    editor.prototype = {
        init: function() {
            require(['mdBufferFormCtrl', 'mdBufferDivideCtrl'], function(FormCtrl,DivideCtrl){
                $('.BufferEdit div.Document').children().each(function(){
                    if($(this).hasClass("Md")){
                        $(this).hover(
                            function(){ $(this).addClass('Focus'); },
                            function(){ $(this).removeClass('Focus'); }
                        );
                        $(this).click(function(){
                            new FormCtrl($(this), getParam("fid")).init();;
                        });
                    }else{
                        $(this).addClass("Uneditable");
                    }
                });
                if($('.BufferEdit div.Document').children().length === 0){
                    var blank = $('<div>').addClass("Blank").attr("id", "md-1");
                    $('.BufferEdit div.Document').append(blank);
                    blank.hover(
                        function(){ blank.addClass('Focus'); },
                        function(){ blank.removeClass('Focus'); }
                    );
                    blank.click(function(){
                        new FormCtrl(blank, getParam("fid")).init();;
                    });
                }
                //アウトラインでページ分割
                new DivideCtrl().init();
            });
        }
    };

    return editor;
});
