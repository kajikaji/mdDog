'use strict'

define(function(){
    var commitForm = function(){
        this.showFlg = false;
    };

    commitForm.prototype = {
        init: function(){
            $('#bufferCommitBtn').on('click', $.proxy(function(){
                $('#bufferCommitForm').fadeToggle();
                this.showFlg = true;
            }, this));

            $('#cancelButton').click($.proxy(function(){
                $('#bufferCommitForm').fadeToggle();
                this.showFlg = false;
            }, this));

            //キー入力の監視
            $(window).keydown($.proxy(function(ev){
                if( this.showFlg && ev.keyCode === 27 ){  //ESCキー
                    //編集バッファのコミット窓
                    $('#bufferCommitForm').fadeToggle();
                    this.showFlg = false;
                }
            }, this));


            $('#bufferCommitForm').find('.Ctrl input[type=submit]').click($.proxy(function(ev){
                this.commit();
            }, this));

        },

        commit: function() {
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
        }

    };



    return commitForm;
});
