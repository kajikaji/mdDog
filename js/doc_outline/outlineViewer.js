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
            $('.Contents.Page').each(function(){
                $(this).find('ul.List li').each(function(){
                    var id = Number($(this).attr('id').substr(7));
                    var lv = $(this).hasClass('Level1')?1
                             :$(this).hasClass('Level2')?2
                             :$(this).hasClass('Level3')?3:4;
                    var hd = $(this).find(".Text").text();
                    if( hd.length > 10 ){
                        hd = hd.substring(0, 10);
                        hd += '...';
                    }

                    var hdlink = $('<a>').data('hdr', id).text(hd);
                    var hdobj = $('<li>').append(hdlink).addClass("h" + lv);
                    $('#headline .headlist').append(hdobj);
                    hdlink.click(function(){
                        var hdr = $(this).data('hdr');
                        var top = $('#document' + hdr).offset().top;
                        $('html, body').animate({scrollTop: top}, 'fast');
                    });

                });
            });
        },

        clearHeadline: function() {
            //TODO:
        }
    });

    return outlineViewer;
});
