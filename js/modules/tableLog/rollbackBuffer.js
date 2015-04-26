'use strict'

define(function(){
    var rollbackBuffer = function(){
    };
    rollbackBuffer.prototype = {
        init: function() {
            $('a.Rollback').on('click', $.proxy(function(ev){
                this.show(ev.target);
            }, this));
        },
        show: function(target){
            var fid      = $(target).data('fid');
            var revision = $(target).data('revision');

            $.ajax({
                url  : 'api/bufferLogEdit.cgi',
                type : 'POST',
                data : {
                    'action'  : 'rollback',
                    'fid'     : fid,
                    'revision': revision,
                }
            }).done($.proxy(function(res){
                var logId   = '#Log' + res.revision;
                var nextLog = $(logId).next('tr.Log');
                var nextId = nextLog.attr('id').substr(3);
                
                var temp = $(nextLog).find('td.Ctrl ul li.CtrlTemp').each(function(){
                    var anch = $(this).find('a.Rollback');
                    anch.data('fid', fid);
                    anch.data('revision', nextId);
                    $(this).removeClass('CtrlTemp');
                });

                $(logId).slideUp();
		this.updateMessage();
            }, this));
        },
        updateMessage: function(){
            if( $('section.Message ul.Buffered').hasClass('Disable') ){
                $('section.Message ul.Buffered').slideDown(300, function(){
                    $('section.Message ul.Buffered').removeClass('Disable');
                });
            }
        },
    };

    return rollbackBuffer;
});
