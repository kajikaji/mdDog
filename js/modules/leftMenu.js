'use strict'

define(function(){
    var leftMenu = function(){};
    leftMenu.prototype = {
        movableMenu: function(menu){
            var off     = menu.offset();
            var menuFlg = false;
            $(window).scroll($.proxy(function(){
                var p = $(window).scrollTop();
                if( !menuFlg && p >= off.top ){
                    menuFlg = this.toggleMenu(menu);
                }else if( menuFlg && p < off.top ){
                    menuFlg = this.toggleMenu(menu, menuFlg);
                }
            }, this));
        },

        toggleMenu: function(menu, flg){
            if(flg){
                menu.css({
                    "position": "absolute",
                    "top": "auto"
                }); 
            }else{
                menu.css({
                    "position": "fixed",
                    "top": "0"
                }); 
            }
            return !flg;
        },

        jumpToTop: function(btn) {
          btn.on('click', function(){
            $('html, body').animate({scrollTop: 0}, 'fast');
          });
        }
    };

    return leftMenu;
});