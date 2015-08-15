'use strict'

require.config({
    paths : {
        docSettingUserCtrl   : 'doc_setting/userCtrl',
        docSettingDocCtrl    : 'doc_setting/docCtrl',
        docSettingView       : 'doc_setting/view'
    },
    shim: {
        docSettingUserCtrl   : {
            deps: ['UTIL', 'docSettingView']
        },
        docSettingDocCtrl   : {
            deps: ['UTIL', 'docSettingView']
        } 
    }
});


require(['docSettingView', 'docSettingUserCtrl','docSettingDocCtrl'],
        function(View, UserCtrl,DocCtrl){
    var fid_ = getParam('fid');

    //権限トグル
    View.AllowUserTable.find(View.parts.userTR).each(function(){
        UserCtrl.setUserAuthority(fid_, $(this));
    });

    //ユーザー削除ボタン
    View.RemoveUserBtn.click($.proxy(function(){
        var users_ = [];
        View.AllowUserTable.find(View.parts.userSelect).each(function(){
            if($(this).prop('checked')){
                var uid = $(this).data('id');
                users_.push(uid);
            }
        });
        if(users_.length === 0) return;
        var userCtrl = new UserCtrl(fid_);
        userCtrl.deleteUser(users_);
    }, this));

    //ユーザー追加ボタン
    View.AddUserBtn.click($.proxy(function(){
        var users_ = View.UnallowUserTable.val();
        if( users_ === null ) return;
        var userCtrl = new UserCtrl(fid_);
        userCtrl.addUser(users_);
    },this));

    //公開フラグ
    $('#PublicMark input[type=checkbox]').on('click', function(){
        var docCtrl = new DocCtrl(fid_);
        docCtrl.togglePublic($(this));
    });
});
