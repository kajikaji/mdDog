package APPBASE;

use strict;
use CGI;
use Template;
use DBI;
use constant TRUE => 1;
use constant FALSE => 0;

use DEFINE;
use SCONFIG;

sub new {
  my $pkg = shift;

  my $hash = {
    q           => new CGI,
    cginame     => undef,
    basename    => undef,
    templatedir  => './tmpl/',
    tmplfile    => undef,
    t           => undef,

    dbh         => undef,
    dsn         => undef,       # you must edit into 'SCONFIG';
    duser       => undef,       # you must edit into 'SCONFIG';
    dpass       => undef,       # you must edit into 'SCONFIG';
  };

  $hash = DEFINE::param($hash);
  $hash = SCONFIG::param($hash);

  return bless $hash, $pkg;
}

# =============================================================================#
# OUTLINE : 基本アプリ用の初期設定メソッド
# RETURN  : TRUE/FALSE
# =============================================================================#
sub setupConfig {
  my $self = shift;
  my $tmplfile = shift;

  my $cginame = $0;
  $cginame =~ s/.*\///g;
  my $basename = $cginame;
  $basename =~ s/\..+//g;

  $self->{cginame} = $cginame;
  $self->{basename} = $basename;

  $self->setupTmpl($tmplfile);
  $self->connectDb() if($self->{dsn} && $self->{duser} && $self->{dpass});

  return TRUE;
}

# =============================================================================#
# OUTLINE : テンプレートの設定準備
# RETURN  : NONE
# =============================================================================#
sub setupTmpl {
    my $self     = shift;
    my $tmplfile = shift;

    if($tmplfile) {
        $self->{tmplfile} = $tmplfile ;
    } else {
        $self->{tmplfile} = $self->{basename} . '.tmpl';
    }

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
sub printPage {
  my $self  = shift;

  $self->destroy();

  my $tmplobj = Template->new({INCLUDE_PATH => $self->{templatedir}});
  print $self->{q}->header(-charset => 'utf-8');
  $tmplobj->process($self->{tmplfile}, $self->{t} ) || die;
}

# =============================================================================#
# OUTLINE : DB接続
# RETURN  : NONE
# =============================================================================#
sub connectDb {
  my $self = shift;

  $self->{dbh} = DBI->connect_cached(
                    $self->{dsn}, $self->{duser}, $self->{dpass},
                    {AutoCommit => 0, RaiseError => 0, RowCacheSize => 1000}
                 ) || $self->errorMessage("ERROR: cannot connect to database (" . $self->{cginame} . " )", TRUE);
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
# OUTLINE : DB接続の破棄
# RETURN  : NONE
# =============================================================================#
sub destroy {
    my $self = shift;

    if($self->{dbh}->{Active}) {    #DBコネクションがあったら
        $self->{dbh}->disconnect;   #DBコネクションの破棄
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

1;
