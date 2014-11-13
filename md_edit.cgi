#!/usr/bin/perl

use strict; no strict "refs";
use lib './lib/';
use DocxLog;

my $docxlog =DocxLog->new();
$docxlog->setupConfig();
$docxlog->login();

if(!$docxlog->qParam('fid')) {
  $docxlog->{t}->{error} = "mdドキュメントが指定されていません<br>md_edit.cgi:err01<br>";
} else {
  if($docxlog->qParam('update')){
    #一時保存
    $docxlog->updateMD_buffer();
  }elsif($docxlog->qParam('commit')){
    #変更を反映 変更履歴は必須
    #Todo: ユーザーリポジトリに反映してmd_view.cgiにリダイレクト
    if($docxlog->fixMD_buffer()){
	print "Location: md_view.cgi?fid=" . $docxlog->qParam('fid') . "\n\n";
	exit();
    }
  }

  if($docxlog->qParam('style') eq "preview"){
    $docxlog->setMD_buffer(1);
  }else{
    $docxlog->setMD_buffer();
  }
  $docxlog->setDocumentInfo();
}

$docxlog->printPage();
exit();
