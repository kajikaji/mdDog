'use strict'

/*
 * リヴィジョンビューアーの埋め込み
 */

define(function(){
    var revisionViewer = function(){};

    revisionViewer.prototype = {
        init: function(){
            $('a.RevisionViewer').on('click', $.proxy(function(ev){
                this.preshow(ev.target);
            }, this));
        },
        preshow: function(target) {
            var fid      = $(target).data('fid');
            var user     = $(target).data('user');
            var revision = $(target).data('revision');
            if(user === null) user = 0;

            $.ajax({
                url  : 'api/revisionViewer.cgi',
                type : 'POST',
                data : {
                    'fid'     : fid,
                    'user'    : user,
                    'revision': revision,
                }
            }).done(this.show);
        },
        show: function(json){
            $('#revisionViewer .Document .Body').html(json.document);
            $('#revisionViewer .Document .Name').text(json.name);
            $('#revisionViewer .Document .Info .CommitDate').text(json.commitDate);
            $('#revisionViewer .Document .Info .CommitMessage').text(json.commitMessage);

            $('#revisionViewer').fadeToggle();
            $(window).one('keydown', function(){
                $('#revisionViewer').fadeToggle();
            });
        }
    };
    return revisionViewer;
});
