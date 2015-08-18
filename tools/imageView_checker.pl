#!/usr/bin/env perl
#
# md_imageViewer.cgiからplugin/image_viewer.cgiの名前変更にworkディレクトリを適用させるスクリプト
# 2015/08/17 by gm2bv
#

use strict;
use lib '../lib/';
use Git::Wrapper;
use MYUTIL;

my $dir = "../work";
my $msg = "#SYSTEM UPDATE#";
my $author = "gm2bv <gm2bv2001\@gmail.com>";
my $outline = 'outline.dat';

opendir(my $h, $dir);
foreach( readdir($h) ){
    next if /^\.{1,2}$/;

    my $repo = "${dir}/$_";
    next unless(isGitRepo($repo));

    print "$_\n";

    my $git = Git::Wrapper->new($repo);
    my @branches = $git->branch;
    foreach (@branches){
        print "    $_\n";

        my $br = $_;
        $br =~ s/^[\s\*]*(.*)\s*$/$1/;

        my $flgConvert = 0;
        my $flgMerge = 0;
        if( $br =~ m/^master$/ || $br =~ m/^user_\d$/ ) {
            $flgConvert = 1;
            $flgMerge = 1;
        }
        elsif( $br =~ m/^user_\d_tmp$/ ) {
            $flgConvert = 1;
        }

        if( $flgConvert ){
            $git->checkout($br);
            my $md = getMD("${repo}");
            open FI, "${repo}/${md}";
            my @data = <FI>;
            close FI;
            open FO, "> ${repo}/${md}";
            for(@data){
                $_ =~ s#md_imageView\.cgi\?#plugin/image_viewer\.cgi\?#g;
                print FO $_;
            }
            close FO;
            if( $git->diff() ){
                $git->add($md);
                $git->commit({message=>$msg, author => $author});

                if ( $flgMerge ) {
                    if ( MYUTIL::is_include(\@branches, "${br}_info") ) {
                        $git->checkout("${br}_info");
                        $git->rebase($br);
                    }
                }

            }
            $git->checkout("master");
        }
    }
}
closedir($h);


sub isGitRepo {
    my $dir = shift;

    my $flg = 0;
    opendir(my $rh, $dir);
    foreach( readdir($rh) ){
        next if /^\.{1,2}$/;
        if( $_ =~ m/\.git/ ){
            $flg = 1;
            last;
        }
    }
    closedir($rh);

    return $flg;
}

sub getMD {
    my $dir = shift;
    my $ret;

    opendir(my $h, $dir);
    foreach( readdir($h) ){
        next if /^\.{1,2}$/;

        if( $_ =~ m/.*\.md/ ){
            $ret = $_;
            last;
        }
    }
    closedir($h);

    return $ret;
}

exit;
