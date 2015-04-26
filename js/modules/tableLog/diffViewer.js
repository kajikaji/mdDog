'use strict'

/*
 * 差分ビューアーの埋め込み
 */

define(function(){
    var diffViewer = function(){
    };
    diffViewer.prototype = {
        init: function() {
            $('a.DiffViewer').on('click', $.proxy(function(ev){
                this.preshow(ev.target);
            }, this));
        },
        preshow: function(target){
            var fid      = $(target).data('fid');
            var revision = $(target).data('revision');
            var dist     = $(target).data('dist');

            $.ajax({
                url  : 'api/diffViewer.cgi',
                type : 'POST',
                data : {
                    'fid'     : fid,
                    'revision': revision,
                    'dist'    : dist,
                }
            }).done($.proxy(this.show, this));
        },
        show: function(json){
            $('#diffViewer .Document .Name').text(json.name);
            $('#diffViewer .Document .Info .Revision').text(json.revision);
            $('#diffViewer .Document .Info .Dist').text(json.dist);
            $(json.diff).each(function(){
                var $no      = $('<div>').addClass('No').text(this.no);
                var $content = $('<div>').addClass('Content').html(this.content);
                var $line    = $('<div>').addClass('Line').append($no).append($content);
                $('#diffViewer .Document .Body').append($line);
            });

            $('#diffViewer').fadeToggle();
            $(window).one('keydown', $.proxy(function(){
                $('#diffViewer').fadeToggle(300, this.clear());
            }, this));
        },
        clear: function(){
            $('#diffViewer .Document .Name').text('');
            $('#diffViewer .Document .Info .Revision').text('');
            $('#diffViewer .Document .Info .Dist').text('');
            $('#diffViewer .Document .Body').children().each(function(){
                $(this).remove();
            });
        }
    };

    return diffViewer;
});