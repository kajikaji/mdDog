'use strict'

define(function(){
    var formWindow = function(obj){
        this.obj      = obj;
        this.fid      = obj.data('fid');
        this.template = $(".Template").find(".GroupCtrlWindow");
        this.api      = 'api/docGroup.cgi';
        this.tags     = $('#doc' + this.fid + ' .Tags');
        this.dialog    = this.template.clone();
        this.groupList = this.dialog.find('ul.GroupList');
        this.candList  = this.dialog.find('select.GroupCandidateList');
    };

    formWindow.prototype = {
        init : function(){
            this.dialog.attr('id', 'docGroup' + this.fid);
            var doc = $('#doc' + this.fid);
            var docName = doc.find('.Info .DocSubject .Name a').text();
            this.dialog.find('.DocName').text(docName);

            this.groupList.children().remove();
            this.tags.children().each($.proxy(function(i, elm){
                this.addIntoList($(elm).text());
            }, this));

            $('body').prepend(this.dialog);

            //キャンセルボタン
            var cancelBtn = this.dialog.find('button.CancelBtn');
            cancelBtn.one('click', $.proxy(function(){
                this.dialog.remove();
            }, this));

            //決定ボタン
            var fixBtn = this.dialog.find('button.FixBtn');
            fixBtn.one('click', $.proxy(function(){
                var $groups = [];
                this.groupList.children().each(function(){
                    $groups.push($(this).text());
                });
                $.ajax({
                    url: this.api,
                    type : 'POST',
                    data: {
                        fid: this.fid,
                        action: 'editGroup',
                        groups:$groups
                    },
                    timeout: 5000
                }).done($.proxy(function(res){
                    this.tags.children().remove();
                    $(res).each($.proxy(function(i, elm){
                        this.tags.append(
                            $('<li>').addClass('GroupTag').append(
                                $('<div>').text(elm)
                            )
                        );
                    }, this));
                }, this));

                this.dialog.remove();
            }, this));

            var $inputText = this.dialog.find('input.GroupName');
            var searchTxt = "";
            $inputText.on('input', $.proxy(function(){
                var inputTxt = $inputText.val();
                if( searchTxt === inputTxt ){
                    return;
                }
                if( inputTxt.length == 0 ){
                    this.candList.children('.Dynamic').remove();
                    return;
                }
                searchTxt = inputTxt;
                $.ajax({
                    url : this.api,
                    type : 'POST',
                    data : {
                        fid : this.fid,
                        search : searchTxt
                    },
                    timeout: 5000
                }).done($.proxy(function(res){
                    this.candList.children('.Dynamic').remove();
                    $(res).each($.proxy(function(i, elm){
                        this.candList.append(
                            $('<option>').addClass('Dynamic').text(elm.title)
                        );
                    }, this));
                    if( $(res).length == 0 ){
                        this.candList.attr('size', 0);
                    }else{
                        this.candList.attr('size', $(res).length + 1);
                    }
                }, this));

            },this));;

            this.candList.on('change', $.proxy(function(){
                var $selectedText = this.candList.find('option:selected').text();
                this.dialog.find('input.GroupName').val($selectedText);
            }, this));

            //追加ボタン
            this.dialog.find('button.GroupAddBtn').on('click', $.proxy(function(){
                var groupTxt = $inputText.val();
                this.addIntoList(groupTxt);
                $('input.GroupName').val("");
                this.candList.children('.Dynamic').remove();
            }, this));
        },
        addIntoList: function(newGroup){
            var $delBtn = $('<a>').append(
                $('<i>').addClass('typcn typcn-delete')
            );
            var $newCand = $('<li>').append(
                $('<div>').text(newGroup)
                .append($delBtn)
            );    
            this.groupList.append(
                $newCand
            );
            $delBtn.one('click', $.proxy(function(){
                $newCand.remove();
            }, this));
        }
    };

    return formWindow;
});

