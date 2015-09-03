'use strict'

require.config({
    paths: {
        mdOutline       :'doc_outline/mdOutline',
        outlineViewer   :'doc_outline/outlineViewer',
        leftMenu        :'modules/leftMenu',
        modalLoading    :'modules/modalLoading'
    },
    shim: {
        'outlineViewer' : {
	        deps: [
                'leftMenu'
            ]
        }
    }
});

require(['mdOutline', 'outlineViewer', 'modalLoading'],
        function(Outline, OutlineViewer, ModalLoading){
    var loading = new ModalLoading();
    loading.show($.proxy(function(){
        new Outline().init();
        new OutlineViewer($('.OutlineMenu')).init();
        loading.remove();
    }, this));
});
