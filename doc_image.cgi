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
$dog->setup_config($fid);
my $uid = $dog->login_user_document($fid);
$dog->check_auths($uid, $fid, "is_edit", "is_admin");

#画像アップロード処理
if ($dog->qParam('upload')) {
    $dog->upload_image($uid, $fid);
}

#画像削除処理
if ($dog->qParam('delete')) {
    $dog->delete_image($uid, $fid);
}

#コミット処理
if ($dog->qParam('commit')) {
    my $comment = $dog->qParam('comment');
    $dog->fix_md_buffer($uid, $fid, $comment);
}

#バッファリセット
if( $dog->qParam('resetBuffer') ){
    $dog->reset_buffer($uid, $fid);
}

my $images  = $dog->set_md_image($uid, $fid);
my $docinfo = $dog->set_document_info($uid, $fid);
my $is_live = $dog->set_buffer_info($uid, $fid);

$dog->print_page({
    'fid'     => $fid,
    'uid'     => $uid,
    'images'  => $images,
    'is_live' => $is_live,
    'docinfo' => $docinfo
});
exit();
