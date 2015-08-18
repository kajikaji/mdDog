#!/usr/bin/env perl
#
# outlineの仕様変更にworkディレクトリを適用させるスクリプト
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
        my $br = $_;
        $br =~ s/^[\s\*]*(.*)\s*$/$1/;

        print "    $br\n";

        $git->checkout($br);
        my $flgInfo = 0;
        my $flgDel = 0;
        if( ($br =~ m/^master$/ || $br =~ m/^user_\d$/) 
            && -e "${repo}/${outline}" ){
            $flgInfo = 1;
            $flgDel = 1;
        }
        elsif( $br =~ m/^user_\d_tmp$/ && -e "${repo}/${outline}" ){
            $flgDel = 1;
        }

        if( $flgInfo ){
#            $git->checkout($br);
            unless( MYUTIL::is_include(\@branches, "${br}_info") ){
                print "      + make info-repo !!!\n";
                $git->checkout({b => "${br}_info"});
            }
        }
        if( $flgDel ){
            print "      + delete outline!!!\n";
#            $git->checkout($br);
            unlink("${repo}/${outline}");
            my $statuses = $git->status({s=>1});
            my @changes =  $statuses->get('changed');
            foreach( @changes ){
                if( $_->from =~ m/${outline}/ ){
                    $git->rm("${outline}");
                    $git->commit({message => $msg, author => $author});
#                    $git->checkout("master");
                    last;
                }
            }
        }
        $git->checkout("master");
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

exit;
