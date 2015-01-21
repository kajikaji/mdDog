'use strict'
/***********************************************
 * 関数定義
 ***********************************************/

function getParam(key) {
    var url = location.href;
    var param = url.split("?");
    var params = param[1].split("&");
    for( var i=0; i < params.length; i++ ){
        var pCols = params[i].split("=");
        if(pCols[0] === key){
            return pCols[1];
        }
    }
    return null;
}
