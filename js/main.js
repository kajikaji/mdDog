'use strict'
requirejs.config({
    baseUrl: 'js/modules',
    paths: {
        jquery:          'jquery-1.11.1.min',
        mddog:           'mddog',
        UTIL:            'UTIL',
        mdOutline:       'mdOutline',
        mdEditForm:      'mdEditForm',
        mdOutlineDivide: 'mdOutlineDivide',
        mdBufferEditor:  'mdBufferEditor',
        mdOutlnieEditor: 'mdOutlineEditor',
        mdApprove:       'mdApprove',
        mdCommitBuffer:  'mdCommitBuffer'
    },
    shim: {
        'mddog': {
            deps: ['jquery']
        },
        'UTIL': {
            deps: ['jquery']
        },
        'mdOutline': {
            deps: ['jquery']
        },
        'mdEditForm': {
            deps: ['jquery', 'mddog']
        },
        'mdOutlineDivide': {
            deps: ['jquery']
        },
        'mdBufferEditor': {
            deps: ['jquery', 'UTIL', 'mdEditForm', 'mdOutlineDivide']
        },
        'mdOutlineEditor':{
            deps: ['jquery', 'UTIL']
        },
        'mdApprove': {
            deps: ['jquery']
        },
        'mdCommitbuffer': {
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
        require(['mdApprove'], function(Approve){});
    }
    //コミットフォーム
    if($('.BufferEditMenu').length){
        require(['mdCommitBuffer'], function(CommitBuffer){});
    }
});

