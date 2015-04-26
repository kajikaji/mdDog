'use strict'

require.config({
    paths: {
        'diffViewer'      :'tableLog/diffViewer',
        'revisionViewer'  :'tableLog/revisionViewer',
        'rollbackBuffer'  :'tableLog/rollbackBuffer',
        'editLogComment'  :'tableLog/editLogComment',
    }
});

require(['diffViewer', 'revisionViewer', 'rollbackBuffer', 'editLogComment'],
function(DiffViewer, RevisionViewer, RollbackBuffer, EditLogComment){
    new DiffViewer().init();
    new RevisionViewer().init();
    new RollbackBuffer().init();
    new EditLogComment().init();
});
