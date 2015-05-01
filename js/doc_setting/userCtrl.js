'use strict'

define(['docSettingView'],function(view){
    var userCtrl = function(fid){
        this.api = "api/userManager.cgi";
        this.fid = fid;
    };
    userCtrl.prototype = {
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
        deleteUser: function(users_){
            var data = {
                action : 'user_delete',
                type   : 'POST',
                fid    : this.fid,
                users  : users_
            };
            this.post(data, view.updateDeleteUser);
        },
        addUser: function(users_){
            var data = {
                action : 'user_add',
                type   : 'POST',
                fid    : this.fid,
                users  : users_
            };
            this.post(data, userCtrl.doneAddUser);
        }
    };
    userCtrl.setUserAuthority = function(fid, obj){
        var uid_ = obj.find(view.parts.userSelect).data('id');
        //承認フラグ
        obj.find(view.parts.authApprove).on('click', function(){
            var reObj = new userCtrl(fid);
            reObj.toggleApprove(uid_, $(this));
        });
        //編集フラグ
        obj.find(view.parts.authEdit).on('click', function(){
            var reObj = new userCtrl(fid);
            reObj.toggleEdit(uid_, $(this));
        });
    };
    userCtrl.doneAddUser = function(res){
        for(var i=0; i < res.length; i++){
            var $tmpl = view.createNewUserTR(res[i].id, res[i].nic_name);
            view.UserTable.prepend($tmpl.show());
            var fid_ = getParam('fid');
            userCtrl.setUserAuthority(fid_, $tmpl);

            view.UnallowUserTable.find('option').each(
                $.proxy(function(j, elm){
                    if(Number(elm.value) === res[i].id){
                        elm.remove();
                        return false;
                    }
                }, this)
            );
        }
    };

    return userCtrl;
});
