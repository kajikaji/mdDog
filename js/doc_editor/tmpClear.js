'use strict'

define(function(){
    var tmpClear = function(fid, target){
        this.fid    = fid;
        this.target = target;
        this.api    = 'api/bufferClear.cgi';
        this.mdDoc  = undefined;
    };
    tmpClear.prototype = {
        init: function(mdDoc){
            this.mdDoc = mdDoc;
            this.target.on('click', $.proxy(this.clearAction, this));
        },
        clearAction: function(){
            $.ajax({
                url  : this.api,
                type : 'POST',
                data : {
                    fid : this.fid
                },
                timeout: 5000
            }).done(function(res){
            });
        }
    };

    return tmpClear;
});
