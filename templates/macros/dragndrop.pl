sub _dragndrop_init {
  
  $courseHtmlUrl = $envir{htmlURL};
  # Load jquery nestable from cdnjs.cloudflare.com
  ADD_CSS_FILE("https://cdnjs.cloudflare.com/ajax/libs/nestable2/1.6.0/jquery.nestable.min.css", 1);
  ADD_JS_FILE("https://cdnjs.cloudflare.com/ajax/libs/nestable2/1.6.0/jquery.nestable.min.js", 1);
  ADD_JS_FILE("$courseHtmlUrl/js/dragndrop_wrapper.js", 1);
 
  main::PG_restricted_eval("sub DragNDrop {new DragNDrop(\@_)}");
} 

package DragNDrop;

my $n = 0;

sub new {    
	my $self = shift; 
    my $class = ref($self) || $self;
    
    my $answer_input_id = shift;
    my %options = (
		AllowNewBuckets => 0,
		@_
	);
    
    my $previous = $main::inputs_ref->{$answer_input_id} || "";
    warn $previous;  
    $self = bless {        
        answer_input_id => $answer_input_id,        
        bucket_list => [],
        aggregate_list => [],
        previous => $previous,
        %options,
    }, $class;
            
    return $self;
}

sub addBucket {
    my $bucket_id = $n++;
    my $self = shift; 
    
    my $list = shift || [];
    # my $container_id = shift || '';
    my $label = shift || ''; 
    my %options = (
		removable => 0,
		@_
	);  
    
    my $bucket = {
        list => $list,
        # container_id => $container_id,
        bucket_id => $bucket_id,
        label => $label,
        removable => $options{removable},
    };
    push(@{$self->{bucket_list}}, $bucket);
    push(@{$self->{aggregate_list}}, @{$list});
        
}

sub getPrevious {
    my $self = shift; 
    return $self->{previous};
}

sub toHTML {
    my $self = shift;
    
    my $out = '';
    $out .= '<div class="bucket_pool" data-ans="'.$self->{answer_input_id}.'">';
    my $previous = $self->{previous};
    main::pretty_print $previous;       
    my @optionsList = ();
    
    for (my $i = 0; $i < @{$self->{bucket_list}}; $i++) {
        my $bucket = $self->{bucket_list}->[$i];        
        # $out .= "<div class='hidden bucket' data-bucket-id='".$bucket->{bucket_id}."'>";
        # $out .= "<div class='label'>".$bucket->{label}."</div>"; 
        # $out .= "<ol class='answer'>";
        my $list = [];
        if ($previous eq "") {
            for ( my $j = 0; $j < @{ $bucket->{list} }; $j++ ) {
                push (@$list, {'shuffled_index' => $j, 'item' => $bucket->{list}->[$j]}) ;
            }
        } else {
            my @matches = ( $previous =~ /(\(\d*(?:,\d+)*\))+/g );
            my @refList = split(',' , $matches[$i] =~ s/\(|\)|\s*//gr);
            warn main::pretty_print [ @refList ];
            $list = [];
            for my $ref ( @refList ) {
                # push(@$list, $self->{aggregate_list}->[$ref]);
                push (@$list, {'shuffled_index' => $ref, 'item' => $self->{aggregate_list}->[$ref]});
            }            
        }
        my $DragNDropOptions =  JSON->new->encode({                
            # containerId => 'nestable-'.$bucket->{container_id}.'-container',
            bucketId => $bucket->{bucket_id},
            answerInputId => $self->{answer_input_id},
            removable => $bucket->{removable},            
            label => $bucket->{label},
            list => $list,
        });
        warn main::pretty_print $DragNDropOptions;
        push(@optionsList, $DragNDropOptions);
        # $out .= "</ol>";
        # $out .= "</div>";         
    }
    my $aggregate = JSON->new->encode({
        list => $self->{aggregate_list},
    });
    
    $out .= "\n<script type='text/javascript'>";
    $out .= "\nvar aggregate = {".$self->{answer_input_id}.": $aggregate}";
    for $options ( @optionsList ) {
        $out .= "\nnew Bucket($options);";
    }
    $out .= "\n</script>";
    $out .= "<br clear='all'><div><a class='btn reset_buckets'>reset</a>";    
    if ($self->{AllowNewBuckets} == 1) {
        $out .= "<a class='btn add_bucket' data-ans='".$self->{answer_input_id}."'>add bucket</a></div>";
    }
    $out .= '</div>';
    return $out;
}

sub ans_rule {
	my $self = shift;
    # my @list = @{ $self->{list} };
    if ($main::displayMode eq 'TeX') {
        return "\\begin{itemize}\\item".join("\n\n\\item\n" , @{ $self->{aggregate_list} })."\\end{itemize}";
    }
    return main::NAMED_HIDDEN_ANS_RULE($self->{answer_input_id});    
}
1;