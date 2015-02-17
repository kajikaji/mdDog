'use strict'
requirejs.config({
    baseUrl: 'js/modules',
    urlArgs: 'rev=20150125b',
    paths: {
        jquery          :'jquery-1.11.1.min',
        mddog           :'mddog',
        UTIL            :'UTIL',
        mdOutline       :'mdOutline',
        mdBufferEditor  :'mdBufferEditor',
        mdEditForm      :'mdEditForm',
        mdOutlineDivide :'mdOutlineDivide',
        mdOutlnieEditor :'mdOutlineEditor',
        mdCommitBuffer  :'mdCommitBuffer',
        bufferMessage   :'bufferMessage',
        logTableChanger :'logTableChanger',
        diffViewer      :'diffViewer',
        revisionViewer  :'revisionViewer',
        rollbackBuffer  :'rollbackBuffer',
        editLogComment  :'editLogComment',
        addAccountForm  :'addAccountForm',
        userManager     :'userManager',
        bufferEditor    :'bufferEditor'
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
        'mdBufferEditor': {
            deps: ['jquery', 'UTIL', 'mdEditForm', 'mdOutlineDivide']
        },
        'mdOutlineEditor':{
            deps: ['jquery', 'UTIL']
        },
        'mdCommitbuffer': {
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
        'bufferEditor' : {
	        deps: ['jquery', 'UTIL']
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
    if( $('.BufferEditMenu').length ){
        require(['bufferEditor'], function(BufferEditor){
            new BufferEditor().init();
        });
    }

    //編集バッファ
    if($('body > section.MdBuffer .BufferEdit').length){
        require(['mdBufferEditor'], function(MdBufferEditor){
            new MdBufferEditor().init();
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

    //コミットフォーム
    if($('.BufferEditMenu').length){
        require(['mdCommitBuffer'], function(CommitBuffer){});
    }

    //バッファメッセージの管理
    if( $('section.Message').length ){
        require(['bufferMessage'], function(BufferMessage){});
    }
});

