package APPBASE;

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

use strict;
use CGI;
use CGI::Cookie;
use CGI::Session;
use Template;
use DBI;
use Teng::Schema::Loader;
use constant TRUE => 1;
use constant FALSE => 0;

use SCONFIG;
use MYUTIL;

sub new {
    my $pkg = shift;
    my $dir = shift;

    my $relative = "";
    if( defined($dir) ){
        $dir =~ s/^\/(.*)$/$1/;
        foreach(split(/\//, $dir)){
            $relative .= "../";
        }
    }

    my $hash = {
        q           => new CGI,
        s           => undef,      #CGI::Session
        cookie      => undef,
        cginame     => undef,
        basename    => undef,
        sessiondir  => "${relative}sess/",
        templatedir => "${relative}tmpl/",
        relative    => $relative,
        tmplfile    => undef,
        tmpl_error  => "error.tmpl",
        t           => undef,

        dbh         => undef,
        dsn         => undef,       # you must edit into 'SCONFIG';
        duser       => undef,       # you must edit into 'SCONFIG';
        dpass       => undef,       # you must edit into 'SCONFIG';
        teng        => undef,
    };

    my $cginame  = $0;
    $cginame     =~ s/.*\///g;
    my $basename = $cginame;
    $basename    =~ s/\..+//g;
    $hash->{cginame}  = $cginame;
    $hash->{basename} = $basename;
    $hash->{tmplfile} = $basename . '.tmpl';

    $hash = SCONFIG::param($hash);
    return bless $hash, $pkg;
}

# =============================================================================#
# OUTLINE : 基本アプリ用の初期設定メソッド
# RETURN  : TRUE/FALSE
# =============================================================================#
sub init {
    my $self = shift;

    #セッションの準備
    $self->{s} = CGI::Session->new("driver:File",
                                    $self->{q},
                                   {Directory => $self->{sessiondir}});
    $self->{s}->expire('+1h');
    $self->add_cookie("CGISESSID", $self->{s}->id);

    #テンプレートの準備
    $self->_default_tmpl();

    #DBの準備
    $self->_db_connect() if($self->{dsn} && $self->{duser} && $self->{dpass});

    return TRUE;
}

# =============================================================================#
# OUTLINE : テンプレートの設定準備
# RETURN  : NONE
# =============================================================================#
sub _default_tmpl {
    my $self     = shift;

    $self->{t} = {
        maintitle      => $self->{maintitle},
        subtitle       => $self->{subtitle},
        description    => $self->{description},
        author         => $self->{author},
        copyright      => $self->{copyright},
        program        => $self->{program},
        version        => $self->{version},
        cginame        => $self->{cginame},
        basename       => $self->{basename},
      };

    # デバッグモード
    if($self->{debug}) {
        $self->{t}->{debug} = 1;
    }
}

# =============================================================================#
# OUTLINE : テンプレート表示 (DB切断も行う)
# RETURN  : NONE
# =============================================================================#
sub print_page {
  my $self  = shift;

  $self->_db_destroy();

  my $tmplfile;
  if($self->{t}->{error}){
    $tmplfile = $self->{tmpl_error};
  }else{
    $tmplfile = $self->{tmplfile};
  }

  my $tmplobj = Template->new({INCLUDE_PATH => $self->{templatedir}});
  print $self->{q}->header(-charset => 'utf-8', -cookie => $self->{cookie});
  $tmplobj->process($tmplfile, $self->{t} ) || die;
}

# =============================================================================#
# OUTLINE : DB接続
# RETURN  : NONE
# =============================================================================#
sub _db_connect {
    my $self = shift;

    $self->{dbh} = DBI->connect_cached(
                    $self->{dsn}, $self->{duser}, $self->{dpass},
                    {AutoCommit => 0, RaiseError => 0, RowCacheSize => 1000}
                 ) || $self->errorMessage("ERROR: cannot connect to database (" . $self->{cginame} . " )", TRUE);

    $self->{teng} = Teng::Schema::Loader->load(
        dbh       => $self->{dbh},
        namespace => 'mdDog::DB'
    );
}

# =============================================================================#
# OUTLINE : DB接続の破棄
# RETURN  : NONE
# =============================================================================#
sub _db_destroy {
    my $self = shift;

    if($self->{dbh}->{Active}) {    #DBコネクションがあったら
        $self->{dbh}->disconnect;   #DBコネクションの破棄
    }
}

# =============================================================================#
# OUTLINE : DBにコミット
# RETURN  : NONE
# =============================================================================#
sub dbCommit {
  my $self = shift;

  $self->{dbh}->commit();
}

# =============================================================================#
# OUTLINE : エラー表示
# PARAM2  : メッセージ
# PARAM3  : exitフラグ
# RETURN  : NONE
# =============================================================================#
sub errorMessage {
  my $self    = shift;
  my $message = shift;
  my $exitFlg = shift;

  $self->{t}->{error} = $message;

  if($exitFlg) {
    my $tmplobj = Template->new({INCLUDE_PATH => $self->{templatedir}});
    print $self->{q}->header(-charset => 'utf-8');
    $tmplobj->process($self->{tmplfile}, $self->{t} ) || die;
    exit();
  }
}

# =============================================================================#
# OUTLINE : 
# RETURN  : 
# =============================================================================#
sub qParam {
  my $self = shift;
  my $param = shift;

  return $self->{q}->param($param);
}


# =============================================================================#
# OUTLINE : 
# RETURN  : 
# =============================================================================#
sub add_cookie {
    my ($self, $key, $value, $expire) = @_;

    if( $expire ){
      push @{$self->{cookie}}, CGI::Cookie->new(-name=>$key, -value=>$value, -expires=>$expire);
    }else{
      push @{$self->{cookie}}, CGI::Cookie->new(-name=>$key, -value=>$value);
    }
}

1;
