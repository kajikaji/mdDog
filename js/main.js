'use strict'
requirejs.config({
    baseUrl: 'js/modules',
    urlArgs: 'rev=20150125b',
    paths: {
        jquery          :'jquery-1.11.1.min',
        mddog           :'mddog',
        UTIL            :'UTIL',
        mdOutline       :'mdOutline',
        mdEditForm      :'mdEditForm',
        mdOutlineDivide :'mdOutlineDivide',
        mdOutlnieEditor :'mdOutlineEditor',
        bufferMessage   :'bufferMessage',
        logTableChanger :'logTableChanger',
        diffViewer      :'diffViewer',
        revisionViewer  :'revisionViewer',
        rollbackBuffer  :'rollbackBuffer',
        editLogComment  :'editLogComment',
        addAccountForm  :'addAccountForm',
        userManager     :'userManager',
        bufferEditor    :'bufferEditor',
        mdBufferCommitForm  :'mdBuffer/commitForm',
        mdBufferEditor      :'mdBuffer/editor',
        mdBufferFormCtrl    :'mdBuffer/formCtrl',
        mdBufferDivideCtrl  :'mdBuffer/divideCtrl'
    },
    shim: {
        'mddog': {
            deps: ['jquery']
        },
	    'bufferMessage': {
            deps: ['jquery']
	    },
        'mdOutline': {
            deps: ['jquery']
        },
        'mdOutlineEditor':{
            deps: ['jquery', 'UTIL']
        },
        'diffViewer': {
            deps: ['jquery']
        },
        'revisionViewer': {
            deps: ['jquery']
        },
	    'rollbackBuffer': {
	        deps: ['jquery']
	    },
	    'editLogComment': {
	        deps: ['jquery']
	    },
        'logTableChanger': {
            deps: ['jquery']
        },
	    'addAccountForm': {
	        deps: ['jquery']
	    },
        'userManager' : {
	        deps: ['jquery', 'UTIL']
	    },
        'bufferEditor' : {
	        deps: [
                'jquery',
                'UTIL',
                'mdBufferCommitForm',
                'mdBufferEditor',
                'mdBufferFormCtrl',
                'mdBufferDivideCtrl'
            ]
        }
    }
});

//jQuery読込みと実行
requirejs(['jquery'], function($){

    //アウトライン出力
    if($('body > section.Outline').length){
        require(['mdOutline'], function(Outline){
            new Outline().init();
        });
    }

    //編集バッファ
    if( $('section.MdBuffer .BufferEdit.Markdown').length ){
        require(['bufferEditor'], function(BufferEditor){
            new BufferEditor().init();
        });
    }

    //アウトラインエディタ
    if($('body > section.OutlineEditor .BufferEdit').length){
        require(['mdOutlineEditor'], function(OutlineEditor){
            new OutlineEditor().init();
        });
    }
    //承認ページの履歴テーブル制御
    if($('body > section.DocApprove').length){
        require(['logTableChanger'], function(changer){});
    }
    //履歴テーブルにビューアーの埋め込み
    if( !$('body > section.Outline').length
         && $('table.Gitlog').length ){
        require(['diffViewer'], function(DiffViewer){
            new DiffViewer().init();
        });
        require(['revisionViewer'], function(RevisionViewer){
            new RevisionViewer().init();
        });
        require(['rollbackBuffer'], function(RollbackBuffer){
            new RollbackBuffer().init();
        });
        require(['editLogComment'], function(EditLogComment){
            new EditLogComment().init();
        });
    }

    //管理ページ　アカウント管理
    if($('.AddAccountForm').length){
        require(['addAccountForm'], function(AddAccountForm){});
    }

    //ドキュメント設定ページ　ユーザー管理
    if($('.DocSetting').length){
        require(['userManager'], function(UserManager){});
    }

    //バッファメッセージの管理
    if( $('section.Message').length ){
        require(['bufferMessage'], function(BufferMessage){});
    }
});

