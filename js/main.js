'use strict'
requirejs.config({
//    baseUrl: 'js/module',
    urlArgs: 'rev=20150425',
    packages : ["modules/tableLog", "edit_buffer", "doc_setting", "doc_group"],
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
        outlineViewer   :'modules/outlineViewer',
        popupHelper     :'modules/popupHelper',
        searchGroup     :'modules/searchGroup',
        modalLoading    :'modules/modalLoading',
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
        },
        'popupHelper' : {
            deps: [
                'jquery'
            ]
        },
        'searchGroup' : {
            deps: [ 'jquery', 'UTIL' ]
        },
    }
});

//jQuery読込みと実行
requirejs(['jquery', 'popupHelper', 'UTIL'], function($, Popup){

    //編集バッファ
    if( $('section.MdBuffer .BufferEdit.Markdown').length 
        || $('section.BufferMerge').length ){
        require(['edit_buffer'], function(Buffer){});
    }

    //アウトライン出力
    if($('body > section.Outline').length){
        require(['mdOutline', 'outlineViewer', 'modalLoading'],
                function(Outline, OutlineViewer, ModalLoading){
            var loading = new ModalLoading();
            loading.show($.proxy(function(){
                new Outline().init();
                new OutlineViewer().init();
                loading.remove();
            }, this));
        });
    }

    //承認ページの履歴テーブル制御
    if($('body > section.DocApprove').length){
        require(['logTableChanger'], function(changer){});
    }
    //履歴テーブルにビューアーの埋め込み
    if( !$('body > section.Outline').length
         && $('table.Gitlog').length ){
        require(['modules/tableLog'], function(tableLog){});
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

    //ポップアップ
    if( $('.PopupHelper').length ){
        new Popup($(this)).init();
    };

    //ドキュメントグループ
    if( $('.GroupAddCtrl').length ){
        require(['doc_group'], function(docGroup){});
    }

    if ( $('#groupSelect').length ){
        require(['searchGroup'], function(SearchGroup){
            new SearchGroup($('#groupSelect')).init();
        });
    }
});

