'use strict'

define(function(){
    var popupHelper = function(target){
        this.targets = [];
        this.baloon = 'myPopup';
        this.flg = false;
    };
    popupHelper.prototype = {
        init: function(){
            $(document).find('.PopupHelper').each($.proxy(function(i, elm){
                this.targets.push(elm);
                $(elm).hover(
                    $.proxy(this.show, this),
                    $.proxy(this.hide, this));

            }, this));
        },
        show: function(ev){
            if( this.flg ){
                return;
            }
            var baloon = popupHelper.baloon().attr('id', this.baloon)
            var info   = $(ev.currentTarget).data('info').replace(/\\n/, '<br>');
            baloon.html(info);
            $('body').append(baloon);
            var margin = 2;
            var rect = ev.currentTarget.getBoundingClientRect();
            var scrlY = $(window).scrollTop();
            baloon.css({
                "top" : (rect.bottom + scrlY + 10 + margin) + "px",
                "left": (rect.left - 10) + "px"
            });
            this.flg = true;
        },
        hide: function(ev){
            if( $('#' + this.baloon).length ){
                $('#' + this.baloon).remove();
                this.flg = false;
            }
        }
    };
    popupHelper.baloon = function(){
           return $('<div>').addClass('PopupBaloon');
    };

    return popupHelper;
});
