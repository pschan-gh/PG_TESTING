sub _dragndrop_init {
  
  $courseHtmlUrl = $envir{htmlURL};
  # Load jquery nestable from cdnjs.cloudflare.com
  ADD_CSS_FILE("https://cdnjs.cloudflare.com/ajax/libs/nestable2/1.6.0/jquery.nestable.min.css", 1);
  ADD_JS_FILE("https://cdnjs.cloudflare.com/ajax/libs/nestable2/1.6.0/jquery.nestable.min.js", 1);
  ADD_JS_FILE("$courseHtmlUrl/js/dragndrop_wrapper.js", 1);
 
  main::PG_restricted_eval("sub DragNDrop {new DragNDrop(\@_)}");
} 

loadMacros("MathObjects.pl");
our @ISA = qw(Value::List);

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
    $self = bless {        
        answer_input_id => $answer_input_id,        
        bucket_list => [],
        aggregate_list => [],
        %options,
    }, $class;
    
    return $self;
}

sub addBucket {
    my $bucket_id = $n++;
    my $self = shift; 
    
    my $list = shift;
    my $container_id = shift;
    my $label = shift || ''; 
    my %options = (
		removable => 0,
		@_
	);  
    
    my $bucket = {
        list => $list,
        container_id => $container_id,
        bucket_id => $bucket_id,
        label => $label,
        removable => $options{removable},
    };
    push(@{$self->{bucket_list}}, $bucket);
    push(@{$self->{aggregate_list}}, @{$list});
    
}

sub ans_rule {
	my $self = shift;
    # my @list = @{ $self->{list} };
    if ($main::displayMode eq 'TeX') {
        return "\\begin{itemize}\\item".join("\n\n\\item\n" , @{ $self->{aggregate_list} })."\\end{itemize}";
    }
    my $out = '<div class="bucket_pool" data-ans="'.$self->{answer_input_id}.'">';
    $out .= main::NAMED_HIDDEN_ANS_RULE($self->{answer_input_id});    
    $previous = $main::inputs_ref->{$self->{answer_input_id}} || "";
        
    
    # duplicate full list in html DOM
    for (my $i = 0; $i < @{$self->{bucket_list}}; $i++) {
        my $bucket = $self->{bucket_list}->[$i];
        $out .= "<ol class='hidden default' data-bucket-id='".$bucket->{bucket_id}."'>";
        for (my $j = 0; $j < @{$bucket->{list}}; $j++) {
            $out .= "<li data-shuffled-index='".$j."'>".$bucket->{list}->[$j]."</li>";
        }
        $out .= "</ol>";
    }
    
    my @optionsList = ();
    
    for (my $i = 0; $i < @{$self->{bucket_list}}; $i++) {
        my $bucket = $self->{bucket_list}->[$i];
        my $DragNDropOptions =  JSON->new->encode({                
            containerId => 'nestable-'.$bucket->{container_id}.'-container',
            bucketId => $bucket->{bucket_id},
            answerInputId => $self->{answer_input_id},
            removable => $bucket->{removable},
            # list => $self->{list}, # Somehow MathJax renders values within the JSON object 
            # label => $bucket->{label},
        });
        push(@optionsList, $DragNDropOptions);
        $out .= "<div class='hidden bucket' data-bucket-id='".$bucket->{bucket_id}."'>";
        $out .= "<div class='label'>".$bucket->{label}."</div>"; 
        $out .= "<ol class='answer'>";
        if ($previous eq "") {
            for (my $j = 0; $j < @{$bucket->{list}}; $j++) {
                $out .= "<li data-shuffled-index='".$j."'>".$bucket->{list}->[$j]."</li>";
            }
        } else {
            my @refList = split(',' , $matches[$i] =~ s/\(|\)|\s*//gr);
            warn main::pretty_print [ @refList ];
            for my $ref ( @refList ) {
                $out .= "<li data-shuffled-index='".$ref."'>".$self->{aggregate_list}->[$ref]."</li>";
            }
        }
        $out .= "</ol>";
        $out .= "</div>"; 
    }
    
    $out .= "</div>";
    $out .= "\n<script type='text/javascript'>\n";
    for $options ( @optionsList ) {
        $out .= "\nnew Bucket($options);";
    }
    $out .= "\n</script>";        
    $out .= "<br clear='all'><div><a class='btn reset_buckets'>reset</a>";    
    if ($self->{AllowNewBuckets} == 1) {
        $out .= "<a class='btn add_bucket' data-ans='".$self->{answer_input_id}."'>add bucket</a></div>";
    }
    return $out;
}
1;