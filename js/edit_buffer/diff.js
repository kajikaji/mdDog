'use strcit'

define(function(){
    var diff = function(){};
    diff.prototype = {
        init: function(){
            var myNum, myLine, masterNum, masterLine;
            var atmark = /^@@ -([0-9]+),([0-9]+) \+([0-9]+),([0-9]+) @@/;
            var $delBtn = $('<div>').addClass('Ctrl').append(
                $('<a>').append(
                $('<span>').addClass('typcn typcn-delete')
                )
            );
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
                    var $btn = $delBtn.clone()
                    $btn.find('a').on('click', function(){
                        $(this).parents('li').toggleClass('Omit');
                    });
                    $('#Mine' + myNum).addClass('Local').append($btn);
                    myNum++;
                }else if( line.match(/^\+/) ){
                    var $target = $('#Mine' + myNum);
                    var $org = $('#Master' + masterNum).clone();
                    var $btn = $delBtn.clone()
                    $btn.find('a').on('click', function(){
                        $(this).parents('li').toggleClass('Omit');
                    });
                    $target.before($org.addClass('Master').append($btn));
                    masterNum++;
                }else{
                    myNum++;
                    masterNum++;
                }
            });
        }
    };

    return diff;
});
