'use strict'

define(function(){
    var headline = function(){
    };

    headline.prototype = {
        init: function(){
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
        updateHeadline: function(){
            $('.BufferEdit.Markdown .Document').find('.Md').each(function(){
                var body = $(this).find('.MdBody');
                var id = $(this).attr('id');
                var tag = body[0].tagName;
                if( tag.match(/[hH][1-4]/) ){
                    var hd = $(body[0]).text();
                    if( hd.length > 10 ){
                        hd = hd.substring(0, 10);
                        hd += '...';
                    }
                    var hdlink = $('<a>').attr('href', '#' + id).text(hd);
                    var level = tag.replace(/h([1-4])/i, "$1");
                    var hdobj = $('<li>').append(hdlink).addClass("h" + level);
                    $('#headline .headlist').append(hdobj);
                }
            });
        },
        clearHeadline: function(){
            $('#headline .headlist').children().each(function(){
                $(this).remove();
            });
        }
    };

    return headline;
});

