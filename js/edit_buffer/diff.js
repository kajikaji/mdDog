'use strcit'

define(function(){
    var diff = function(){};
    diff.prototype = {
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
                    $('#Mine' + myNum).addClass('Local');
                    myNum++;
                }else if( line.match(/^\+/) ){
                    var $target = $('#Mine' + myNum);
                    var $org = $('#Master' + masterNum);
                    $target.before($org.clone().addClass('Master'));
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
