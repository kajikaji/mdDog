'use strict'

define(function(){
    var ajaxCtrl = function(fid){
        this.api = "api/userManager.cgi";
        this.fid = fid;
    };
    ajaxCtrl.prototype = {
        post : function(data, callback) {
            $.ajax({
                'url'  : this.api,
                'type' : 'POST',
                'data' : data
            }).done(callback);
        },
        toggleApprove: function(uid_, obj){
            var checked_ = obj.prop('checked')===true?1:0;
            var data     = {
                action  : 'user_may_approve',
                type    : 'POST',
                fid     : this.fid,
                uid     : uid_,
                checked : checked_
            };
            this.post(data, undefined);
        },
        toggleEdit: function(uid_, obj){
            var checked_ = obj.prop('checked')===true?1:0;
            var data     = {
                action  : 'user_may_edit',
                type    : 'POST',
                fid     : this.fid,
                uid     : uid_,
                checked : checked_
            };
            this.post(data, undefined);
        },
        deleteUser: function(users_, callback){
            var data = {
                action : 'user_delete',
                type   : 'POST',
                fid    : this.fid,
                users  : users_
            };
            this.post(data, callback);
        },
        addUser: function(users_, callback){
            var data = {
                action : 'user_add',
                type   : 'POST',
                fid    : this.fid,
                users  : users_
            };
            this.post(data, callback);
        }
    };

    return ajaxCtrl;
});
