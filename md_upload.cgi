#!/usr/bin/perl

use strict; no strict "refs";
use lib './lib/';
use mdDog;

my $dog =mdDog->new();
$dog->setupConfig();
$dog->login();


if(!$dog->qParam('fid')) {
    $dog->{t}->{error} = "mdドキュメントが指定されていません<br>md_upload.cgi:err01<br>";
} else {
    if($dog->qParam('uploadfile')){
        if($dog->uploadFile()){
            $dog->{t}->{message} = { "info" => "アップロードしたファイルで上書きしました" };
        }else{
            $dog->{t}->{message} = { "error" => "アップロードに失敗しました" };
        }
    }

    if($dog->qParam('commit')){
        #変更を反映 変更履歴は必須
        if($dog->fixMD_buffer()){
            $dog->{t}->{message} = { "info" => "コミットしました" };
        }else{
            $dog->{t}->{message} = { "error" => "編集バッファのコミットに失敗しました" };
        }
    }

    $dog->setDocumentInfo();
}

$dog->printPage();
exit();
