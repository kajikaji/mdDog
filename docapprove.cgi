#!/usr/bin/perl
#
# author: gm2bv
# date: 2015/1/14
#

use strict; no strict "refs";
use lib './lib/';
use mdDog;
use Data::Dumper;

my $dog =mdDog->new();
$dog->setup_config();
$dog->login();

if(!$dog->qParam('fid')) {
  $dog->{t}->{error} = "ドキュメントが指定されずにアクセスされました<br>docinfo.cgi<br>Err001";
} else {
  #正常系の処理
  if($dog->qParam('approve')){
    $dog->doc_approve();
  }elsif($dog->qParam('approve_pre')){ # 確認
    $dog->set_approve_list();
  }

  $dog->git_log('all');
  $dog->set_document_info();
}

$dog->print_page();
exit();
