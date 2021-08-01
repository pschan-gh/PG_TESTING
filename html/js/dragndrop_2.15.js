if ($('#content').attr('data-dnd-loaded') != 'true') {
    $.ajax({
        url: 'http://localhost/webwork2_files/js/apps/DragNDrop/dragndrop.js',
        dataType: 'script',
        async: false
    });
}
