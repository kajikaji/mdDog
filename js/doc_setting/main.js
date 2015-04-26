'use strict'

require.config({
    paths : {
        docSettingAjaxCtrl   : 'doc_setting/ajaxCtrl'
    },
    shim: {
        docSettingAjaxCtrl   : {
            deps: ['UTIL']
        }
    }
});


require(['docSettingAjaxCtrl'], function(AjaxCtrl){
    var fid_ = getParam('fid');

    //権限トグル
    $('.UsersTable tbody').find('tr.User').each(function(){
        setUserAuthority(fid_, $(this));
    });
    function setUserAuthority(fid, obj){
        var uid_ = obj.find('.Select input[type=checkbox]').data('id');
        //承認フラグ
        obj.find('.Approve input[type=checkbox]').on('click', function(){
            var ajaxCtrl = new AjaxCtrl(fid_);
            ajaxCtrl.toggleApprove(uid_, $(this));
        });
        //編集フラグ
        obj.find('.Edit input[type=checkbox]').on('click', function(){
            var ajaxCtrl = new AjaxCtrl(fid_);
            ajaxCtrl.toggleEdit(uid_, $(this));
        });
    }

    //ユーザー削除ボタン
    $('button.RemoveUser').click($.proxy(function(){
        var users_ = [];
        $('.AllowUsersList .UsersTable').find('.User .Select input[type=checkbox]').each(function(){
            if($(this).prop('checked')){
                var uid = $(this).data('id');
                users_.push(uid);
            }
        });
        if(users_.length === 0) return;
        var ajaxCtrl = new AjaxCtrl(fid_);
        ajaxCtrl.deleteUser(users_, doneDeleteUser);
 
        function doneDeleteUser(res){
            for(var i=0; i < res.length; i++){
                $('#User' + res[i].id).remove();
                var option = $('<option>').val(res[i].id);
                option.text(res[i].nic_name);
                $('.UnallowUsersList select').append(option);
            }
        }
    }, this));

    //ユーザー追加ボタン
    $('button.AddUser').click($.proxy(function(){
        var users_ = $('.UnallowUsersList select').val();
        if( users_ === null ) return;
        var ajaxCtrl = new AjaxCtrl(fid_);
        ajaxCtrl.addUser(users_, doneAddUser);

        function doneAddUser(res){
            for(var i=0; i < res.length; i++){
                var $tmpl = $('.UsersTable tbody .UserTmpl').clone().removeClass('UserTmpl').addClass('User');
                $tmpl.attr('id', 'User' + res[i].id);
                $tmpl.find('.Select input[type=checkbox]').attr('data-id', res[i].id);
                $tmpl.find('.Name').text(res[i].nic_name);

                $('.UsersTable tbody').prepend($tmpl.show());
                setUserAuthority(fid_, $tmpl);

                $('.UnallowUsersList select').find('option').each($.proxy(function(j, elm){
                    if(Number(elm.value) === res[i].id){
                        elm.remove();
                        return false;
                    }
                }, this));
            }
        }
    },this));

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



