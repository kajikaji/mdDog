'use strict'
/*
 * マークダウンエディタで使う編集フォームクラス
 */

define(function(){
    var mdEditForm = function(obj, fid){
        this.src = obj;
        this.id;
        this.fid = fid;
        this.elmId;
        this.mdId;
        this.formId;
        this.formtmpl = 'editform';
        this.api = 'api/mdEditor.cgi';
    };
    mdEditForm.prototype = {
        init: function() {
            var newForm = $('#' + this.formtmpl).clone()
            var tt = newForm.find('textarea.Editdata');

            this.id = Number(this.src.attr('id').slice(2));
            this.mdId = 'md' + this.id;
            this.formId = 'edit' + this.id;

            tt.attr('id', 'editdata' + this.id);
            newForm.attr('id', this.formId);

            if(this.id >= 0){
                this.elmId = 'elm' + this.id;

                var data= $('#' + this.elmId).text();
                var n = data.match(/\n/g).length + 1;
                tt.text(data).attr('rows', n);
            }

            this.src.after(newForm);
            newForm.show(); this.src.hide();
            this.attachButton();
        },

        attachButton: function(){
            $('#' + this.formId).find('button.Update').click($.proxy(function(){
                this.btnUpdate();
            }, this));
            if(this.id >= 0){
                $('#' + this.formId).find('button.Delete').click($.proxy(function(){
                    this.btnDelete();
                }, this));
            }else{
                $('#' + this.formId).find('button.Delete').hide();
            }
            $('#' + this.formId).find('button.Cancel').click($.proxy(function(){
                this.btnCancel();
            }, this));
            $('#' + this.formId).find('button.ImageView').click($.proxy(function(){
                this.btnImageView();
            }, this));
        },

        btnUpdate: function(){
            var editdata = $('#' + this.formId).find('textarea.Editdata').val();
            $.ajax({
                url: this.api,
                type: 'POST',
                data:{
                    fid: this.fid, 
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
            $.ajax({
                url: this.api,
                type: 'POST',
                data:{
                    fid: this.fid, 
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
            $.ajax({
                url: this.api,
                type: 'GET',
                data:{
                    fid: this.fid, 
                    action: 'image_list', 
                }
            }).done($.proxy(function(res){
                var length = res.length;
                var list = $('#' + this.formId).find('ul.ImageList');
                list.show();
                for(var i=0; i < res.length; i++){
                    var img = $('<img>').attr('src', 'md_imageView.cgi?image=' + res[i].filename + '&fid=' + this.fid + '&tmp=1&thumbnail=1');
                    var anch = $('<a>').addClass('Btn').text('挿入');
                    anch.data("image", res[i].filename);
                    anch.click($.proxy(function(ev){
                        this.insertAtCaret($(ev.target).data("image"));
                    }, this));

                    var imageRec = $('<li>').append(img).append(anch);
                    list.append(imageRec);
                }
            }, this));
        },

        insertAtCaret: function(filename) {
            var obj = $('#editdata' + this.id);
            var str = '![mdDog](md_imageView.cgi?fid=' + this.fid + '&image=' + filename + ')';

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

            if(this.elmId !== undefined){
                $('#' + this.elmId).attr('id', this.elmId + 'org');
                var $elmObj = $(res.row);
                $('#' + this.elmId + 'org').after($elmObj);
                $('#' + this.elmId + 'org').remove();
                var eLeng = $elmObj.length;
                if(eLeng > 1){
                    this.resetTreeId($elmObj.last().next(), eLeng - 1, 'elm');
                }
            }else{
                $('#bufferCommitForm .Rowdata').append(res.row);
            }

            $newObj.hover(
                function(){ $(this).addClass('Focus'); },
                function(){ $(this).removeClass('Focus'); }
            );
            $newObj.click(function(){
                var eForm = new mdEditForm($(this));
                eForm.init();
            });
            this.checkBlankDocument();
        },
        deleteSuccess: function(res) {
            $('#' + this.formId).remove();
            var $nextMd = $('#' + this.mdId).next();
            $('#' + this.mdId).remove();
            this.resetTreeId($nextMd, -1, 'md');
            var $nextElm = $('#' + this.elmId).next();
            $('#' + this.elmId).remove();
            this.resetTreeId($nextElm, -1, 'elm');
            this.checkBlankDocument();
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
        },
        checkBlankDocument: function(){
            if($('.MdBuffer div.Document').children().length == 0){
                var blank = $('<div>').addClass("Blank").attr("id", "md-1");
                $('.MdBuffer div.Document').append(blank);
                blank.hover(
                    function(){ blank.addClass('Focus'); },
                    function(){ blank.removeClass('Focus'); }
                );
                blank.click(function(){
                    new mdEditForm(blank).init();;
                });
            }
        }
    };

    return mdEditForm;
});