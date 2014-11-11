#!/usr/bin/perl

use strict; no strict "refs";
use lib './lib/';
use DocxLog;
use Data::Dumper;

my $docxlog =DocxLog->new();
$docxlog->setupConfig();
$docxlog->login();

if(!$docxlog->qParam('fid')) {
  $docxlog->{t}->{error} = "違法なアクセスです";
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
  $docxlog->setMD_buffer();
  $docxlog->setDocumentInfo();
}

$docxlog->printPage();
exit();
