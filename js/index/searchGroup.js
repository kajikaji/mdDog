'use strict'

define(function(){
    var searchGroup = function(obj){
        this.obj = obj;
    };
    searchGroup.prototype = {
        init: function(){
            this.obj.on('change', $.proxy(function(){
                var group = this.obj.val();
                var href = "index.cgi?group=" + group + '&page=0';
                var style = getParam('style');
                if( style ){
                    href += "&style=" + style;
                }
                location.href = href;
            }, this));
        }
    };

    return searchGroup;
});
