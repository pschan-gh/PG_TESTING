// if ($('#content').attr('data-dndloaded') != 'true') {
if (typeof DragNDropIsLoaded == 'undefined') {
// try {
//     DragNDropIsLoaded();
// } catch(e) {
    // if (typeof (new DragNDropBucket()) == 'undefined') {
        $.ajax({
            url: 'http://localhost/webwork2_files/js/apps/DragNDrop/dragndrop.js',
            dataType: 'script',
            async: false
        })
    // }
}
