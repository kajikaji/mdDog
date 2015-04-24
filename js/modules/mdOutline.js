'use strict'
/*
 * アウトライン出力制御クラス
 */
define(function(){
    var mdOutline = function(){
        this.page = undefined;
    };
    mdOutline.prototype = {
        init: function (){
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

            //目次にページ番号を挿入
	        $('.Outline').find('.Contents.Page').each($.proxy(function(i, elm){
	            $(elm).find('.List .Caption').each(function(){
		            var num     = Number($(this).attr('id').substr(7));
		            var pageObj = $('#document' + num).parent('.Document.Page');
		            var page    = Number(pageObj.attr('class').split(' ')[2].substr(1)) + 1;
		            $(this).find('span.PageNum').text(page);
	            });
	        }, this));

            this.outlineButton();
        },

        addPage : function (className, cPage, depth, obj){
            var newPage = $('<div>').addClass(className + ' Page  P' + (cPage + 1));
            var oldPage = $(obj).parents('.Page');
            var blk     = oldPage;
            var ch      = undefined;
            for(var i=0; i < depth; i++){
                var pObjs = blk.children();
                var k=0;
                while($(pObjs.get(k)).hasClass('Subject')){
                    k++;
                }
                var pObj = pObjs.get(k);
                var pNewObj = $('<' + pObj.tagName + '>');
                pNewObj.addClass(pObj.className);
                newPage.append(pNewObj)

                blk = pObj;
            }
            $('.' + className + '.Page.P' + cPage).after(newPage);
            $(obj).prev().addClass("AdjustBlock");
        },

        recursivePage : function(className, obj, innerHeight, pageHeight, cHeight, depth) {
            var objHeight = $(obj).outerHeight(true);
            if( objHeight + cHeight > innerHeight ){
                if( $(obj).children().length === 0 ){
                    this.addPage(className, this.page, depth, obj);
                    this.page++;
                    cHeight = objHeight;
                }else{
                    $(obj).children().each($.proxy(function(index, elm){
                        var disp = $(elm).css('display');
                        if( disp === 'block' || disp === 'table' || disp === 'list-item' ) {
                            if( index === 0 ){
                                $('.' + className + '.Page.P' + this.page).append($('<' + obj.tagName + '>').addClass(obj.className));
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
                if( depth === 0 ){
                    $('.' + className + '.Page.P' + this.page).append($(obj).clone());
                }else{  // TODO: １階層しか対応していない 2014/12/12
                    $('.' + className + '.Page.P' + this.page).children().last().append($(obj).clone());
                }
                cHeight += objHeight;
            }

            return cHeight;
        },

        //目次・履歴のページ分割
        adjustPage : function(className, obj){
            var innerHeight = $(obj).height();
            var pageHeight  = $(obj).outerHeight();  //297mm
            var cHeight     = 0.0;
            var newPage     = $('<div>').addClass(className + ' Page P' + this.page);
            $('.' + className + '.Page').after(newPage);

            $(obj).children().each($.proxy(function(i, elm){
                cHeight = this.recursivePage(className, elm, innerHeight, pageHeight, cHeight, 0);
            } ,this));
	        $(obj).remove();
        },

        // 本文のページ分割
        adjustDocumentPage : function(obj) {
            var innerHeight = $(obj).height();
            var cHeight     = 0.0;
            var newpage     = 0;

            $(obj).after($('<div>').addClass("Document Page P" + this.page));

            $(obj).children().each($.proxy(function(i, elm){
                if( newpage === 1 ){
                    $(".Document.Page.P" + this.page).append(this.pageFooter(this.page + 1));
                    $(".Document.Page.P" + this.page).after(
                        $('<div>').addClass("Document Page P" + (this.page + 1))
                    );
                    this.page++;
                    newpage = 0;
                }

                $(".Document.Page.P" + this.page).append($(elm).clone());

                var objHeight = $(elm).outerHeight(true);
                if( cHeight + objHeight >= innerHeight ){
                    cHeight = objHeight;
                    newpage = 1;
                }else{
                    cHeight += objHeight;
                }
            }, this));

            $(".Document.Page.P" + this.page).append(this.pageFooter(this.page + 1));
            this.page++;
        },

        pageFooter: function(num){
	        var footer = $('<div>').addClass("PageFooter");
	        footer.append($('<div>').addClass("PageNum").text(num));
	        return footer;
        },

        outlineButton: function(){
            $('#printOutline').on("click", function(){
                $('body').children().each(function(){
                    if( !$(this).hasClass('Outline') ){
                        $(this).slideUp('100');
                    }else{
                        $(this).addClass('PrintFormat');
                    }
                });

                $(window).one('keydown', function(ev){
                    $('body').children().each(function(){
                        if( !$(this).hasClass('Outline') ){
                            $(this).slideDown('100');
                        }else{
                            $(this).removeClass('PrintFormat');
                        }
                    });
                });
            });
        }
    };

    return mdOutline;
});