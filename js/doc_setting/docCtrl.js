'use strict'

define(['docSettingView'], function(view){
    var docCtrl = function(fid){
        this.api = "api/docManage.cgi";
        this.fid = fid;
    };
    docCtrl.prototype = {
        post : function(data, callback) {
            $.ajax({
                'url'  : this.api,
                'type' : 'POST',
                'data' : data
            }).done(callback);
        },
        togglePublic: function(obj){
            var checked_ = obj.prop('checked')===true?1:0;
            var data = {
                action  : 'change_public',
                type    : 'POST',
                fid     : this.fid,
                is_public : checked_
            };
            this.post(data, view.updateTag_public(!checked_));
        }
    };

    return docCtrl;
});
