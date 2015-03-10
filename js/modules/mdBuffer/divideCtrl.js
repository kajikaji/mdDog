'use strict'
/*
 * バッファ編集エディタのアウトライン分割制御クラス
 */

define(function(){
    var divideCtrl = function() {
        this.activeIndex = 0;
    };
    divideCtrl.prototype = {
        init: function (){
            var divide = [];
            $('.MdBuffer  ul.Pagenav').find('a.OutlinePage').each($.proxy(function(index, obj){
                var id = $(obj).data('elm');
                divide.push(id);

                if(id > 0){
                    var target = $("#md" + id);
                    target.before($('<div>').addClass('PageDivide'));
                }
            }, this));

            $('.BufferEdit.Markdown .Document').find('.Md').each($.proxy(function(index, obj){
                var id = Number($(obj).attr('id').substr(2));
                if(id <= 0){
                    return;
                }
                $(obj).find('.DivideCtrl').append(this.getDivideBtn(obj));
            }, this));
        },

        getDivideBtn: function(obj){
            var btn = $('<a>').addClass('DivideBtn');
            var icon = $('<i>').addClass('Glyph');
            if( $(obj).prev().hasClass('PageDivide') ){
                icon.addClass('DeletePoint');
            }else{
                icon.addClass('Eject');
            }
            btn.append(icon);
            btn.click($.proxy(function(){
                var action = 'divide';
                if( $(obj).prev().hasClass('PageDivide') ){
                    action = 'undivide';
                }
                var mdId = Number($(obj).attr('id').substr(2));
                $.ajax({
                    url: 'api/outlineEditor.cgi',
                    type: 'POST',
                    data: {
                        fid: getParam('fid'),
                        action: action,
                        num: mdId,
                    }
                }).done(function(res){
                    var target = $("#md" + res.num);
                    if( res.action === 'divide'){
                        target.before($('<div>').addClass('PageDivide'));
                        target.find('.DivideBtn i').addClass('DeletePoint').removeClass('Eject');
                    }else{
                        target.prev('.PageDivide').remove();
                        target.find('.DivideBtn i').addClass('Eject').removeClass('DeletePoint');
                    }
                });
            }, this));
            return btn;
        }
    };

    return divideCtrl;
});
