/***********************************************
 * 関数定義
 ***********************************************/
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

function test() {
    var obj = $(this);
    alert(obj.attr('id'));
}

/***********************************************
 * 初回実行
 ***********************************************/
$(function(){
    var cnt = 0;
    $('div.document').children().each(function(){
        $(this).attr('id', 'bk' + cnt);
        cnt++;

        var obj = $(this).clone();
        var row = $('<div>').html(obj.html());
        row.attr('id', 'elm-' + cnt);
        $('form.md-buffer-fix div.rowdata').append(row);


        $(this).hover(
            function(){ $(this).addClass('forcus'); },
            function(){ $(this).removeClass('forcus'); }
        );
        $(this).click(function(){
          var obj = $(this);
          alert(obj.attr('id'));
        });
    });
});
