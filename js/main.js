'use strict'
requirejs.config({
//    baseUrl: 'js/module',
    urlArgs: 'rev=20150425',
    packages : ["modules/tableLog", "edit_buffer", "doc_setting"],
    paths: {
        jquery          :'modules/jquery-1.11.1.min',
        UTIL            :'modules/UTIL',
        mdOutline       :'modules/mdOutline',
        mdEditForm      :'modules/mdEditForm',
        mdOutlineDivide :'modules/mdOutlineDivide',
        logTableChanger :'modules/logTableChanger',
        addAccountForm  :'modules/addAccountForm',
        userManager     :'modules/userManager',
        leftMenu        :'modules/leftMenu',
        outlineViewer   :'modules/outlineViewer'
    },
    shim: {
        'mdOutline': {
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
        'outlineViewer' : {
	        deps: [
                'jquery',
                'leftMenu'
            ]
        }
    }
});

//jQuery読込みと実行
requirejs(['jquery'], function($){

    //編集バッファ
    if( $('section.MdBuffer .BufferEdit.Markdown').length ){
        require(['edit_buffer'], function(Buffer){});
    }

    //アウトライン出力
    if($('body > section.Outline').length){
        require(['mdOutline'], function(Outline){
            new Outline().init();
        });
        require(['outlineViewer'], function(OutlineViewer){
            new OutlineViewer().init();
        });
    }

    //承認ページの履歴テーブル制御
    if($('body > section.DocApprove').length){
        require(['logTableChanger'], function(changer){});
    }
    //履歴テーブルにビューアーの埋め込み
    if( !$('body > section.Outline').length
         && $('table.Gitlog').length ){
        require(['tableLog'], function(tableLog){});
    }

    //管理ページ　アカウント管理
    if($('.AddAccountForm').length){
        require(['addAccountForm'], function(AddAccountForm){});
    }

    //ドキュメント設定ページ　ユーザー管理
    if($('.DocSetting').length){
//        require(['userManager'], function(UserManager){});
        require(['doc_setting'], function(docSetting){});
    }

});

