'use strict'

require.config({
    paths: {
        'diffViewer'      :'modules/tableLog/diffViewer',
        'revisionViewer'  :'modules/tableLog/revisionViewer',
        'rollbackBuffer'  :'modules/tableLog/rollbackBuffer',
        'editLogComment'  :'modules/tableLog/editLogComment',
    }
});

require(['diffViewer', 'revisionViewer', 'rollbackBuffer', 'editLogComment'],
function(DiffViewer, RevisionViewer, RollbackBuffer, EditLogComment){
    new DiffViewer().init();
    new RevisionViewer().init();
    new RollbackBuffer().init();
    new EditLogComment().init();
});
