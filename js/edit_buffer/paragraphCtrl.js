'use strict'
/*
 * マークダウンエディタで使う編集フォームクラス
 */

define(function(){
    var paragraphCtrl = function(obj, fid){
        this.src      = obj;
        this.fid      = fid;
        this.formtmpl = 'editform';
        this.api      = 'api/mdEditor.cgi';

        this.id;
        this.elmId;
        this.mdId;
        this.formId;
        this.tt;
    };
    paragraphCtrl.prototype = {
        init: function() {
            this.src.hover(
                function(){ $(this).addClass('Focus'); },
                function(){ $(this).removeClass('Focus'); }
            );
            this.src.click($.proxy(function(){
                this.show();
            }, this));
        },

        show:function(){
            var newForm = $('#' + this.formtmpl).clone()
            this.tt      = newForm.find('textarea.Editdata');
            this.id     = Number(this.src.parent().attr('id').slice(2));
            this.mdId   = 'md'   + this.id;
            this.formId = 'edit' + this.id;

            if( this.id >= 0 ){
                var data = $('#' + this.mdId).find('.Raw').text();
                var n    = data.match(/\n/g).length + 1;
                this.tt.text(data).attr('rows', n);
            }
            this.tt.attr('id', 'editdata' + this.id);
            newForm.attr('id', this.formId);


            this.src.after(newForm);
            newForm.show(); this.src.hide();
            this.attachButton();
        },

        attachButton: function(){
            $('#' + this.formId).find('button.Update').on('click', $.proxy(function(){
                this.btnUpdate();
            }, this));
            if( this.id >= 0 ){
                $('#' + this.formId).find('button.Delete').on('click', $.proxy(function(){
                    this.btnDelete();
                }, this));
            }else{
                $('#' + this.formId).find('button.Delete').hide();
            }
            $('#' + this.formId).find('button.Cancel').on('click', $.proxy(function(){
                this.btnCancel();
            }, this));
            $('#' + this.formId).find('button.ImageView').on('click', $.proxy(function(){
                this.btnImageView();
            }, this));
        },

        detachButton: function(){
            $('#' + this.formId + ' ul.ImageList').find('li a.Btn').each(function(){
                $(this).off('click');
            });

            $('#' + this.formId).find('button.Update').off('click');
            if( this.id >= 0 ){
                $('#' + this.formId).find('button.Delete').off('click');
            }
            $('#' + this.formId).find('button.Cancel').off('click');
            $('#' + this.formId).find('button.ImageView').off('click');
        },

        btnUpdate: function(){
            var editdata = this.tt.val();
            $.ajax({
                url  : this.api,
                type : 'POST',
                data : {
                    fid    : this.fid, 
                    eid    : this.id>=0?this.id:0,
                    action : 'update', 
                    data   : editdata
                },
                timeout: 5000
            }).done($.proxy(function(res){
                this.updateSuccess(res);
                this.updateMessage();
            }, this));
        },
        btnDelete: function(){
            $.ajax({
                url  : this.api,
                type : 'POST',
                data :{
                    fid    : this.fid, 
                    eid    : this.id>=0?this.id:0,
                    action : 'delete',
                },
                timeout: 5000
            }).done($.proxy(function(res){
                this.deleteSuccess(res);
                this.updateMessage();
            }, this));
        },
        btnCancel: function(){
            this.detachButton();
            $('#' + this.formId).remove();
            $(this.src).show();
        },
        btnImageView: function(){
            var imageList = $('#' + this.formId).find('ul.ImageList');
            var disp = imageList.css('display');
            if( disp === 'none' || disp === undefined ){
                $.ajax({
                    url  : this.api,
                    type : 'GET',
                    data :{
                        fid    : this.fid, 
                        action : 'image_list', 
                    },
                    timeout: 5000
                }).done($.proxy(function(res){
                    var length = res.length;
                    imageList.show();
                    for(var i=0; i < res.length; i++){
                        var img = $('<img>').attr('src', 'md_imageView.cgi?image=' + res[i].filename + '&fid=' + this.fid + '&tmp=1&thumbnail=1');
                        var nametag = $('<div>').addClass('NameTag').text(res[i].filename);
                        var anch = $('<a>').addClass('Btn').text('挿入');
                        anch.data("image", res[i].filename);
                        anch.on('click', $.proxy(function(ev){
                            this.insertAtCaret($(ev.target).data("image"));
                        }, this));

                        var imageRec = $('<li>').append(img).append(nametag).append(anch);
                        imageList.append(imageRec);
                    }
                }, this));
            }else{
                imageList.find('li').each(function(){
                    $(this).find('a.Btn').off('click');
                    $(this).remove();
                });
                imageList.hide();
            }
        },

        insertAtCaret: function(filename){
            var obj = $('#editdata' + this.id);
            var str = '![mdDog](md_imageView.cgi?fid=' + this.fid + '&image=' + filename + ')';

            obj.focus();
            if( navigator.userAgent.match(/MSIE/) ){
                var r = document.selection.createRange();
                r.text = str;
                r.select();
            }else{
                var s  = obj.val();
                var p  = obj.get(0).selectionStart;
                var np = p + str.length;
                obj.val(s.substr(0, p) + str + s.substr(p));
                obj.get(0).setSelectionRange(np, np);
            }
        },

        updateSuccess: function(res){
            require(['editBufferDivideCtrl'], $.proxy(function(DivideCtrl){
                $('#' + this.formId).remove();
                $('#' + this.mdId).attr('id', this.mdId + 'org');
                var $ptr = $('#' + this.mdId + 'org');
                var $tmp  = $ptr;
                var $cnt  = 0;
                if( this.id < 0 ){  this.id = 0;  }

                $(res).each($.proxy(function(i, elm){
                    var paragraph = new paragraphCtrl($(elm.md), this.fid);
                    paragraph.init();
                    var $mdPrgh = paragraph.getMdParagraph();
                    $mdPrgh.find('.Raw').text(elm.raw);
                    $tmp.after($mdPrgh);
                    if( $tmp.attr('id') === this.mdId + 'org' ){
                        $ptr = $tmp.next();
                        $tmp.remove();
                    }

                    if( this.id === 0 && i === 0 ){
                        $mdPrgh.find('.DivideCtrl').append( new DivideCtrl().getPageNum(0) );
                    }else{
                        $mdPrgh.find('.DivideCtrl').append( new DivideCtrl().getDivideBtn($mdPrgh) );
                        if( $mdPrgh.prev().hasClass('PageDivide') ){
                            var pagenum = Number($mdPrgh.prev().attr('id').substr(4));
                            $mdPrgh.find('.DivideCtrl').append( new DivideCtrl().getPageNum(pagenum) );
                        }
                    }
                    $tmp = $mdPrgh;
                    $cnt++;
                }, this));
                if( $cnt > 0 ){
                    this.resetTreeId($ptr, this.id>=0?this.id:0, 'md');
                }
                this.checkBlankDocument();
                this.detachButton();
            }, this));
        },
        deleteSuccess: function(res){
            $('#' + this.formId).remove();
            var divideFlg = false;
            if( $('#' + this.mdId).prev().hasClass('PageDivide') ){
                divideFlg = true;
            }
            var $nextMd = $('#' + this.mdId).next();
            $('#' + this.mdId).remove();

            if( $nextMd.length ){
                //改ページブロックが重複すれば削る
                if( $nextMd.hasClass('PageDivide')
                    && (this.id === 0 || divideFlg) ){
                    var pagenum = Number($nextMd.attr('id').substr(4));
                    var $tmp = $nextMd.next();
                    $nextMd.remove();
                    $nextMd = $tmp;
                }

                //次段落とマージしていないかチェック
                $nextMd = this.checkMergeParagraph(res, $nextMd);

                //MD段落のid制御
                this.resetTreeId($nextMd, this.id, 'md');

                //改ページコントロール部の制御
                if( this.id === 0 ){
                    $nextMd.find('.DivideCtrl').find('.DivideBtn').remove();
                    require(['editBufferDivideCtrl'], $.proxy(function(DivideCtrl){
                        if( $nextMd.find('.DivideCtrl .PageNum').length ){
                            $nextMd.find('.DivideCtrl .PageNum').text('P 1');
                        }else{
                            $nextMd.find('.DivideCtrl').append(
                                new DivideCtrl().getPageNum(0)
                            );
                        }
                    }, this));
                    this.resetPageNum($nextMd, 1);
                }
                if( $nextMd.prev().hasClass('PageDivide') ){
                    if( !$nextMd.find('.DivideCtrl .PageNum').length ){
                        $nextMd.find('.DivideBtn').after($('<div>').addClass('PageNum'));
                    }
                    var pagenum = Number($nextMd.prev().attr('id').substr(4));
                    $nextMd.find('.DivideCtrl .PageNum').text('P ' + (pagenum + 1));
                    $nextMd.find('.DivideBtn i').addClass('DeletePoint').removeClass('Eject');
                    pagenum++;
                    this.resetPageNum($nextMd, pagenum);
                }
            }else if( divideFlg ){ //ドキュメント最後に改ページが残った時の対処
                var $lastDivide = $('.BufferEdit.Markdown .Document').children().last();
                $lastDivide.remove();
            }
            this.checkBlankDocument();
            this.detachButton();
        },
        updateMessage: function(){
            if( $('#bufferCommitBtn').hasClass('Disabled') ){
                $('#bufferCommitBtn').removeClass('Disabled');
            }
            if( $('#clearBtn').hasClass('Disabled') ){
                $('#clearBtn').removeClass('Disabled');
            }
        },
        resetTreeId: function(obj, inc, prefix){
            while( obj.length > 0 ){
                if( obj.hasClass('Md') ){
                    obj.attr('id', prefix + inc);
                    inc++;
                }
                obj = obj.next();
            }
        },
        resetPageNum: function(obj, num){
            while( obj.length ){
                if( obj.hasClass('PageDivide') ){
                    if( obj.next('.Md').length ){
                        obj.attr('id', 'page' + num);
                        obj.next('.Md').find('.PageNum').text('P ' + (num + 1));
                    }else{ //ドキュメントの最終段落の場合
                        var tmp = obj.next();
                        obj.remove();
                        obj = tmp;
                        break;
                    }
                    num++;
                }
                obj = obj.next();
            }
        },
        checkBlankDocument: function(){
            if( $('.BufferEdit.Markdown .Document').children().length == 0 ){
                var paragraph = new paragraphCtrl($('<div>').addClass('Blank'), this.fid);
                paragraph.init();
                var mdObj = paragraph.getMdParagraph();
                $(mdObj).attr('id', 'md-1');
                require(['editBufferDivideCtrl'], $.proxy(function(DivideCtrl){
                    $(mdObj).find('.DivideCtrl').append(
                        new DivideCtrl().getPageNum(0)
                    );
                }, this));
                $('.BufferEdit.Markdown .Document').append(mdObj);
            }
        },

        getMdParagraph: function() {
            this.src.addClass('MdBody');
            var divideCtrl = $('<div>').addClass('DivideCtrl');
            var rawdata = $('<div>').addClass('Raw');
            var mdParagraph = $('<div>').addClass('Md').append(this.src).append(divideCtrl).append(rawdata);
            return mdParagraph;
        },

        checkMergeParagraph: function(res, obj){
            var flg = false;
            var nextRaw = obj.find('.Raw').text().replace(/\n+$/g, '');
            while( obj.hasClass('Md')
                   && nextRaw !== res.raw ){
                flg = true;
                var tmp = obj.next();
                obj.remove();
                obj = tmp;
                if( obj.hasClass('PageDivide') ){
                    tmp = obj.next();
                    obj.remove();
                    obj = tmp;
                }
                nextRaw = obj.find('.Raw').text().replace(/\n+$/g, '');
            }
            if( flg ){
                var prevId = Number(res.eid) - 1;
                if( prevId >= 0 ){
                    $.ajax({
                        url: this.api,
                        type: 'GET',
                        data: {
                            fid: this.fid,
                            eid : prevId
                        },
                        timeout: 5000
                    }).done($.proxy(function(res){
                        var prev = $('#md' + prevId);
                        prev.find('.MdBody').remove();
                        this.src = $(res[0].html).addClass('MdBody');
                        prev.prepend(this.src);
                        this.init();
                        prev.find('.Raw').text(res[0].raw);
                    }, this));

                }
            }

            return obj;
        }
    };

    return paragraphCtrl;
});