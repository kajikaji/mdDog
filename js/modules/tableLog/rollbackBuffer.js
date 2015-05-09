'use strict'

define(function(){
    var rollbackBuffer = function(fid, revision, callback){
        this.fid      = fid;
        this.revision = revision;
        this.callback = callback;
        this.api = 'api/bufferLogEdit.cgi';
    };
    rollbackBuffer.prototype = {
        init: function() {
            var headLog = $('#Log' + this.revision);
            headLog.find('a.Rollback').on('click', $.proxy(function(ev){
                this.submit(ev.target);
            }, this));
        },
        submit: function(target){
            var fid      = $(target).data('fid');
            var revision = $(target).data('revision');

            $.ajax({
                url  : this.api,
                type : 'POST',
                data : {
                    'action'  : 'rollback',
                    'fid'     : fid,
                    'revision': revision,
                }
            }).done($.proxy(function(res){
                this.callback();
            }, this));
        }
    };

    return rollbackBuffer;
});
