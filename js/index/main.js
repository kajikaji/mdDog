'use strict'

require.config({
    paths : {
        formWindow  : 'index/formWindow',
        searchGroup : 'index/searchGroup',
        UTIL            :'modules/UTIL'
    },
    shim  : {
        'searchGroup' : {
            deps: [ 'UTIL' ]
        }
    }
});

require(['formWindow', 'searchGroup'],
        function(FormWindow, SearchGroup){
    if( $('.DocList').length ){
        $('.DocList').find('.GroupAddCtrl').each(function(){
            $(this).find('button').on('click', function(){
                var fid = $(this).data('fid');
                if( !$('#docGroup' + fid).length ){
                    new FormWindow($(this)).init();
                }
            });
        });
    }

    if ( $('#groupSelect').length ){
        require(['searchGroup'], function(SearchGroup){
            new SearchGroup($('#groupSelect')).init();
        });
    }
});
