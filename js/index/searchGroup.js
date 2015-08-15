'use strict'

define(function(){
    var searchGroup = function(obj){
        this.obj = obj;
        this.api      = 'api/searchGroups.cgi';
    };
    searchGroup.prototype = {
        init: function(){
            this.obj.on('change', $.proxy(function(){
                var group = this.obj.val();
                var href = "index.cgi?group=" + group;
                var style = getParam('style');
                if( style ){
                    href += "&style" + style;
                }
                location.href = href;
            }, this));
        }
    };

    return searchGroup;
});
