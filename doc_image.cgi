#!/usr/bin/perl

# --------------------------------------------------------------------
# @Author Yoshiaki Hori
# @copyright 2014 Yoshiaki Hori gm2bv2001@gmail.com
#
# This file is part of mdDog.
#
# mdDog is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# mdDog is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
# --------------------------------------------------------------------

use strict; no strict "refs";
use lib './lib', './src';
use mdDog::Doc::Image;

my $dog = mdDog::Doc::Image->new();
my $fid = $dog->qParam('fid');
unless( $fid ){
    print "Location: index.cgi\n\n";
    exit;
}
$dog->init($fid);
unless( $dog->login ){
    print "Location: doc_history.cgi?fid=${fid}\n\n";
    exit;
}

$dog->check_auths("is_edit", "is_admin");

#画像アップロード処理
if ($dog->qParam('upload')) {
    $dog->upload_image;
}

#画像削除処理
if ($dog->qParam('delete')) {
    my @selected = $dog->qParam('select_image');
    $dog->delete_image(\@selected);
}

#コミット処理
if ($dog->qParam('commit')) {
    my $comment = $dog->qParam('comment');
    $dog->fix_md_buffer($comment);
}

#バッファリセット
if( $dog->qParam('resetBuffer') ){
    $dog->reset_buffer;
}

my $images  = $dog->set_md_image;
my $docinfo = $dog->set_document_info;
my $is_live = $dog->set_buffer_info;

$dog->print_page({
    'fid'     => $fid,
    'images'  => $images,
    'is_live' => $is_live,
    'docinfo' => $docinfo
});
exit();
