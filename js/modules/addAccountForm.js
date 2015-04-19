'use strict'

$(function(){
    //使用フラグ
    $('#accountTable tbody').find('.Account').each(function(){
        $(this).find('.IsUsed input[type=checkbox]').on('click', function(){
            var uid_     = $(this).data('uid');
            var checked_ = $(this).prop('checked')===true?1:0;

            $.ajax({
                url  : 'api/accountManager.cgi',
                type : 'POST',
                data : {
		    action  : 'account_is_used',
		    type    : 'POST',
		    uid     : uid_,
		    is_used : checked_,
                }
            }).done(function(res){
            });
        });
        $(this).find('.MayAdmin input[type=checkbox]').on('click', function(){
            var uid_     = $(this).data('uid');
            var checked_ = $(this).prop('checked')===true?1:0;

            $.ajax({
                url  : 'api/accountManager.cgi',
                type : 'POST',
                data : {
		    action  : 'account_may_admin',
		    type    : 'POST',
		    uid     : uid_,
		    checked : checked_,
                }
            }).done(function(res){
            });
        });
        $(this).find('.MayApprove input[type=checkbox]').on('click', function(){
            var uid_     = $(this).data('uid');
            var checked_ = $(this).prop('checked')===true?1:0;

            $.ajax({
                url  : 'api/accountManager.cgi',
                type : 'POST',
                data : {
		    action  : 'account_may_approve',
		    type    : 'POST',
		    uid     : uid_,
		    checked : checked_,
                }
            }).done(function(res){
            });
        });
    });
   
    //ユーザー追加
    $('.AddAccountForm button.Add').click(function(){
        var account_  = $('.AddAccountForm input.Account').val();
        var nicname_  = $('.AddAccountForm input.NicName').val();
        var mail_     = $('.AddAccountForm input.Mail').val();
        var password_ = $('.AddAccountForm input.Password').val();

        if(!account_
        || !nicname_
        || !mail_
        || !password_){
            return;  // "入力は必須"
        }

        $.ajax({
            url  : 'api/accountManager.cgi',
            type : 'POST',
            data : {
                action   : 'add',
                account  : account_,
                nicname  : nicname_,
                mail     : mail_,
                password : password_
            }
        }).done(function(res){
            var $tmpl = $('#accountTable .AccountTmpl').clone().removeClass('AccountTmpl');
            $tmpl.find('.Account').text(res.account);
            $tmpl.find('.Nicname').text(res.nic_name);
            $tmpl.find('.Mail').text(res.mail);
            $tmpl.find('.CreatedAt').text(res.created_at);
            if(res.may_admin){
                $tmpl.find('.MayAdmin input[type=checkbox]').attr('checked', 'checked');
            }
            if(res.may_approve){
                $tmpl.find('.MayApprove input[type=checkbox]').attr('checked', 'checked');
            }
            if(res.is_used){
                $tmpl.find('.IsUsed input[type=checkbox]').attr('checked', 'checked');
            }


            $('#accountTable tbody').prepend($tmpl.show());
        });

        $('.AddAccountForm input.Account').val('');
        $('.AddAccountForm input.NicName').val('');
        $('.AddAccountForm input.Mail').val('');
        $('.AddAccountForm input.Password').val('');
    });
});
