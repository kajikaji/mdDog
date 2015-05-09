'use strict'

define(function(){
    var editLogComment = function(fid, revision){
        this.fid = fid;
        this.revision = revision;
        this.api = 'api/bufferLogEdit.cgi';
        
    };
    editLogComment.prototype = {
        init: function() {
            var $form = $('#Log' + this.revision + ' .Message .Ctrl');
            $form.children().removeClass('CtrlTemp');
            $form.find('textarea').attr('id', 'message');
            $form.find('.Body').hide();

		    $form.find('a.Btn.Edit').on('click', $.proxy(function(ev){
                this.submit();
		    }, this));
        },
        submit: function(){
            var comment = $('#message').val();
            $.ajax({
                url : this.api,
                type : 'POST',
                data : {
                    fid : this.fid,
                    action : 'editLog',
                    comment : comment
                }
            }).done($.proxy(function(res){
            }, this));
        }
    };

    return editLogComment;
});
