#!/usr/bin/perl
#
# author: gm2bv
# date: 2015/1/14
#

use strict; no strict "refs";
use lib './lib/';
use mdDog;

my $dog =mdDog->new();
$dog->setup_config();
$dog->login();

if(!$dog->qParam('fid')) {
    $dog->{t}->{error} = "mdドキュメントが指定されていません<br>md_edit.cgi:err01<br>";
} else {
    if($dog->qParam('upload')){
        if($dog->upload_image()){
            $dog->{t}->{message} = { "info" => "画像をアップロードしました"};
        }else{
            $dog->{t}->{message} = { "error" => "画像のアップロードに失敗しました"};
        }
    }
 
    if($dog->qParam('delete')){
        if($dog->delete_image()){
            $dog->{t}->{message} = { "info" => "画像を削除しました"};
        }else{
            $dog->{t}->{message} = { "error" => "画像の削除に失敗しました"};
        }
    }

    if($dog->qParam('commit')){
        #変更を反映 変更履歴は必須
        if($dog->fix_md_buffer()){
            $dog->{t}->{message} = { "info" => "コミットしました" };
        }else{
            $dog->{t}->{message} = { "error" => "編集バッファのコミットに失敗しました" };
        }
    }

    if($dog->is_exist_buffer()){
	$dog->{t}->{message} = { "info" => "コミットされていないバッファがあります" };
    }

    $dog->set_md_image();
    $dog->set_document_info();
}

$dog->print_page();
exit();
