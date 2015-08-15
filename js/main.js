'use strict'
requirejs.config({
//    baseUrl: 'js/module',
    urlArgs: 'rev=20150816',
    packages : [
        "modules/tableLog",
        "index",
        "doc_editor",
        "doc_setting",
        "doc_outline"
    ],
    paths: {
        jquery          :'modules/jquery-1.11.1.min',
        UTIL            :'modules/UTIL',
        logTableChanger :'doc_approve/logTableChanger',
        addAccountForm  :'admin/addAccountForm',
        leftMenu        :'modules/leftMenu',
        popupHelper     :'modules/popupHelper',
        modalLoading    :'modules/modalLoading',
        docMerge        :'doc_merge/merge'
    },
    shim: {
    }
});

//jQuery読込みと実行
requirejs(['jquery', 'popupHelper', 'UTIL'], function($, Popup){
    //ドキュメント一覧(グループ編集UI)
    if( $('body > section.Top').length ){
        require(['index'], function(){});
    }

    //編集バッファ
    if( $('body > section.MdBuffer .BufferEdit.Markdown').length ){
        require(['doc_editor'], function(Buffer){});
    }

    //バッファマージ
    if( $('body > section.BufferMerge').length ){
        require(['docMerge'], function(Merge){
            new Merge(getParam('fid')).init();
        });
    }

    //アウトライン出力
    if($('body > section.Outline').length){
        require(['doc_outline'], function(Outline){});
    }

    //承認ページの履歴テーブル制御
    if($('body > section.DocApprove').length){
        require(['logTableChanger'], function(changer){});
    }
    //履歴テーブルにビューアーの埋め込み
    if( $('body > section.DocApprove table.Gitlog').length
        || $('body > section.Gitlog table.Gitlog').length
        || $('body > section.BufferLog table.Gitlog').length ){
        require(['modules/tableLog'], function(tableLog){});
    }

    //管理ページ　アカウント管理
    if($('.AddAccountForm').length){
        require(['addAccountForm'], function(AddAccountForm){});
    }

    //ドキュメント設定ページ　ユーザー管理
    if($('.DocSetting').length){
        require(['doc_setting'], function(docSetting){});
    }

    //ポップアップ
    if( $('.PopupHelper').length ){
        new Popup($(this)).init();
    };
});

