package mdDog::Doc::Approve;

use strict; no strict "subs";
use parent mdDog::Doc;

# @summary ドキュメントのログを取得(承認者用)
#
sub set_user_log {
    my ($self, $uid, $fid) = @_;

    my @userary;
    my $gitctrl    = $self->{git};
    my $latest_rev = undef;
    my $doclogs    = $gitctrl->get_shared_logs('raw');
    $latest_rev    = $doclogs->[0]->{rev} if( @$doclogs );

    foreach ( $gitctrl->get_other_users() ) {
        my $userlog = {
            uid       => $_,
            name      => $self->_get_nic_name($_),
            loglist   => $gitctrl->get_user_logs($_),
        };

        my $userRoot = $gitctrl->get_branch_root($_);
        if ( $latest_rev =~ m/${userRoot}[0-9a-z]+/
             && (@{$userlog->{loglist}}) ) {
            $userlog->{is_live} = 1;
            push @userary, $userlog;
        }
    }
    return \@userary;
}

# @summary 承認するために指定したリヴィジョンまでの履歴を取得してテンプレートにセット
#
sub set_approve_list {
    my ($self, $uid, $fid, $user, $revision) = @_;
    return unless($uid && $fid && $revision && $user); # NULL CHECK

    my $branch = "$self->{repo_prefix}${user}";
    my @logs;
    my $flg    = undef;
    my $branches = $self->{git}->get_user_logs($user);
    for( @$branches ) {
        my $obj = eval {($_)};
        if( $flg || (!$flg && $obj->{rev} eq ${revision}) ) {
            push @logs, $obj;
            $flg = 1 unless($flg);
        }
    }

    return \@logs;
#    $self->{t}->{loglist}     = \@logs;
#    $self->{t}->{approve_pre} = 1;
}

# @summary 指定のユーザーの指定のリヴィジョンを承認して共有化
#
sub doc_approve {
    my ($self, $uid, $fid, $user, $revision) = @_;
    return unless($uid && $fid && $revision && $user); # NULL CHECK

    $self->{git}->approve($user, $revision);
}


1;
