/***********************************************
 * 関数定義
 ***********************************************/
function activeBufferList(uid) {
    $('#buffer-list').find('li').each(function(){
        var id = Number($(this).attr("id").substr(7));
        if(uid === id){
            $(this).addClass("active");
        }else{
            $(this).removeClass("active");
        }
    });
}

function showLog(uid) {
    $('.gitlog .logtable').each(function(){
        var id = $(this).attr("id").substr(11);
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
    $('form.md_buffer_fix .rowdata').find('.elm').each(function(){
        $document += $(this).text();
        $document += "\n";
    });
    $('form.md_buffer_fix').find('textarea.document').text($document);
    document.forms['commitForm'].submit();   
}

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
        this.elmId = 'elm-' + this.id;
        this.mdId = 'md' + this.id;
        this.formId = 'edit-' + this.id;

        var newForm = $('#' + this.formtmpl).clone().attr('id', this.formId);
        var data= $('#' + this.elmId).text();
        var n = data.match(/\n/g).length + 1;
        newForm.find('textarea.editdata').text(data).attr('rows', n);
        this.src.after(newForm);
        newForm.show(); this.src.hide();

        this.attachButton();
    },

    attachButton: function(){
        $('#' + this.formId).find('button.update').click($.proxy(function(){
            this.btnUpdate();
        }, this));
        $('#' + this.formId).find('button.delete').click($.proxy(function(){
            this.btnDelete();
        }, this));
        $('#' + this.formId).find('button.cancel').click($.proxy(function(){
            this.btnCancel();
        }, this));
    },

    btnUpdate: function(){
            var fid = getParam("fid");
            var editdata = $('#' + this.formId).find('textarea.editdata').val();
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
            }, this));
    },
    btnCancel: function(){
            $('#' + this.formId).remove();
            $(this.src).show();
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
	        this.resetTreeId($elmObj.last().next(), eLeng - 1, 'elm-');
        }

        $newObj.hover(
            function(){ $(this).addClass('focus'); },
            function(){ $(this).removeClass('focus'); }
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
	this.resetTreeId($nextElm, -1, 'elm-');
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

var outlineDivide = function() {};
outlineDivide.prototype = {
    init: function () {
        var divide = [];
        $('.md_buffer  ul.pagenav').find('a.outline_page').each($.proxy(function(index, obj){
            divide.push($(obj).data('elm'));
            $(obj).data('id', index);
            $(obj).click($.proxy(function(ev){
                $('.md_buffer .document .md').hide();

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
            $('.md_buffer .document').find('.md').each(function(){
                var objId = $(this).attr('id').substr(2);
                if(objId >= tmp) {
                    $(this).show();
                }
            });
        }
    },

    activeNum: function (num) {
        $('.md_buffer ul.pagenav').find('a.outline_page').each(function(index){
            if(index === num){
                $(this).addClass('active');
            }else{
                $(this).removeClass('active');
            }
        });
    }
};

// アウトラインエディター
var mdOutlineEditor = function(){};
mdOutlineEditor.prototype = {
    init: function(){
        $('.outline_editor div.document').children('.md').each(function(){
            var id = $(this).attr("id");
            if(id === "blk_tmpl" || id == "divide_info"){
                return;
            }
            var num = id.substr(2);
            var tag = this.tagName;
            var digest = $(this).text().substr(0, 6);
            $(this).hide();
            var blk = $('#blk_tmpl').clone().removeAttr("id");
            blk.find('.tagname').text(tag);
            blk.find('.digest').text(digest);
            blk.find('a.btn_expand').click(function(){
                $('#'+id).toggle();
            });
            blk.find('button.divide_ctrl').attr('id', 'divide' + num).click(function(){
                var action = 'divide';
                if($(this).parent().next().next().hasClass('outline_divide')){
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
                    var target = $('#md' + num).prev('div.blk');
                    if(action === 'divide'){
                        var divideObj = $('<div>').addClass('outline_divide');
                        target.before(divideObj);
                    }else if(action === 'undivide'){
                        target.prev('div.outline_divide').remove();
                    }
                });
            });
            $(this).before(blk);
        });
        $('.outline_editor div.document .divide_info').find('.divide').each(function(){
            var num = $(this).text();
            var target = $('#md' + num).prev('div.blk');
            var divideObj = $('<div>').addClass('outline_divide');
            target.before(divideObj);
        });
    }
};

// アウトライン
var mdOutline = function(){
    this.page = undefined;
};
mdOutline.prototype = {
    init: function () {
        $('.outline').find('.page').each($.proxy(function(i, elm){
            var className = elm.className.split(" ")[0];
            this.page = 0;
            if(className === 'document'){
                this.adjustDocumentPage(className, elm);
                $(elm).remove();
            }else{
                this.adjustPage(className, elm);
            }
        }, this));
    },

    addPage : function (className, cPage, depth, obj){
        var newPage = $('<div>').addClass(className).addClass('page');
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
        $('.' + className + '.page.p' + cPage).after(newPage.addClass('p' + (cPage + 1)));
        $(obj).prev().addClass("adjust-block");
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
                            $('.' + className + '.page.p' + this.page).append($('<' + obj.tagName + '>'));
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
                $('.' + className + '.page.p' + this.page).append($(obj).clone());
            }else{  // TODO: １階層しか対応していない 2014/12/12
                $('.' + className + '.page.p' + this.page).children().last().append($(obj).clone());
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

        var newPage = $('<div>').addClass(className).addClass('page');
        $('.' + className + '.page').after(newPage.addClass('p' + this.page));

        $(obj).children().each($.proxy(function(i, elm){
            cHeight = this.recursivePage(className, elm, innerHeight, pageHeight, cHeight, 0);
        } ,this));
	    $(obj).remove();
    },

    // 本文のページ分割
    adjustDocumentPage : function(className, obj) {
        var innerHeight = $(obj).height();
        var cHeight = 0.0;
        var newpage = 0;

        $(obj).after($('<div>').addClass(className).addClass("page").addClass("p" + this.page));

        $(obj).children().each($.proxy(function(i, elm){
            if(newpage === 1){
                $("." + className + ".page.p" + this.page).after(
                     $('<div>').addClass(className).addClass("page").addClass("p" + (this.page + 1))
                );
                this.page++;
                newpage = 0;
            }

            $("." + className + ".page.p" + this.page).append($(elm).clone());

            var objHeight = $(elm).outerHeight(true);
            if( cHeight + objHeight >= innerHeight ) {
                cHeight = objHeight;
                newpage = 1;
            }else{
                cHeight += objHeight;
            }
        }, this));
    }
};

/***********************************************
 * 初回実行
 ***********************************************/
$(function(){
    /** バッファ編集ページ **/
    $('.md_buffer div.document').children().each(function(){
        if($(this).hasClass("md")){
            $(this).hover(
                function(){ $(this).addClass('focus'); },
                function(){ $(this).removeClass('focus'); }
            );
            $(this).click(function(){
                new mdEditForm($(this)).init();;
            });
        }else{
            $(this).addClass("uneditable");
        }
    });
    new outlineDivide().init();   // 編集バッファのアウトライン
    new mdOutlineEditor().init(); // アウトラインエディタ
    new mdOutline().init();       // アウトライン出力

    var $outline = false;
    $('#printOutline').on("click", function(){
        $outline = true;

        $('body').children().each(function(){
            if(!$(this).hasClass('outline')){
                $(this).slideUp('100');
            }else{
                $(this).addClass('print-format');
            }
        });
    });

    $(window).keydown(function(ev){
        if($outline){
            $outline = false;

            $('body').children().each(function(){
                if(!$(this).hasClass('outline')){
                    $(this).slideDown('100');
                }else{
                    $(this).removeClass('print-format');
                }
            });
        }
    });
});
