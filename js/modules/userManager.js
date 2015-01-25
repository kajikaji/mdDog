'use strict'

$(function(){
    $('button.AddUser').click($.proxy(function(){
        var users_ = $('.UnallowUsersList select').val();
        var fid_   = getParam('fid');

        $.ajax({
            url  : 'api/userManager.cgi',
            type : 'POST',
            data : {
                action  : 'add_users',
                type    : 'POST',
                fid     : fid_,
                users   : users_
            }
        }).done(function(res){
            for(var i=0; i < res.length; i++){
                var $tmpl = $('.UsersTable tbody .UserTmpl').clone().removeClass('UserTmpl').addClass('User');
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
	$(this).find('.Delete input[type=checkbox]').on('click', function(){
	});
    });
});
