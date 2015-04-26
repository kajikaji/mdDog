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

                var target = $("#md" + id);
                if(id > 0){
                    var pageDivide = $('<div>').addClass('PageDivide').attr('id', 'page' + index);
                    target.before(pageDivide);
                }
                target.find('.DivideCtrl').append(this.getPageNum(index));
            }, this));

            $('.BufferEdit.Markdown .Document').find('.Md').each($.proxy(function(index, obj){
                var id = Number($(obj).attr('id').substr(2));
                if( id < 0 ){
                    $(obj).find('.DivideCtrl').prepend(this.getPageNum(0));
                }else if( id > 0 ){
                    $(obj).find('.DivideCtrl').prepend(this.getDivideBtn(obj));
                }
            }, this));
        },

        getPageNum: function(index) {
            var num = $('<div>').addClass('PageNum');
            num.text('P ' + (index + 1) );
            return num;
        },
        getDivideBtn: function(obj){
            var btn = $('<a>').addClass('DivideBtn');
            var icon = $('<span>').addClass('typcn');
            if( $(obj).prev().hasClass('PageDivide') ){
                icon.addClass('typcn-backspace');
            }else{
                icon.addClass('typcn-media-eject-outline');
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
                }).done($.proxy(function(res){
                    var target = $("#md" + res.num);
                    if( res.action === 'divide'){
                        target.before($('<div>').addClass('PageDivide'));
                        target.find('.DivideBtn span').addClass('typcn-backspace').removeClass('typcn-media-eject-outline');
                        target.find('.DivideCtrl').append(this.getPageNum(0));
                    }else{
                        target.prev('.PageDivide').remove();
                        target.find('.DivideBtn span').addClass('typcn-media-eject-outline').removeClass('typcn-backspace');
                        target.find('.DivideCtrl').find('.PageNum').remove();
                    }

                    $('.BufferEdit.Markdown .Document').find('.PageDivide').each(function(i, elm){
                        $(elm).attr('id', 'page' + (i + 1));
                        $(elm).next('.Md').find('.PageNum').text('P ' + (i + 2));
                    });
                }, this));
            }, this));
            return btn;
        }
    };

    return divideCtrl;
});
