'use strict'

define(function(){
    var leftMenu = function(obj){
        this.menu = obj;
        this.offset = undefined;
    };
    leftMenu.prototype = {
        movableMenu: function(){
            this.offset = this.menu.offset();
            var menuFlg = this.checkMenuPosition(false);
            $(window).scroll($.proxy(function(){
                menuFlg = this.checkMenuPosition(menuFlg);
            }, this));
        },

        checkMenuPosition: function(menuFlg) {
            var p = $(window).scrollTop();
            if( !menuFlg && p >= this.offset.top ){
                menuFlg = this.toggleMenu();
            }else if( menuFlg && p < this.offset.top ){
                menuFlg = this.toggleMenu(menuFlg);
            }
            return menuFlg;
        },

        toggleMenu: function(flg){
            if(flg){
                this.menu.css({"position": "absolute", "top": "auto"}); 
            }else{
                this.menu.css({"position": "fixed",    "top": "0"   }); 
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