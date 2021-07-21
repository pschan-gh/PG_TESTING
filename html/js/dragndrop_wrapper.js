console.log('dnd wrapper loaded');

class Bucket {
    constructor(serverData) {
        console.log(serverData);
        this.answerInputId = serverData['answerInputId'];
        this.bucketId = serverData['bucketId'];
        // this.list = serverData['list'];
        this.indices = serverData['indices'];
        this.label = serverData['label'];
        this.aggregateList = serverData['aggregateList']
        console.log(this.aggregateList);
        
        var answerInputId = this.answerInputId;
        var bucketId = this.bucketId;
        var $bucketPool = $('.bucket_pool[data-ans="' + answerInputId + '"]').first();
                
        var $newBucket = $('<div id="nestable-' + bucketId + '-container" class="dd-container"></div>').attr('data-bucket-id', bucketId);
    
        $newBucket.append($('<div class="nestable-label">' + this.label + '</div>'));
        $newBucket.append($('<div class="dd" data-bucket-id="' + this.bucketId + '"></div>'));
        if (serverData['removable'] != 0) {
            $newBucket.append($('<a class="btn remove_bucket">Remove</a>'));
        }
        
        if (this.indices && this.indices.length) {
            var $ddList = $('<ol class="dd-list"></ol>').attr('data-bucket-id', this.bucketId);
            var $item;
            this.indices.forEach(index => {
                $item = $('<li><div class="dd-handle">' + this.aggregateList[index] + '</div></li>');
                $item.addClass('dd-item').attr('data-shuffled-index', index);
                $ddList.append($item);
            });
            $newBucket.find('.dd').first().append($ddList);
        }
                
        $bucketPool.append($newBucket);
        
        var el = this;
        $newBucket.find('.dd').nestable({
            group: answerInputId,
            maxDepth: 1,
            scroll: true,
            callback: function() {el._nestableUpdate()}
        });  
        this._nestableUpdate()
        this._ddUpdate();
    }
    
    _nestableUpdate(e) {
        console.log('updating ans');
        console.log(this.answerInputId);
        var buckets = [];
        $('.dd').each(function() {
            var list = [];
            $(this).find('li.dd-item').each(function() {
                list.push($(this).attr('data-shuffled-index'));
            });
            buckets.push('(' + list.join(",") + ')');
        });
        console.log(buckets);
        
        $("#" +  this.answerInputId).val(buckets.join(","));
    }
    
    _ddUpdate() {
        console.log('_ddUpdate');
        var answerInputId = this.answerInputId;
        var $bucketPool = $('.bucket_pool[data-ans="' + answerInputId + '"]').first();
        console.log($bucketPool);
        var el = this;
        $(function() {
            $bucketPool.parent().find('.add_bucket').off();
            $bucketPool.parent().find('.add_bucket').click(function() {
                new Bucket({
                    answerInputId: $(this).attr('data-ans'),
                    bucketId: +($('.dd').length) + 1,
                    removable: 1,
                    label:'',
                });
            });
            $bucketPool.find('.remove_bucket').click(function() {
                var bucketId = $(this).closest('.dd-container').attr('data-bucket-id');
                var $container = $(this).closest('.dd-container');
                $container.find('li').appendTo($bucketPool.find('.dd[data-bucket-id="0"] ol').first());
                // $('.hidden[data-bucket-id="' + bucketId + '"]').remove();
                $container.remove();
                el._nestableUpdate();
            });
            $bucketPool.parent().find('.reset_buckets').off();
            $bucketPool.parent().find('.reset_buckets').click(function() {
                console.log('clicked');
                $bucketPool.find('.dd').each(function() {
                    $(this).find('ol, .dd-empty').remove();
                });
                var $firstBucket = $bucketPool.find('.dd[data-bucket-id="0"]');
                console.log(el.aggregateList);
                $firstBucket.find('ol, .dd-empty').remove();
                if ( el.aggregateList.length ) {
                    var $ddList = $('<ol class="dd-list"></ol>');                    
                    // $('ol.hidden.default[data-bucket-id="0"] li').each(function() {
                    el.aggregateList.forEach((listItem, index) => {
                        var $item = $('<li class="dd-item"><div class="dd-handle">' + listItem + '</div></li>');
                        $item.attr('data-shuffled-index', index);
                        $ddList.append($item);
                    });
                    // });
                    $firstBucket.append($ddList);
                } 
                $bucketPool.find('.dd').each(function() {
                    if ($(this).find('.dd-empty').length == 0 && $(this).find('li').length == 0) {
                        $(this).append('<div class="dd-empty"></div>');
                    }               
                });
                
                $(function() {                                   
                    el._nestableUpdate();
                    refreshAllCSS($bucketPool);
                });
            });
            el._refreshCSS();
        });    
    }
    
    _refreshCSS() {
        var answerInputId = this.answerInputId;
        var bucketId = this.bucketId;
        var $bucketPool = $('.bucket_pool[data-ans="' + answerInputId + '"]').first();
        var $container = $bucketPool.find('.dd-container[data-bucket-id="' + bucketId + '"]').first();
        
        refreshCSS($container);
    }
}

function refreshAllCSS($bucketPool) {
    $bucketPool.find('.dd-container').each(function() {
        var $container = $(this);
        refreshCSS($container);
    });
}

function refreshCSS($container) {
    $container.css({width: '350px',
    float: 'left',
    margin: '10px',
    padding: '0',
    color: '#000000',
    border: '1px solid #388E8E',
    borderRadius: '5px',
    textAlign: 'center'});

    $container.find('.nestable-label').css({
        margin: '10px 0 10px 0',
    });

    $container.find('.dd, .dd-list, .dd-item').css({
        display: 'block',
        position: 'relative',
        listStyle: 'none',
        margin: '0',
        padding: '0',
        minHeight: '30px',
    });

    $container.find('.dd-empty, .dd-handle, .dd-placeholder').css( {
        display: 'block',
        position: 'relative',
        margin: '0 10px 10px 10px',
        padding: '4px',
        minHeight: '30px',
        boxSizing: 'border-box',
        borderRadius: '5px',
    });
    $container.find('.dd-handle').css({
        background: '#F5DEB3',
        border: '1px solid #388E8E',
        textAlign: 'center',
        height: 'auto',
    });
    $container.find('.dd-handle:hover').css({
        cursor: 'pointer',
        background: '#EEE3CE',
        color: '#222'
    });
    $container.find('.dd-placeholder').css({
        background: '#f2fbff',
        border: '1px dashed #b6bcbf',
    });
    $container.find('.dd-dragel').css({
        position: 'absolute',
        pointerEvents: 'none',
        zIndex: '9999',
    });
    $container.find('.dd-dragel > .dd-item .dd-handle').css( {
        marginTop: '0',
    });
    $container.find('.dd-dragel .dd-handle').css({
        '-webkit-box-shadow': '2px 4px 6px 0 rgba(0,0,0,.1)',
        'box-shadow': '2px 4px 6px 0 rgba(0,0,0,.1)',
        'opacity': '0.8',
    });
}