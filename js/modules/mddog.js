'use strict'
/***********************************************
 * 初回実行
 ***********************************************/
$(function(){

    var outline = false;
    $('#printOutline').on("click", function(){
        outline = true;

        $('body').children().each(function(){
            if(!$(this).hasClass('Outline')){
                $(this).slideUp('100');
            }else{
                $(this).addClass('PrintFormat');
            }
        });
    });

    var revisionViewer = false;
    var diffViewer = false;
    if($('table.Gitlog').length > 0){
        //リヴィジョンビューアーの埋め込み
	$('a.RevisionViewer').on('click', function(){
	    var fid=$(this).data('fid');
	    var user=$(this).data('user');
	    if(user === null) user = 0;
	    var revision=$(this).data('revision');
	    $.ajax({
		url: 'api/revisionViewer.cgi',
		type: 'POST',
		data: {
		    'fid': fid,
		    'user': user,
		    'revision': revision,
		}
	    }).done(function(res){
		$('#revisionViewer .Document .Body').html(res.document);
		$('#revisionViewer .Document .Name').text(res.name);
		$('#revisionViewer .Document .Info .CommitDate').text(res.commitDate);
		$('#revisionViewer .Document .Info .CommitMessage').text(res.commitMessage);
                $('#revisionViewer').fadeToggle();
                revisionViewer = true;
	    });
	});
        //差分ビューアーの埋め込み
	$('a.DiffViewer').on('click', function(){
	    var fid=$(this).data('fid');
	    var revision=$(this).data('revision');
	    var dist=$(this).data('dist');
	    $.ajax({
		url: 'api/diffViewer.cgi',
		type: 'POST',
		data: {
		    'fid': fid,
		    'revision': revision,
		    'dist': dist,
		}
	    }).done(function(res){
		$('#diffViewer .Document .Name').text(res.name);
		$('#diffViewer .Document .Info .Revision').text(res.revision);
		$('#diffViewer .Document .Info .Dist').text(res.dist);
		$(res.diff).each(function(){
		    var $no = $('<div>').addClass('No').text(this.no);
		    var $content = $('<div>').addClass('Content').html(this.content);
		    var $line = $('<div>').addClass('Line').append($no).append($content);
  	            $('#diffViewer .Document .Body').append($line);
		});

		$('#diffViewer').fadeToggle();
		diffViewer = true;
	    });
	});
    }

    //キー入力の監視
    $(window).keydown(function(ev){
        if(outline){
            //アウトラインの印刷ページ
            outline = false;

            $('body').children().each(function(){
                if(!$(this).hasClass('Outline')){
                    $(this).slideDown('100');
                }else{
                    $(this).removeClass('PrintFormat');
                }
            });
        }
        if(revisionViewer){
            //リヴィジョンヴューアー窓
            $('#revisionViewer').fadeToggle();
            revisionViewer = false;
        }
        if(diffViewer){
            //差分ヴューアー窓
            $('#diffViewer').fadeToggle();
            diffViewer = false;
        }
    });

    if($('.MdBuffer').find('.BufferEdit.Source').length){
	var changeFlg = false;
	$(window).on('beforeunload', function(){
	    if(changeFlg){
                 //変更があったときはAJAXで一時保存します
//		return '!!!';
		return;
	    }
	});
	$('.Canvas').find('textarea').change(function(){
	    changeFlg = true;
	});
    }
});
