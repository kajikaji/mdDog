'use strict'
/*
 * バッファ編集エディタのアウトライン分割制御クラス
 */

define(function(){
    var mdOutlineDivide = function() {};
    mdOutlineDivide.prototype = {
        init: function (){
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

        showPage: function(dividesAr, id){
            var tmp = undefined;
            for(var i=0; i < dividesAr.length; i++) 
            {
                if( i === id ){
                    tmp = dividesAr[i];
                }else{
                    if( tmp !== undefined ){
                        for(var j=tmp; j < dividesAr[i]; j++){
                            $('#md' + j).show();
                        }
                        tmp = undefined;
                    }
                }
            }
            if( tmp !== undefined ){
                $('.MdBuffer .Document').find('.Md').each(function(){
                    var objId = $(this).attr('id').substr(2);
                    if( objId >= tmp ){
                        $(this).show();
                    }
                });
            }
        },

        activeNum: function(num){
            $('.MdBuffer ul.Pagenav').find('a.OutlinePage').each(function(index){
                if( index === num ){
                    $(this).addClass('Active');
                }else{
                    $(this).removeClass('Active');
                }
            });
        }
    };

    return mdOutlineDivide;
});
