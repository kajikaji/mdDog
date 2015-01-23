'use strict'
requirejs.config({
    baseUrl: 'js/modules',
    urlArgs: 'rev=20150123e',
    paths: {
        jquery:          'jquery-1.11.1.min',
        mddog:           'mddog',
        UTIL:            'UTIL',
        mdOutline:       'mdOutline',
        mdBufferEditor:  'mdBufferEditor',
        mdEditForm:      'mdEditForm',
        mdOutlineDivide: 'mdOutlineDivide',
        mdOutlnieEditor: 'mdOutlineEditor',
        mdCommitBuffer:  'mdCommitBuffer',
        logTableChanger: 'logTableChanger',
        diffViewer:      'diffViewer',
        revisionViewer:  'revisionViewer'
    },
    shim: {
        'mddog': {
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
        'logTableChanger': {
            deps: ['jquery']
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
    if($('body > section.MdBuffer .BufferEdit').length){
        require(['mdBufferEditor'], function(BufferEditor){
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
    //コミットフォーム
    if($('.BufferEditMenu').length){
        require(['mdCommitBuffer'], function(CommitBuffer){});
    }

    //履歴テーブルにビューアーの埋め込み
    if(!$('body > section.Outline').length && $('table.Gitlog').length){
        require(['diffViewer'], function(DiffViewer){
            new DiffViewer().init();
        });
        require(['revisionViewer'], function(RevisionViewer){
            new RevisionViewer().init();
        });
    }
});

