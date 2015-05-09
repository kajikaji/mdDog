'use strcit'

define(function(){
    var merge = function(fid){
        this.fid = fid;
        this.api = 'api/merge.cgi';
    };
    merge.prototype = {
        init: function(){
            var myNum, myLine, masterNum, masterLine;
            var atmark = /^@@ -([0-9]+),([0-9]+) \+([0-9]+),([0-9]+) @@/;

            $('.DiffInfo div').each(function(){
                var line   = $(this).text();
                var atinfo = line.match(atmark);
                if( atinfo ){
                    myNum      = atinfo[1];
                    myLine     = atinfo[2];
                    masterNum  = atinfo[3];
                    masterLine = atinfo[4];
                    return;
                }

                if( line.match(/^-/) ){
                    var $target = $('#Mine' + myNum);
                    var $btn    = merge.getDelBtn($target);
                    $target.addClass('Local').append($btn);
                    myNum++;
                }else if( line.match(/^\+/) ){
                    var $target = $('#Mine' + myNum);
                    var $org    = $('#Master' + masterNum);
                    var $btn    = merge.getDelBtn($org);
                    $org.addClass('Master').append($btn);
                    if( $target.length ){
                        $target.before($org);
                    }else{
                        $('.MergeView .Mine .Document').append($org);
                    }
                    masterNum++;
                }else{
                    myNum++;
                    masterNum++;
                }
            });

            //COMMIT BUTTON
            $('#commit').on('click', $.proxy(this.btnCommit, this));
        },
        btnCommit: function(){
            var doc = merge.getMergeText();
            $.ajax({
                url  : this.api,
                type : 'POST',
                data : {
                    fid : this.fid,
                    doc : doc
                },
                timeout: 5000
            }).done(function(res){
                document.location = 'edit_log.cgi?fid=' + res.fid;
            });
        }
    };
    merge.getDelBtn = function(target){
        var $delBtn = $('<div>').addClass('Ctrl').append(
            $('<a>').append(
                $('<span>').addClass('typcn typcn-delete')
            )
        );
        $delBtn.find('a').on('click', function(){
            target.toggleClass('Omit');
            if( $(this).find('.typcn').hasClass('typcn-delete') ){
                $(this).find('.typcn').removeClass('typcn-delete')
                                      .addClass('typcn-delete-outline');
            }else{
                $(this).find('.typcn').removeClass('typcn-delete-outline')
                                      .addClass('typcn-delete');
            }
        });
        return $delBtn;
    };
    merge.getMergeText = function(){
        var $str = "";
        $('.MergeView .Mine .Document').find('li').each($.proxy(function(i, elm){
            if( !$(elm).hasClass('Omit') ){
                $str += $(elm).find('.Line').text();
                $str += '\n';
            }
        }, this));
        return $str;
    };

    return merge;
});
