'use strict'

require.config({
    paths: {
        editBufferHeadline      :'doc_editor/headline',
        editBufferCommitForm    :'doc_editor/commitForm',
        editBufferEditor        :'doc_editor/editor',
        editBufferDivideCtrl    :'doc_editor/divideCtrl',
        editBufferParagraphCtrl :'doc_editor/paragraphCtrl',
        editBufferMessage       :'doc_editor/bufferMessage'
    },

    shim:{
        'editBufferEditor' : {
	        deps: [
                'UTIL',
                'modalLoading',
                'editBufferDivideCtrl',
                'editBufferParagraphCtrl'
            ]
        }
    }
});

require(['leftMenu'], function(LeftMenu){

    if( $('.BufferEditMenu').length ){
        var leftMenu = new LeftMenu();
        leftMenu.movableMenu($('.BufferEditMenu'));
        if( $('#jumpTopBtn').length ){
            leftMenu.jumpToTop($('#jumpTopBtn'));
        }

        //コミットフォーム
        require(['editBufferCommitForm'], function(CommitForm){
            new CommitForm().init();
        });

        //見出しマップ
        if( $('#headlineBtn').length ){
            require(['editBufferHeadline'], function(Headline){
                new Headline().init();
            });
        }

        //プレビュー
        if( $('#previewBtn').length ){
            $('#previewBtn').on('click', function(){
                alert('SORRY! THIS FUNCTION IS UNDERCONSTRUCTION.');
            });
        }

        //差異表示
        if( $('#diffBtn').length ){
            $('#diffBtn').on('click', function(){
                alert('SORRY! THIS FUNCTION IS UNDERCONSTRUCTION.');
            });
        }

    }

    // 編集フォーム
    if( $('body > section.MdBuffer .BufferEdit').length ){
        require(['editBufferEditor', 'modalLoading'], function(EditBufferEditor, ModalLoading){
            var loading = new ModalLoading();
            loading.show($.proxy(function(){
                var editor = new EditBufferEditor();
                editor.init();
                if( $('#clearBtn').length ){
                    editor.setClearBtn($('#clearBtn'));
                }
                loading.remove();
            }, this));
        });
    }

    //バッファメッセージの管理
    if( $('section.Message').length ){
        require(['editBufferMessage'], function(BufferMessage){});
    }

    //未コミットメッセージ
/*  TODO: 未実装
    if( $('#uncommitAlert').length ){
        require(['mdBufferUncommitAlert'], function(UncommitAlert){
            new UncommitAlert().init();
        });
    }
*/
});

