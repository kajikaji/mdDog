'use strict'

define(['rollbackBuffer', 'editLogComment'], function(Rollback,EditLog){
    var headLogCtrl = function(fid){
        this.fid      = fid;
        this.rollback = undefined;
        this.editlog  = undefined;
    };
    headLogCtrl.prototype = {
        init: function(){
            var headLog = $('table.Gitlog tbody tr.Log:first-child');
            var revision = headLog.attr('id').substr(3);

            if( headLog.find('a.Rollback').length ){
                this.rollback = new Rollback(this.fid, revision, $.proxy(this.reduceLog, this));
                this.rollback.init();
            }
            if( headLog.find('.Message .Ctrl').length ){
                this.editlog = new EditLog(this.fid, revision);
                this.editlog.init();
            }
        },
        reduceLog: function(){
            var headLog = $('table.Gitlog tbody tr.Log:first-child');
            var revision = headLog.attr('id').substr(3);
//            var logId   = '#Log' + res.revision;
            var nextLog = headLog.next('tr.Log');
            var nextId = nextLog.attr('id').substr(3);
                
            headLog.slideUp(100, function(){
                headLog.remove();
            });

            $(nextLog).find('td.Ctrl ul li').removeClass('CtrlTemp');

            this.rollback = new Rollback(this.fid, nextId, $.proxy(this.reduceLog,this));
            this.rollback.init();
            this.editlog = new EditLog(this.fid, nextId);
            this.editlog.init();

	        this.updateMessage();
        },
        updateMessage: function(){
            if( $('section.Message ul.Buffered').hasClass('Disable') ){
                $('section.Message ul.Buffered').slideDown(300, function(){
                    $('section.Message ul.Buffered').removeClass('Disable');
                });
            }
        }
    };

    return headLogCtrl;
});
