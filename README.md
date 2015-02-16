# mdDog


- 仕様書作成に特化したドキュメント管理ツールです
- 長期的な仕様書のメンテを手助けすることを目的としています
- ドキュメントのフォーマットはMarkdownを用いて、仕様書に適した出力を目指しています
- ドキュメントのファイル管理はgitを利用しており、更新履歴は自動生成して出力されます
- また目次も自動生成して出力されます


## DEPENDENCIES

- git
- PostgreSQL
- NKF
- CGI.pm
- CGI::Session.pm
- DBI.pm
- Git::Wrapper.pm
- Image::Magick.pm
- JSON.pm
- Template.pm
- Text::Markdown::Discount.pm
- Date::Manip.pm
- Data::Dumper.pm
- ....


## DEMO

Dockerhubにデモ環境を用意しました。

dockerを既に用意されている方は、
dockerhubにログインして以下のコマンドで最新版の環境を試せます。

````
docker pull gm2bv/mddog_test
docker run -p 80:80 gm2bv/mddog_test
````
- ユーザー；admin
- パスワード：admin


## NEWS

> 2015/2/14 Dockerfileを追加してdockerhubでautobuidlできるようにしました

> 2015/2/11 GPLv3ライセンスを適用しました

> 2015/1/7 プロジェクト名を"docxlog"から"mdDog"に変更しました。
