'use strict'

define(function(){
    var outlineViewer = function(){};
    outlineViewer.prototype = {
        init: function(){
            this.movableMenu($('.OutlineMenu'));

            $('#headlineBtn').on('click', $.proxy(function(){
                $('#headline').animate({
                    'left': 0
                }, 500, this.updateHeadline());
            }, this));
            var menuWidth = $('#headline').outerWidth();
            $('.Headline .CloseBtn').on('click', $.proxy(function(){
                $('#headline').animate({
                    'left': -menuWidth
                }, 500, this.clearHeadline());
            }, this));

        },

        movableMenu: function(leftmenu){
            var off     = leftmenu.offset();
            var menuFlg = false;
            $(window).scroll($.proxy(function(){
                var p = $(window).scrollTop();
                if( !menuFlg && p >= off.top ){
                    menuFlg = this.toggleMenu(leftmenu);
                }else if( menuFlg && p < off.top ){
                    menuFlg = this.toggleMenu(leftmenu, menuFlg);
                }
            }, this));
        },

        toggleMenu: function(leftmenu, flg){
            if(flg){
                leftmenu.css({
                    "position": "absolute",
                    "top": "auto"
                }); 
            }else{
                leftmenu.css({
                    "position": "fixed",
                    "top": "0"
                }); 
            }
            return !flg;
        }

    };

    return outlineViewer;
});
