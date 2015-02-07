'use strict'

define(function(){
    $('section.Message ul.Info').children().each(function(){
	var closeBtn = $(this).find('.CloseBtn');
	closeBtn.click($.proxy(function(ev){
	    $(this).slideUp(300, function(){
		if( $('section.Message ul.Info').children().length === 1 ){
		    $('section.Message ul.Info').fadeOut(300);
		}
		$(this).remove();
	    });
	},this));
    });
});
