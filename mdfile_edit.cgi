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
    $docxlog->updateMDdocument_buffer();
  }elsif($docxlog->qParam('commit')){
    #変更を反映 変更履歴は必須
    #Todo: ユーザーリポジトリに反映してmdfile_view.cgiにリダイレクト
    if($docxlog->fixMDdocument_buffer()){
	print "Location: mdfile_view.cgi?fid=" . $docxlog->qParam('fid') . "\n\n";
	exit();
    }
  }
  $docxlog->setMDdocument_buffer();
  $docxlog->setupFileinfo();
}

$docxlog->printPage();
exit();
