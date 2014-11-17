
function activeBufferList(uid) {
    $('#buffer-list').find('li').each(function(){
        var id = Number($(this).attr("id").substr(7));
        if(uid === id){
            $(this).addClass("active");
        }else{
            $(this).removeClass("active");
        }
    });
}

function showLog(uid) {
    $('.gitlog .logtable').each(function(){
        var id = $(this).attr("id").substr(11);
        if(uid != id && !$(this).is(":hidden")){
              $(this).hide();
        }else if(uid == id && $(this).is(":hidden")){
            $(this).show();
        }
    });
    activeBufferList(uid);
}
