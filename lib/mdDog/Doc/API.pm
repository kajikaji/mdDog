package mdDog::Doc::API;

use strict; no strict "subs";
use parent mdDog::Doc;
use Text::Markdown::MdDog qw/markdown paragraph_html paragraph_raw alter_paragraph paragraphs/;
use JSON;

#
#
sub get_data {
    my ($self, $eid, $action) = @_;
    return unless($self->{userinfo});
    my $data;

    if ( $action eq 'image_list' ) {
        $self->{git}->attach_local_tmp($self->{userinfo}->{uid});
        my $imgdir = "$self->{repodir}/$self->{fid}/image";
        if ( -d $imgdir) {
            my @images = glob "$imgdir/*";
            $self->{git}->detach_local();

            foreach (@images) {
                my $path = $_;
                $path =~ s#$self->{repodir}/$self->{fid}/image/(.*)$#\1#g;
                push @$data, {filename => $path};
            }
        }
    } else {
        my $document = $self->_get_user_document($self->{userinfo}->{uid},
                                                 $self->{fid});
        if ( $eid >= 0) {
            my $raw = paragraph_raw($document, $eid);
            my $html = paragraph_html($document, $eid);
            $raw  =~ s#\(plugin/image_viewer\.cgi\?(.*)\)#(plugin/image_viewer.cgi?tmp=1&\1)#g;
            $html =~ s#\(plugin/image_viewer\.cgi\?(.*)\)#(plugin/image_viewer.cgi?tmp=1&\1)#g;
            $data = [{eid => ${eid}, raw => ${raw}, html => ${html}}];
        } else {
            my $cnt = 0;
            while ( my $ret = paragraph_raw($document, $cnt) ) {
                last if( $ret =~ m/^\n/ );
                $ret  =~ s#\(plugin/image_viewer\.cgi\?(.*)\)#(plugin/image_viewer.cgi?tmp=1&\1)#g;
                push @$data, { eid => ${cnt}, raw => ${ret} };
                $cnt++;
            }
        }
    }
    my $json = JSON->new();
    return $json->encode($data);
}


#
#
sub update_paragraph {
    my ($self, $eid, $data) = @_;
    return unless($self->{userinfo});
    $data .= "\n" if( $data !~ m/(.*)\n*$/);

    my $document = $self->_get_user_document($self->{userinfo}->{uid},
                                             $self->{fid});
    $document = alter_paragraph(length($document)>0?$document:"", $eid, $data);

    #ファイル書き込み
    my $filepath = "$self->{repodir}/$self->{fid}/$self->{filename}";
    $self->{git}->attach_local_tmp($self->{userinfo}->{uid}, 1);
    open my $hF, '>', $filepath || return undef;
    syswrite $hF, $document, length($document);
    close $hF;

    my $author = $self->_get_author($self->{userinfo}->{uid});
    $self->{git}->commit($self->{filename}, $author, "temp saved");
    $self->{git}->detach_local();

    my $mds;
    my $cnt = 0;
    my $raws = paragraphs($data);

    foreach ( @$raws ) {
        my $raw = $_;
        my $md = markdown($raw);
        $md =~ s#"plugin/image_viewer\.cgi\?(.*)"#"plugin/image_viewer.cgi?tmp=1&\1"#g;
        push @$mds, {md => $md, raw => $raw};
        $cnt++;
    }

    $self->{git}->attach_info($self->{userinfo}->{uid});
    $self->{outline}->init();
    $self->{outline}->slide_down_divide($eid, $cnt - 1);
    $self->{git}->commit_info($self->{outline}->{filename}, $author);
    $self->{git}->detach_local();

    my $json = JSON->new();
    return $json->encode($mds);
}

############################################################
#[API]
#
sub delete_paragraph {
    my ($self, $eid) = @_;
    return unless($self->{userinfo});
    my $document = $self->_get_user_document($self->{userinfo}->{uid},
                                             $self->{fid});

    $document = alter_paragraph($document, $eid, "");

    $self->{git}->attach_local_tmp($self->{userinfo}->{uid}, 1);

    #ファイル書き込み
    my $filepath = "$self->{repodir}/$self->{fid}/$self->{filename}";
    open my $hF, '>', $filepath || return undef;
    syswrite $hF, $document, length($document);
    close $hF;

    my $author = $self->_get_author($self->{s}->param('login'));
    $self->{git}->commit($self->{filename}, $author, "temp saved");
    $self->{git}->detach_local();

    $self->{git}->attach_info($self->{userinfo}->{uid});
    $self->{outline}->init();
    $self->{outline}->slide_up_divide($eid);
    $self->{git}->commit_info($self->{outline}->{filename}, $author);
    $self->{git}->detach_local();

    my $raw = paragraph_raw($self->_get_user_document(
        $self->{userinfo}->{uid}, $self->{fid}), $eid);

    my $json = JSON->new();
    return $json->encode({eid => ${eid}, raw => $raw });
}

# @summary アウトラインで改ページを加える
#
sub outline_add_divide {
    my ($self, $num) = @_;
    return unless($self->{userinfo});

    my $author = $self->_get_author($self->{s}->param('login'));
    my $comment = "INSERT DIVIDE";

    $self->{git}->attach_info($self->{userinfo}->{uid});
    $self->{outline}->init();
    $self->{outline}->insert_divide($num, $comment);
    $self->{git}->commit_info($self->{outline}->{filename}, $author);
    $self->{git}->detach_local();

    my $json = JSON->new();
    return $json->encode({action => 'divide',num => ${num}});
}

############################################################
#[API] アウトラインに設定された改ページを削除する
#
sub outline_remove_divide {
    my ($self, $num) = @_;
    return unless( $self->{userinfo} );

    my $author  = $self->_get_author($self->{userinfo}->{uid});
    my $comment = "REMOVE DIVIDE";

    $self->{git}->attach_info($self->{userinfo}->{uid});
    $self->{outline}->init();
    $self->{outline}->remove_divide($num);
    $self->{git}->commit_info($self->{outline}->{filename}, $author);
    $self->{git}->detach_local();

    my $json = JSON->new();
    return $json->encode({action => 'undivide',num => ${num}});
}

# @summary 指定のrevisionのJSONデータを返す
#
sub get_revisiondata {
    my ($self, $revision, $user) = @_;

    $self->_set_filename($self->{fid});
    my $filepath = "$self->{repodir}/$self->{fid}/$self->{filename}";
    my $document;
    $user = undef if($user == 0);

    my $gitctrl = $self->{git};

    my $user_root = $gitctrl->get_branch_latest($user);
    $revision = $user_root unless($revision);
    my $oneLog = $gitctrl->one_log($revision);

    $gitctrl->attach_local($user);
    $gitctrl->checkout_version($revision);

    open my $hF, '<', $filepath || die "failed to read ${filepath}";
    my $pos = 0;
    while (my $length = sysread $hF, $document, 1024, $pos) {
        $pos += $length;
    }
    close $hF;

    $gitctrl->detach_local();
    my $json = JSON->new();
    return $json->encode({
        name => $self->{filename},
        document => markdown($document),
        revision => $revision,
        commitDate => MYUTIL::format_date1($oneLog->{attr}->{date}),
        commitMessage => $oneLog->{message},
    });
}

############################################################
#[API] 指定のrevisionの差分を返す
#
sub get_diff {
    my ($self, $revision, $dist) = @_;
    $self->_set_filename($self->{fid});

    my $diff = $self->{git}->get_diff($self->{filename},
                                      $revision,
                                      $dist);

    my $json = JSON->new();
    return $json->encode({
        name     => $self->{filename},
        revision => $revision,
        dist     => $dist?$dist:'ひとつ前',
        diff     => $diff,
    });
}

#
#
sub rollback_buffer {
    my ($self, $revision) = @_;

    my $uid = $self->{userinfo}->{uid};
    my $gitctrl  = $self->{git};
    unless( $gitctrl->is_exist_user_branch($uid, 'tmp') ){
        $gitctrl->attach_local_tmp($uid, 'create tmp');
        $gitctrl->detach_local();
    }
    $gitctrl->attach_local($uid);
    $gitctrl->rollback_buffer($revision);
    $gitctrl->detach_local();

    my $json = JSON->new();
    return $json->encode({action => 'reset', revision => $revision});
}

#
#
sub edit_log {
    my ($self, $revision, $comment) = @_;
    return unless( $comment );

    my $uid = $self->{userinfo}->{uid};
    my $author   = $self->_get_author($uid);
    my $gitctrl = $self->{git};

    $gitctrl->attach_local($uid);
    $gitctrl->edit_commit_message($author, $comment);
    $gitctrl->detach_local();

    my $json = JSON->new();
    return $json->encode({fid => $self->{fid}, comment => $comment});
}

#
#
sub document_change_public {
    my ($self, $is_public) = @_;

    $self->{teng}->update('docx_infos' => {
        is_public => $is_public
    }, {
        id => $self->{fid}
    });
    $self->dbCommit();

    my $sth = $self->{dbh}->prepare(SQL::document_info);
    $sth->execute($self->{fid});
    my $info = $sth->fetchrow_hashref();

    my $json = JSON->new();
    return $json->encode($info);
}

############################################################
#[API]
#
sub document_user_add {
    my ($self, $users)  = @_;
    my $ar_insert;
    my $sql = SQL::user_info;
    $sql =~ s/ id = \?/ id IN (/;

    my $i = 0;
    foreach(@$users) {
      push @$ar_insert, {
          info_id    => $self->{fid},
          user_id    => $_,
          created_at => 'now()',
          created_by => $self->{userinfo}->{uid},
          updated_at => 'now()'
      };

      $sql .= "," if($i > 0);
      $sql .= $_;
      $i++;
    }
    $sql .= ')';

    $self->{teng}->bulk_insert('docx_auths', $ar_insert);
    $self->dbCommit();

    my $data = $self->{dbh}->selectall_arrayref($sql, +{Slice => {}})
      || die("DB Error+ document_user_add select");

    my $json = JSON->new();
    return $json->encode($data);
}

#
#
sub document_user_delete {
    my ($self, $users) = @_;
    return unless( @$users );

    my $sql_delete = << "SQL";
DELETE FROM docx_auths
WHERE
  info_id = $self->{fid}
  AND user_id in (
SQL

    my $sql = SQL::user_info;
    $sql =~ s/ id = \?/ id IN (/;

    my $i = 0;
    foreach(@$users) {
        $sql_delete .= ',' if( $i > 0 );
        $sql_delete .= $_;

        $sql .= ',' if( $i > 0);
        $sql .= $_;
        $i++;
    }
    $sql_delete .= ')';
    $sql        .= ')';

    $self->{dbh}->do($sql_delete)
      || die("DB Error: document_user_delete");
    $self->dbCommit();

    my $data = $self->{dbh}->selectall_arrayref($sql, +{Slice => {}})
      || die("DB Error+ document_user_add select");


    my $json = JSON->new();
    return $json->encode($data);
}

#
#
sub document_user_may_approve {
    my ($self, $user, $checked) = @_;

    $self->{teng}->update('docx_auths' => {
        may_approve => $checked
    }, {
        info_id => $self->{fid},
        user_id => $user
    });

    $self->dbCommit();

    my $sth = $self->{dbh}->prepare(SQL::auth_info);
    $sth->execute($self->{fid}, $user);
    my $info = $sth->fetchrow_hashref();

    my $json = JSON->new();
    return $json->encode($info);
}

#
#
sub document_user_may_edit {
    my ($self, $user, $checked) = @_;

    $self->{teng}->update('docx_auths' => {
        may_edit => $checked
    }, {
        info_id => $self->{fid},
        user_id => $user
    });
    $self->dbCommit();

    my $sth = $self->{dbh}->prepare(SQL::auth_info);
    $sth->execute($self->{fid}, $user);
    my $info = $sth->fetchrow_hashref();

    my $json = JSON->new();
    return $json->encode($info);
}

############################################################
#[API]
sub restruct_document {
    my ($self, $doc) = @_;
    return unless( $self->{userinfo} );

    my $uid = $self->{userinfo}->{uid};
    my $gitctrl = $self->{git};
    my $oldlogs = $gitctrl->get_user_logs($uid);
    my $log;
    foreach(@$oldlogs){
      $log .= $_->format_datetime . ": " . $_->{message};
      $log .= "====\n";
    }

    $gitctrl->attach_local($uid, 1);

    $self->_set_filename($self->{fid});
    my $filepath = "$self->{repodir}/$self->{fid}/$self->{filename}";
    open my $hF, '>', $filepath || return undef;
    syswrite $hF, $doc, length($doc);
    close $hF;

    my $author = $self->_get_author($uid);
    $self->{git}->commit($self->{filename}, $author, $log);

    $gitctrl->detach_local();

    my $json = JSON->new();
    return $json->encode({fid => $self->{fid}, uid => $uid, log => $log});
}

#
#
sub clear_user_buffer {
    my $self = shift;
    return unless( $self->{userinfo} );

    my $uid = $self->{userinfo}->{uid};
    my $gitctrl = $self->{git};

    return unless( $gitctrl->clear_tmp($uid) );

    my $document = $self->_get_user_document($uid, $self->{fid});
    my $md       = markdown($document);
    $md =~ s#"plugin/image_viewer\.cgi\?(.*)"#"plugin/image_viewer.cgi?tmp=1&$1" #g;
    my $rows     = paragraphs($document);

    my $json = JSON->new();
    return $json->encode({md => $md, rows => $rows});
}

#
#
sub get_doc_groups {
    my ($self) = @_;

    my $sql = SQL::doc_group_list;
    $sql   .= s/\?/$self->{fid}/;
    my $ar = $self->{dbh}->selectall_arrayref($sql, +{Slice =>{}})
      || die("SQL Error: in 'get_doc_groups'");
    my $json = JSON->new();
    return $json->encode($ar);
}

#
#
sub search_groups{
    my ($self, $search) = @_;
    return unless( $search );

    my $sql = SQL::group_list;
    $sql   .= "WHERE title like '%${search}%'";

    my $ary = $self->{dbh}->selectall_arrayref($sql, +{Slice =>{}});
    $ary = "[]" unless( $ary );
    my $json = JSON->new();
    return $json->encode($ary);
}

#--------------------------------------------------
#
#--------------------------------------------------
sub add_groups {
    my ($self, $groups) = @_;
    return unless( $groups );
    my $g_type   = 1;

    #グループの登録
    for (@$groups) {
        my $groupname = $_;
        my $sql_check = SQL::group_list;
        $sql_check   .= " WHERE title = '${groupname}'";
        if( $self->{dbh}->selectrow_arrayref($sql_check) ){
            next;
        }

        $self->{teng}->insert('mddog_groups' => {
            title      => $groupname,
            type       => $g_type,
            created_by => $self->{userinfo}->{uid},
            created_at => 'now()',
            updated_at => 'now()'
        });
    }

    #ドキュメントのグループ設定付け（一旦消してから再登録）
    $self->{teng}->delete('mddog_doc_group', {
        doc_id => $self->{fid}
    });

    if( @$groups ){
        my $values = "";
        for( @$groups ){
            $values .= ',' if ( $values =~ m/^\(.*\).*/ );
            $values .= "($self->{fid}, (select id from mddog_groups where title = '$_'))";
        }

        my $sql_groupadd = << "SQL";
INSERT INTO mddog_doc_group(doc_id, group_id) VALUES ${values}
SQL
        $self->{dbh}->do($sql_groupadd);
    }

    # 不使用のグループは削除
    my $sql_clean = << "SQL";
DELETE FROM mddog_groups
WHERE id not in (
  SELECT group_id FROM mddog_doc_group GROUP BY group_id
)
SQL
    $self->{dbh}->do($sql_clean);

    $self->{dbh}->commit();

    my $length = @$groups;
    my $json = JSON->new();
    return $json->encode($groups);
}


1;
