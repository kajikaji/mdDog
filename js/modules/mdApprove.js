'use strict'

define(function(){
    function activeBufferList(uid) {
            $('#bufferList').find('li').each(function(){
                var id = Number($(this).attr("id").substr(6));
                if(uid === id){
                    $(this).addClass("Active");
                }else{
                    $(this).removeClass("Active");
                }
            });
    };
    function showLog(uid) {
            $('.DocApprove .Logtable').each(function(){
                var id = $(this).attr("id").substr(9);
                if(uid != id && !$(this).is(":hidden")){
                    $(this).hide();
                }else if(uid == id && $(this).is(":hidden")){
                    $(this).show();
                }
            });
            activeBufferList(uid);
    };
    $('#bufferList').find('li').each(function(){
        var uid = Number($(this).attr('id').substr(6));
        $(this).children('a').click($.proxy(function(ev){
            showLog(uid);
        }, this));
    });
    return {}
});
