'use strict'

$(function(){
    //ユーザー削除ボタン
    $('button.RemoveUser').click($.proxy(function(){
        var fid_   = getParam('fid');
        var users_ = [];

        $('.AllowUsersList .UsersTable').find('.User .Select input[type=checkbox]').each(function(){
            if($(this).prop('checked')){
                var uid = $(this).data('id');
                users_.push(uid);
            }
        });
        if(users_.length === 0) return;

        $.ajax({
            url  : 'api/userManager.cgi',
            type : 'POST',
            data : {
                action  : 'user_delete',
                type    : 'POST',
                fid     : fid_,
                users   : users_
            }
        }).done(function(res){
            for(var i=0; i < res.length; i++){
                $('#User' + res[i].id).remove();
                var option = $('<option>').val(res[i].id);
                option.text(res[i].nic_name);
                $('.UnallowUsersList select').append(option);
            }
        });     
    }, this));

    //ユーザー追加ボタン
    $('button.AddUser').click($.proxy(function(){
        var users_ = $('.UnallowUsersList select').val();
        var fid_   = getParam('fid');

        if( users_ === null ) return;

        $.ajax({
            url  : 'api/userManager.cgi',
            type : 'POST',
            data : {
                action  : 'user_add',
                type    : 'POST',
                fid     : fid_,
                users   : users_
            }
        }).done(function(res){
            for(var i=0; i < res.length; i++){
                var $tmpl = $('.UsersTable tbody .UserTmpl').clone().removeClass('UserTmpl').addClass('User');
                $tmpl.attr('id', 'User' + res[i].id);
                $tmpl.find('.Select input[type=checkbox]').attr('data-id', res[i].id);
                $tmpl.find('.Name').text(res[i].nic_name);

                $('.UsersTable tbody').prepend($tmpl.show());

                $('.UnallowUsersList select').find('option').each($.proxy(function(j, elm){
                    if(Number(elm.value) === res[i].id){
                        elm.remove();
                        return false;
                    }
                }, this));
            }
        });
        

    }, this));


    $('.UsersTable tbody').find('tr.User').each(function(){
        var uid_ = $(this).find('.Select input[type=checkbox]').data('id');
        var fid_ = getParam('fid');
        //承認フラグ
        $(this).find('.Approve input[type=checkbox]').on('click', function(){
            var checked_ = $(this).prop('checked')===true?1:0;
            $.ajax({
                url  : 'api/userManager.cgi',
                type : 'POST',
                data : {
                    action  : 'user_may_approve',
                    type    : 'POST',
                    fid     : fid_,
                    uid     : uid_,
                    checked : checked_
                }
            }).done(function(res){
            });
        });
        //編集フラグ
        $(this).find('.Edit input[type=checkbox]').on('click', function(){
            var checked_ = $(this).prop('checked')===true?1:0;
            $.ajax({
                url  : 'api/userManager.cgi',
                type : 'POST',
                data : {
                    action  : 'user_may_edit',
                    type    : 'POST',
                    fid     : fid_,
                    uid     : uid_,
                    checked : checked_
                }
            }).done(function(res){
            });
        });
        //削除フラグ
        $(this).find('.Delete input[type=checkbox]').on('click', function(){
        });
    });

    //公開フラグ
    $('#PublicMark input[type=checkbox]').on('click', function(){
	var fid_ = getParam('fid');
        var checked_ = $(this).prop('checked')===true?1:0;
        $.ajax({
	    url  : 'api/documentManager.cgi',
	    type : 'POST',
	    data : {
                    action    : 'change_public',
                    type      : 'POST',
                    fid       : fid_,
		    is_public : checked_
	    }
        }).done(function(res){
	});
    });
});
