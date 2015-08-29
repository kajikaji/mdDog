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
#
# 画像をバイナリ出力する

use strict; no strict "refs";
use lib '../lib', '../src';
use mdDog;
use MYUTIL;

my $dog = mdDog->new('/plugin');
my $fid = $dog->qParam('fid');
return unless($fid);
$dog->setup_config($fid);
my $uid = $dog->login();

my $image     = $dog->qParam('image');
my $thumbnail = $dog->qParam('thumbnail');
my $tmp       = $dog->qParam('tmp');
my $size      = $dog->qParam('size'); # 0 - 100
my $master    = $dog->qParam('master');
 
$dog->print_image($uid, $fid, $image, $thumbnail, $tmp, $size);

exit();
