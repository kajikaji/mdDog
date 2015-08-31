'use strict'
/*
 * マークダウンエディタの制御クラス
 */

define(['editBufferParagraphCtrl', 'editBufferDivideCtrl'],
       function(ParagraphCtrl, DivideCtrl){
    var editor = function(){
        this.mdDoc     = $('.BufferEdit.Markdown .Document');
        this.fid       = getParam('fid');
        this.api_clear = 'api/docEditor.cgi';
    };

    editor.prototype = {
        init: function() {
            var cnt = 0;
            this.mdDoc.children().each($.proxy(function(i, elm){
                var paragraph = new ParagraphCtrl($(elm), this.fid);
                paragraph.init();
                var mdObj = paragraph.getMdParagraph();
                $(mdObj).attr("id", "md" + i);
                $(mdObj).find('.Raw').text($('#raw' + i).text());
                $('#raw' + i).remove();
                this.mdDoc.append(mdObj);
                cnt++;
            }, this));
            if( cnt == 0 ){
                var paragraph = new ParagraphCtrl($('<div>').addClass('Blank'), this.fid);
                paragraph.init();
                var mdObj = paragraph.getMdParagraph();
                $(mdObj).attr("id", "md-1");

                this.mdDoc.append(mdObj);
            }

            new DivideCtrl().init();
        },
        setClearBtn: function(btnObj){
            btnObj.on('click', $.proxy(this.clearAction, this));
        },
        clearAction: function(){
            $.ajax({
                url  : this.api_clear,
                type : 'POST',
                data : {
                    fid : this.fid,
                    action : 'bufferclear',
                },
                timeout: 5000
            }).done($.proxy(function(res){
                this.cleanupDocument();

                //setup the document
                this.mdDoc.append(res.md);
                var insertPt = this.mdDoc;
                $(res.rows).each(function(i,elm){
                    var raw = $('<div>').attr('id','raw'+i).addClass('Raw');
                    raw.text(elm);
                    insertPt.after(raw);
                    insertPt = raw;
                });
                
                //initial the document
                this.init();
                $('#bufferCommitBtn').addClass('Disabled');
                $('#clearBtn').addClass('Disabled');
            }, this));
        },
        cleanupDocument: function(){
            this.mdDoc.children().each($.proxy(function(i, elm){
                if( $(elm).hasClass('Md') ){
                    $(elm).off('click');
                    $(elm).find('.DivideCtrl a').off('click');
                }
                $(elm).remove();
            }, this));
        }
    };

    return editor;
});
