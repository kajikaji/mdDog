'use strict'

define(function(){

    function commitBuffer() {
        var $document = "";
        $('form .MdBufferFix .Rowdata').find('.Elm').each(function(){
            $document += $(this).text();
            $document += "\n";
        });
        if( $('.BufferEdit.Source .Canvas').find('textarea').length ){
	        $document = $('.BufferEdit.Source .Canvas textarea').val();
        }

        $('form .MdBufferFix').find('textarea.Document').text($document);
        document.forms['commitForm'].submit();   
    };

    $('#bufferCommitForm').find('.Ctrl input[type=submit]').click($.proxy(function(ev){
        commitBuffer();
    }, this));

    var commitForm = false;
    $('#bufferCommitBtn').on('click', function(){
        $('#bufferCommitForm').fadeToggle();
        commitForm = true;
    });

    $('#cancelButton').click(function(){
        $('#bufferCommitForm').fadeToggle();
        commitForm = false;
    });

    //キー入力の監視
    $(window).keydown(function(ev){
        if( commitForm && ev.keyCode === 27 ){  //ESCキー
            //編集バッファのコミット窓
            $('#bufferCommitForm').fadeToggle();
            commitForm = false;
        }
    });

    return;
});
