'use strict'

define(function(){
    var editLogComment = function(){};
    editLogComment.prototype = {
        init: function() {
	    $('table.Gitlog').find('.Log .Message .Ctrl').each($.proxy(function(i, elm){
		var revision = $(elm).data('revision');
		$(elm).find('a.Btn.Edit').on('click', $.proxy(function(ev){
		    alert(revision); // TODO:未実装
		}, this));
	    }, this));
        },
    };

    return editLogComment;
});
