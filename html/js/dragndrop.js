// (function() {
function DragNDropIsLoaded() {
    return true;    
}

class DragNDropBucket {
    constructor(pgData) {
        this.answerInputId = pgData['answerInputId'];
        this.bucketId = pgData['bucketId'];
        this.label = pgData['label'] || '';
        this.removable = pgData['removable'];
        this.bucketPool = $('.bucket_pool[data-ans="' + this.answerInputId + '"]').first()[0];
        
        var $bucketPool = $(this.bucketPool);
        var $newBucket = this._newBucket(this.bucketId, this.label, this.removable, $bucketPool.find('.hidden.past_answers.bucket[data-bucket-id="' + this.bucketId + '"]'));
        $bucketPool.append($newBucket);
        
        var el = this;
        $newBucket.find('.dd').nestable({
            group: el.answerInputId,
            maxDepth: 1,
            scroll: true,
            callback: function() {el._nestableUpdate();}
        });  
        this._nestableUpdate();
        this._ddUpdate();
    }
    
    _newBucket(bucketId, label, removable, $bucketHtmlElement) {
        var $bucketPool = $(this.bucketPool);
        var $newBucket = $('<div id="nestable-' + bucketId + '-container" class="dd-container"></div>').attr('data-bucket-id', bucketId);
    
        $newBucket.append($('<div class="nestable-label">' + label + '</div>'));
        $newBucket.append($('<div class="dd" data-bucket-id="' + bucketId + '"></div>'));
        
        if (removable != 0) {
            $newBucket.append($('<a class="btn remove_bucket">Remove</a>'));
        }
        
        if ($bucketHtmlElement.find('ol.answer li').length) {
            var $ddList = $('<ol class="dd-list"></ol>');
            $bucketHtmlElement.find('ol.answer li').each(function(index) {
                var $item = $('<li><div class="dd-handle">' + $(this).html() + '</div></li>');
                $item.addClass('dd-item').attr('data-shuffled-index', $(this).attr('data-shuffled-index'));
                $ddList.append($item);
            });
            $newBucket.find('.dd').first().append($ddList);
        }
        $newBucket.css('background-color', 'hsla(' + ((100 + (bucketId)*100) % 360) + ', 40%, 90%, 1)');
        return $newBucket;
    }
        
    _nestableUpdate(e) {
        var buckets = [];
        $(this.bucketPool).find('.dd').each(function() {
            var list = [];
            $(this).find('li.dd-item').each(function() {
                list.push($(this).attr('data-shuffled-index'));
            });
            if (list.length) {
                buckets.push('(' + list.join(",") + ')');
            } else {
                buckets.push('(-1)');
            }
        });
        
        $("#" +  this.answerInputId).val(buckets.join(","));
    }
    
    _ddUpdate() {
        var answerInputId = this.answerInputId;
        var $bucketPool = $('.bucket_pool[data-ans="' + answerInputId + '"]').first();
        var el = this;
        $(function() {
            $bucketPool.parent().find('.add_bucket').off();
            $bucketPool.parent().find('.add_bucket').click(function() {
                new DragNDropBucket({
                    answerInputId: $(this).attr('data-ans'),
                    bucketId: +($('.dd').length) + 1,
                    removable: 1,
                    label:'',
                });
            });
            $bucketPool.find('.remove_bucket').off();
            $bucketPool.find('.remove_bucket').click(function() {
                if ($bucketPool.find('.dd ol').length == 1) {
                    return 0;
                }
                var bucketId = $(this).closest('.dd-container').attr('data-bucket-id');
                var $container = $(this).closest('.dd-container');
                $container.find('li').appendTo($bucketPool.find('.dd ol').first());
                $container.remove();
                el._nestableUpdate();
            });
            $bucketPool.parent().find('.reset_buckets').off();
            $bucketPool.parent().find('.reset_buckets').click(function() {
                $bucketPool.find('.dd-container').remove();
                $bucketPool.find('div.hidden.default.bucket').each(function() {
                    var bucketId = $(this).attr('data-bucket-id');
                    var label = $(this).find('.label').first().html() || '';
                    var $bucket = el._newBucket($(this).attr('data-bucket-id'), $(this).find('.label').first().html(), $(this).attr('data-removable'), $bucketPool.find('.hidden.default.bucket[data-bucket-id="' + bucketId + '"]'));                    
                    $bucketPool.append($bucket);
                });
                
                $bucketPool.find('.dd').nestable({
                    group: el.answerInputId,
                    maxDepth: 1,
                    scroll: true,
                    callback: function() {el._nestableUpdate();}
                });  
                el._nestableUpdate();
            });
        });    
    }
        
}

// $('div.bucket_pool').each(function() {
//     var answerInputId = $(this).attr('data-ans');
//     if ($(this).find('div.bucket.past_answers.hidden').length) {
//         $(this).find('div.bucket.past_answers.hidden').each(function() {
//             new DragNDropBucket({
//                 answerInputId : answerInputId,
//                 bucketId : $(this).attr('data-bucket-id'),
//                 label : $(this).find('.label').html(),
//                 removable : $(this).attr('data-removable'),
//             });
//         });
//     } 
// });

$('#content').attr('data-dndloaded', 'true');
console.log('dnd loaded');
// })();
var DragNDropIsLoaded = 1;

$(function() {
    $('div.bucket_pool').each(function() {
        var answerInputId = $(this).attr('data-ans');
        if ($(this).find('div.bucket.past_answers.hidden').length) {
            $(this).find('div.bucket.past_answers.hidden').each(function() {
                new DragNDropBucket({
                    answerInputId : answerInputId,
                    bucketId : $(this).attr('data-bucket-id'),
                    label : $(this).find('.label').html(),
                    removable : $(this).attr('data-removable'),
                });
            });
        } 
    });
});
