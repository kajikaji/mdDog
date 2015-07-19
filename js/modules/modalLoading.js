'use strict'

define(function(){
    var modalLoading = function(){
        this.modal = $('<div>').addClass('ModalLoading').append(
            $('<div>')
                .addClass('Loading')
                .append(
                $('<img>').attr('src', '/img/ajax-loader.gif')
                )
        );
    };

    modalLoading.prototype = {
        show: function(proc){
            var $height = $(window).height();
            var $width = $(window).width();
            this.modal.css({'height': $height + "px", 'width' : $width + "px"});
            $('body').prepend(this.modal);
            setTimeout(proc, 10);
        },
        remove: function(){
            this.modal.remove();
        }
    };

    return modalLoading;
});
