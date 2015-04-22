'use strict'

define(['leftMenu'], function(LeftMenu){
    var bufferEditor = function(){};
    bufferEditor.prototype = $.extend({}, LeftMenu.prototype, {
        init: function(){
            this.movableMenu($('.BufferEditMenu'));

            if( $('#jumpTopBtn').length ){
                this.jumpToTop($('#jumpTopBtn'));
            }

            if($('body > section.MdBuffer .BufferEdit').length){
                require(['mdBufferEditor'], function(MdBufferEditor){
                    new MdBufferEditor().init();
                });
            }
        }
    });

    return bufferEditor;
});
