'use strict'

require.config({
    paths : {
        formWindow : 'doc_group/formWindow',
    },
    shim  : {
    }
});

require(['formWindow'], function(FormWindow){
    $('.DocList').find('.GroupAddCtrl').each(function(){
        $(this).find('button').on('click', function(){
            var fid = $(this).data('fid');
            if( !$('#docGroup' + fid).length ){
                new FormWindow($(this)).init();
            }
        });
    });
});
