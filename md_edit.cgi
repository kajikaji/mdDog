#!/usr/bin/perl

use strict; no strict "refs";
use lib './lib/';
use mdDog;

my $dog =mdDog->new();
$dog->setupConfig();
$dog->login();

if(!$dog->qParam('fid')) {
  $dog->{t}->{error} = "mdドキュメントが指定されていません<br>md_edit.cgi:err01<br>";
} else {
  if($dog->qParam('update')){
    #一時保存
    $dog->updateMD_buffer();
  }elsif($dog->qParam('commit')){
    #変更を反映 変更履歴は必須
    #Todo: ユーザーリポジトリに反映してmd_view.cgiにリダイレクト
    if($dog->fixMD_buffer()){
	print "Location: md_view.cgi?fid=" . $dog->qParam('fid') . "\n\n";
	exit();
    }
  }

  if($dog->qParam('style') eq "preview"){
    $dog->setMD_buffer(1);
  }else{
    $dog->setMD_buffer();
  }
  $dog->setDocumentInfo();
}

$dog->printPage();
exit();
