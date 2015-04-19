'use strict'
requirejs.config({
    baseUrl: 'js/modules',
    urlArgs: 'rev=201504010',
    paths: {
        jquery          :'jquery-1.11.1.min',
        mddog           :'mddog',
        UTIL            :'UTIL',
        mdOutline       :'mdOutline',
        mdEditForm      :'mdEditForm',
        mdOutlineDivide :'mdOutlineDivide',
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
        mdBufferHeadline    :'mdBuffer/headline',
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
        'mdBufferCommitForm' : {
	        deps: ['jquery', 'UTIL']
        },
        'mdBufferHeadline' : {
	        deps: ['jquery', 'UTIL']
        },
        'mdBufferFormCtrl' : {
            deps: [
                'jquery',
                'UTIL',
                'mdBufferDivideCtrl'
            ]
        },
        'bufferEditor' : {
	        deps: [
                'jquery',
                'UTIL',
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

    if( $('section.MdBuffer .BufferEditMenu').length ){
        require(['mdBufferCommitForm'], function(CommitForm){
            new CommitForm().init();
        });
    }

    //未コミットメッセージ
    if( $('#uncommitAlert').length ){
        require(['mdBufferUncommitAlert'], function(UncommitAlert){
            new UncommitAlert().init();
        });
    }

    //見出しマップ
    if( $('#headlineBtn').length ){
        require(['mdBufferHeadline'], function(Headline){
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

    //トップにスクロール
    if( $('#jumpTopBtn').length ){
        $('#jumpTopBtn').on('click', function(){
            $('html, body').animate({scrollTop: 0}, 'fast');
        });
    }

    //編集バッファ
    if( $('section.MdBuffer .BufferEdit.Markdown').length ){
        require(['bufferEditor'], function(BufferEditor){
            new BufferEditor().init();
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

