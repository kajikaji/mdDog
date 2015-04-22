'use strict'

define(["leftMenu"], function(LeftMenu){
    var outlineViewer = function(){};
    outlineViewer.prototype = $.extend({}, LeftMenu.prototype, {
        init: function(){
            this.movableMenu($('.OutlineMenu'));

            if( $('#jumpTopBtn').length ){
                this.jumpToTop($('#jumpTopBtn'));
            }

            $('#headlineBtn').on('click', $.proxy(function(){
                $('#headline').animate({
                    'left': 0
                }, 500, this.updateHeadline());
            }, this));
            var menuWidth = $('#headline').outerWidth();
            $('.Headline .CloseBtn').on('click', $.proxy(function(){
                $('#headline').animate({
                    'left': -menuWidth
                }, 500, this.clearHeadline() );
            }, this));

        },
    
        updateHeadline: function() {
            //TODO:
        },

        clearHeadline: function() {
            //TODO:
        }
    });

    return outlineViewer;
});
