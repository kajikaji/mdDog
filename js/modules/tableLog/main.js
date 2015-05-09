'use strict'

require.config({
    paths: {
        'diffViewer'      :'modules/tableLog/diffViewer',
        'revisionViewer'  :'modules/tableLog/revisionViewer',
        'headLogCtrl'     :'modules/tableLog/headLogCtrl',
        'rollbackBuffer'  :'modules/tableLog/rollbackBuffer',
        'editLogComment'  :'modules/tableLog/editLogComment',
    },
    shim: {
        'headLogCtrl':{
            deps : ['UTIL']
        }
    }
});

require(['diffViewer', 'revisionViewer', 'headLogCtrl'],
        function(DiffViewer, RevisionViewer, HeadLogCtrl){
    var fid = getParam('fid');
    new DiffViewer().init();
    new RevisionViewer().init();
    new HeadLogCtrl(fid).init();
});
