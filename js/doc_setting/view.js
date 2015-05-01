'use strict'

define(function(){
    var view = function(){
    };
    view.UserTable     = $('.UsersTable tbody');
    view.RemoveUserBtn = $('button.RemoveUser');
    view.AddUserBtn    = $('button.AddUser');
    view.AllowUserTable   = $('.AllowUsersList .UsersTable tbody');
    view.UnallowUserTable = $('.UnallowUsersList select');
    view.parts = {
        userTR      :'tr.User',
        userSelect  :'.Select input[type=checkbox]',
        authApprove :'.Approve input[type=checkbox]',
        authEdit    :'.Edit input[type=checkbox]'
    };

    view.updateTag_public = function(checked_){
        if(checked_){
            var tag = $('.Docinfo .Tags').find('.Public');
            tag.remove();
        }else{
            var tag = $('<li>').addClass('Public').append(
                $('<div>').text('public')
            );
            $('.Tags').prepend(tag);
        }
    };
    view.updateDeleteUser = function(res){
        for(var i=0; i < res.length; i++){
            $('#User' + res[i].id).remove();
            var option = $('<option>').val(res[i].id);
            option.text(res[i].nic_name);
            $('.UnallowUsersList select').append(option);
        }
    };
    view.createNewUserTR = function(userId,nicName){
        var $tmpl = $('.UsersTable tbody .UserTmpl').clone()
                    .removeClass('UserTmpl').addClass('User');
        $tmpl.attr('id', 'User' + userId);
        $tmpl.find('.Select input[type=checkbox]').attr('data-id', userId);
        $tmpl.find('.Name').text(nicName);
        return $tmpl;
    };
    return  view;
});
