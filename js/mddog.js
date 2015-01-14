/***********************************************
 * 関数定義
 ***********************************************/
function activeBufferList(uid) {
    $('#bufferList').find('li').each(function(){
        var id = Number($(this).attr("id").substr(6));
        if(uid === id){
            $(this).addClass("Active");
        }else{
            $(this).removeClass("Active");
        }
    });
}

function showLog(uid) {
    $('.Gitlog .Logtable').each(function(){
        var id = $(this).attr("id").substr(9);
        if(uid != id && !$(this).is(":hidden")){
              $(this).hide();
        }else if(uid == id && $(this).is(":hidden")){
            $(this).show();
        }
    });
    activeBufferList(uid);
}

function getParam(key) {
    var url = location.href;
    var param = url.split("?");
    var params = param[1].split("&");
    for( var i=0; i < params.length; i++ ){
        var pCols = params[i].split("=");
        if(pCols[0] === key){
            return pCols[1];
        }
    }
    return null;
}

function commitBuffer() {
    var $document = "";
    $('form .MdBufferFix .Rowdata').find('.Elm').each(function(){
        $document += $(this).text();
        $document += "\n";
    });
    if($('.BufferEdit.Source .Canvas').find('textarea').length){
	$document = $('.BufferEdit.Source .Canvas textarea').val();
    }

    $('form .MdBufferFix').find('textarea.Document').text($document);
    document.forms['commitForm'].submit();   
}

function insertAtCaret(target, str) {
    var obj = $(target);
    obj.focus();
    if(navigator.userAgent.match(/MSIE/)) {
        var r = document.selection.createRange();
        r.text = str;
        r.select();
    } else {
        var s = obj.val();
        var p = obj.get(0).selectionStart;
        var np = p + str.length;
        obj.val(s.substr(0, p) + str + s.substr(p));
        obj.get(0).setSelectionRange(np, np);
    }
}

/*
 * マークダウンエディタの制御クラス
 */
var mdEditForm = function(obj){
    this.src = obj;
    this.id;
    this.elmId;
    this.mdId;
    this.formId;
    this.formtmpl = 'editform';
    this.api = 'api/mdEditor.cgi';
};
mdEditForm.prototype = {
    init: function() {
        this.id = this.src.attr('id').slice(2);
        this.elmId = 'elm' + this.id;
        this.mdId = 'md' + this.id;
        this.formId = 'edit' + this.id;

        var newForm = $('#' + this.formtmpl).clone().attr('id', this.formId);
        var data= $('#' + this.elmId).text();
        var n = data.match(/\n/g).length + 1;
        var tt = newForm.find('textarea.Editdata');
        tt.attr('id', 'editdata' + this.id);
        tt.text(data).attr('rows', n);
        this.src.after(newForm);
        newForm.show(); this.src.hide();

        this.attachButton();
    },

    attachButton: function(){
        $('#' + this.formId).find('button.Update').click($.proxy(function(){
            this.btnUpdate();
        }, this));
        $('#' + this.formId).find('button.Delete').click($.proxy(function(){
            this.btnDelete();
        }, this));
        $('#' + this.formId).find('button.Cancel').click($.proxy(function(){
            this.btnCancel();
        }, this));
        $('#' + this.formId).find('button.ImageView').click($.proxy(function(){
            this.btnImageView();
        }, this));
    },

    btnUpdate: function(){
        var fid = getParam("fid");
        var editdata = $('#' + this.formId).find('textarea.Editdata').val();
        $.ajax({
                url: this.api,
                type: 'POST',
                data:{
                fid: fid, 
                eid: this.id,
                action: 'update', 
                data: editdata
            }
        }).done($.proxy(function(res){
            this.updateSuccess(res);
            this.updateMessage();
        }, this));
    },
    btnDelete: function(){
        var fid = getParam("fid");
        $.ajax({
                url: this.api,
                type: 'POST',
                data:{
                fid: fid, 
                eid: this.id,
                action: 'delete',
            }
        }).done($.proxy(function(res){
            this.deleteSuccess(res);
            this.updateMessage();
        }, this));
    },
    btnCancel: function(){
        $('#' + this.formId).remove();
        $(this.src).show();
    },
    btnImageView: function(){
        var fid = getParam("fid");
 
        $.ajax({
            url: this.api,
            type: 'GET',
            data:{
                fid: fid, 
                action: 'image_list', 
            }
        }).done($.proxy(function(res){
            var length = res.length;
            var list = $('#' + this.formId).find('ul.ImageList');
            list.show();
            for(var i=0; i < res.length; i++){
                var img = $('<img>').attr('src', 'md_imageView.cgi?image=' + res[i].filename + '&fid=' + fid + '&tmp=1&thumbnail=1');
                var anch = $('<a>').addClass('Btn').text('挿入');
                var tt = '#editdata' + this.id;
                var tag = '![mdDog](md_imageView.cgi?fid=' + fid + '&image=' + res[i].filename + ')';
                anch.attr('onclick', 'insertAtCaret(\"' + tt + '\",\"' + tag + '\")');
                var imageRec = $('<li>').append(img).append(anch);
                list.append(imageRec);
            }
        }, this));
    },

    updateSuccess: function(res){
        $('#' + this.formId).remove();

        $('#' + this.mdId).attr('id', this.mdId + 'org');
        var $newObj = $(res.md);
        $('#' + this.mdId + 'org').after($newObj);
        $newObj.show();
        $('#' + this.mdId + 'org').remove();
	    var leng = $newObj.length;
	    if(leng > 1){
	        this.resetTreeId($newObj.last().next(), leng - 1, 'md');
        }

        $('#' + this.elmId).attr('id', this.elmId + 'org');
        var $elmObj = $(res.row);
        $('#' + this.elmId + 'org').after($elmObj);
        $('#' + this.elmId + 'org').remove();
	    var eLeng = $elmObj.length;
	    if(eLeng > 1){
	        this.resetTreeId($elmObj.last().next(), eLeng - 1, 'elm');
        }

        $newObj.hover(
            function(){ $(this).addClass('Focus'); },
            function(){ $(this).removeClass('Focus'); }
        );
        $newObj.click(function(){
            var eForm = new mdEditForm($(this));
            eForm.init();
        });
    },
    deleteSuccess: function(res) {
        $('#' + this.formId).remove();
        var $nextMd = $('#' + this.mdId).next();
        $('#' + this.mdId).remove();
        this.resetTreeId($nextMd, -1, 'md');
        var $nextElm = $('#' + this.elmId).next();
        $('#' + this.elmId).remove();
        this.resetTreeId($nextElm, -1, 'elm');
    },
    updateMessage: function() {
        if($('section.Message').is(":hidden")){
            var info = $('<div>').addClass('Info').text("コミットされていないバッファがあります");
            $('section.Message').append(info);
            $('section.Message').show();
        }
    },
    resetTreeId: function(obj, inc, prefix) {
        while(obj.length > 0){
            var id = obj.attr('id');
            if(id){
                id = Number(id.substr(prefix.length));
                id += inc;
                obj.attr('id', prefix + id);
            }
            obj = obj.next();
        }
    }
};

/*
 * バッファ編集エディタのアウトライン分割制御クラス
 */
var outlineDivide = function() {};
outlineDivide.prototype = {
    init: function () {
        var divide = [];
        $('.MdBuffer  ul.Pagenav').find('a.OutlinePage').each($.proxy(function(index, obj){
            divide.push($(obj).data('elm'));
            $(obj).data('id', index);
            $(obj).click($.proxy(function(ev){
                $('.MdBuffer .Document .Md').hide();

                var id = $(ev.target).data('id');
	            this.showPage(divide, id);
	            this.activeNum(id);
            }, this));
        }, this));
        this.showPage(divide, 0);
        this.activeNum(0);
    },

    showPage: function (dividesAr, id) {
        var tmp = undefined;
        for(var i=0; i < dividesAr.length; i++) 
        {
            if(i === id) {
                tmp = dividesAr[i];
            }else{
                if(tmp !== undefined){
                    for(var j=tmp; j < dividesAr[i]; j++)
                    {
                        $('#md' + j).show();
                    }
                    tmp = undefined;
                }
            }
        }
        if(tmp !== undefined) {
            $('.MdBuffer .Document').find('.Md').each(function(){
                var objId = $(this).attr('id').substr(2);
                if(objId >= tmp) {
                    $(this).show();
                }
            });
        }
    },

    activeNum: function (num) {
        $('.MdBuffer ul.Pagenav').find('a.OutlinePage').each(function(index){
            if(index === num){
                $(this).addClass('Active');
            }else{
                $(this).removeClass('Active');
            }
        });
    }
};

/*
 * アウトラインエディターの制御クラス
 */
var mdOutlineEditor = function(){};
mdOutlineEditor.prototype = {
    init: function(){
        $('.OutlineEditor div.Document').children('.Md').each(function(){
            var id = $(this).attr("id");
            if(id === "blkTmpl" || id == "divideInfo"){
                return;
            }
            var num = id.substr(2);
            var tag = this.tagName;
            var digest = $(this).text().substr(0, 6);
            $(this).hide();
            var blk = $('#blkTmpl').clone().removeAttr("id");
            blk.find('.Tagname').text(tag);
            blk.find('.Digest').text(digest);
            blk.find('a.BtnExpand').click(function(){
                $('#'+id).toggle();
            });
            blk.find('button.DivideCtrl').attr('id', 'divide' + num).click(function(){
                var action = 'divide';
                if($(this).parent().next().next().hasClass('OutlineDivide')){
                    action = 'undivide';
                }
                $.ajax({
                    url: 'api/outlineEditor.cgi',
                    type: 'POST',
                    data: {
                        fid: getParam('fid'),
                        action: action,
                        num: parseInt(num) + 1,
                    }
                }).done(function(res){
                    var num = res.num;
                    var target = $('#md' + num).prev('div.Blk');
                    if(action === 'divide'){
                        var divideObj = $('<div>').addClass('OutlineDivide');
                        target.before(divideObj);
                    }else if(action === 'undivide'){
                        target.prev('div.OutlineDivide').remove();
                    }

                    //メッセージを表示
                    if($('section.Message').is(":hidden")){
                        var info = $('<div>').addClass('Info').text("コミットされていないバッファがあります");
                        $('section.Message').append(info);
                        $('section.Message').show();
                    }
                });
            });
            $(this).before(blk);
        });
        $('.OutlineEditor div.Document .DivideInfo').find('.Divide').each(function(){
            var num = $(this).text();
            var target = $('#md' + num).prev('div.Blk');
            var divideObj = $('<div>').addClass('OutlineDivide');
            target.before(divideObj);
        });
    }
};

/*
 * アウトライン出力制御クラス
 */
var mdOutline = function(){
    this.page = undefined;
};
mdOutline.prototype = {
    init: function () {
        this.page = 0;
        $('.Outline').find('.History.Page').each($.proxy(function(i, elm){
            this.adjustPage("History", elm);
        }, this));

        this.page = 0;
        $('.Outline').find('.Contents.Page').each($.proxy(function(i, elm){
            this.adjustPage("Contents", elm);
        }, this));

        this.page = 0;
        $('.Outline').find('.Document.Page').each($.proxy(function(i, elm){
            this.adjustDocumentPage(elm);
            $(elm).remove();
        }, this));

    },

    addPage : function (className, cPage, depth, obj){
        var newPage = $('<div>').addClass(className + ' Page  P' + (cPage + 1));
        var blk = obj;
        var ch = undefined;
        for(var i=0; i < depth; i++){
            var pObj = $(blk).parent().get(0);
            var pNewObj = $('<' + pObj.tagName + '>');
            if(ch !== undefined){
                pNewObj.append(ch);
            }
            ch = pNewObj;
            blk = pObj;
        }
        newPage.prepend(ch);
        $('.' + className + '.Page.P' + cPage).after(newPage);
        $(obj).prev().addClass("AdjustBlock");
    },

    recursivePage : function(className, obj, innerHeight, pageHeight, cHeight, depth) {
        var objHeight = $(obj).outerHeight(true);
        if(objHeight + cHeight > innerHeight) {
            if($(obj).children().length === 0) {
                this.addPage(className, this.page, depth, obj);
                this.page++;
                cHeight = objHeight;
            }else{
                $(obj).children().each($.proxy(function(index, elm){
                    var disp = $(elm).css('display');
                    if(disp === 'block' || disp === 'table' || disp === 'list-item') {
                        if(index === 0){
                            $('.' + className + '.Page.P' + this.page).append($('<' + obj.tagName + '>'));
                        }
                        cHeight = this.recursivePage(className, elm, innerHeight, pageHeight, cHeight, depth + 1);
                    }else{
                        this.addPage(className, this.page, depth, elm);
                        this.page++;
                        cHeight = objHeight;
                        return false;
                    }
                }, this));
            }
        }else{
            if(depth === 0){
                $('.' + className + '.Page.P' + this.page).append($(obj).clone());
            }else{  // TODO: １階層しか対応していない 2014/12/12
                $('.' + className + '.Page.P' + this.page).children().last().append($(obj).clone());
            }
            cHeight += objHeight;
        }

        return cHeight;
    },

    //目次・履歴のページ分割
    adjustPage : function(className, obj) {
        var innerHeight = $(obj).height();
        var pageHeight = $(obj).outerHeight();  //297mm
        var cHeight = 0.0;

        var newPage = $('<div>').addClass(className + ' Page P' + this.page);
        $('.' + className + '.Page').after(newPage);

        $(obj).children().each($.proxy(function(i, elm){
            cHeight = this.recursivePage(className, elm, innerHeight, pageHeight, cHeight, 0);
        } ,this));
	    $(obj).remove();
    },

    // 本文のページ分割
    adjustDocumentPage : function(obj) {
        var innerHeight = $(obj).height();
        var cHeight = 0.0;
        var newpage = 0;

        $(obj).after($('<div>').addClass("Document Page P" + this.page));

        $(obj).children().each($.proxy(function(i, elm){
            if(newpage === 1){
                $(".Document.Page.P" + this.page).after(
                     $('<div>').addClass("Document Page P" + (this.page + 1))
                );
                this.page++;
                newpage = 0;
            }

            $(".Document.Page.P" + this.page).append($(elm).clone());

            var objHeight = $(elm).outerHeight(true);
            if( cHeight + objHeight >= innerHeight ) {
                cHeight = objHeight;
                newpage = 1;
            }else{
                cHeight += objHeight;
            }
        }, this));
	this.page++;
    }
};

/***********************************************
 * 初回実行
 ***********************************************/
$(function(){
    // バッファ編集ページ
    $('.MdBuffer div.Document').children().each(function(){
        if($(this).hasClass("Md")){
            $(this).hover(
                function(){ $(this).addClass('Focus'); },
                function(){ $(this).removeClass('Focus'); }
            );
            $(this).click(function(){
                new mdEditForm($(this)).init();;
            });
        }else{
            $(this).addClass("Uneditable");
        }
    });
    new outlineDivide().init();   // 編集バッファのアウトライン
    new mdOutlineEditor().init(); // アウトラインエディタ
    new mdOutline().init();       // アウトライン出力

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

    var commitForm = false;
    $('#bufferCommitBtn').on('click', function(){
        $('#bufferCommitForm').fadeToggle();
        commitForm = true;
    });

    $('#cancelButton').click(function(){
	$('#bufferCommitForm').fadeToggle();
        commitForm = false;
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
        if(commitForm && ev.keyCode === 27){ //ESCキー
            //編集バッファのコミット窓
            $('#bufferCommitForm').fadeToggle();
            commitForm = false;
        }
        if(revisionViewer && ev.keyCode === 27){ //ESCキー
            //リヴィジョンヴューアー窓
            $('#revisionViewer').fadeToggle();
            revisionViewer = false;
        }
        if(diffViewer && ev.keyCode === 27){ //ESCキー
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
