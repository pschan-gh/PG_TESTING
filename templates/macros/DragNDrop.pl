sub _DragNDrop_init {
    main::PG_restricted_eval("sub DragNDrop {new DragNDrop(\@_)}");
} 

package DragNDrop;

sub new {    
	my $self = shift; 
    my $class = ref($self) || $self;
    
    my $answerInputId = shift; # 'id' of html <input> tag corresponding to the answer blank. Must be unique to each pool of DragNDrop buckets
    my $aggregateList = shift; # array of all statements provided
    my $defaultBuckets = shift; # instructor-provided default buckets with pre-included statements encoded by the array of corresponding statement indices
    my %options = (
		AllowNewBuckets => 0,
		@_
	);

    $self = bless {        
        answerInputId => $answerInputId,        
        bucketList => [],
        aggregateList => $aggregateList,
        defaultBuckets => $defaultBuckets,
		%options,
    }, $class;
            	
    return $self;
}

sub addBucket {    
    my $self = shift; 
    
    my $indices = shift;
	
	my %options = (
	label => "",
	removable => 0,
	@_
    );
	
	my $bucket = {
        indices => $indices,
        list => [ map { $self->{aggregateList}->[$_] } @$indices ],
        bucket_id => scalar @{ $self->{bucketList} },
		label => $options{label},
        removable => $options{removable},
    };
    push(@{$self->{bucketList}}, $bucket);
    
}

sub HTML {
    my $self = shift;
    	
    my $out = '';
    $out .= "<div class='bucket_pool' data-ans='$self->{answerInputId}'>";
        
    # buckets from instructor-defined default settings
    for (my $i = 0; $i < @{$self->{defaultBuckets}}; $i++) {
        my $defaultBucket = $self->{defaultBuckets}->[$i];
        $out .= "<div class='hidden default bucket' data-bucket-id='$i' data-removable='$defaultBucket->{removable}'>";
        $out .= "<div class='label'>$defaultBucket->{label}</div>"; 
        $out .= "<ol class='answer'>";
        for my $j ( @{$defaultBucket->{indices}} ) {
            $out .= "<li data-shuffled-index='$j'>$self->{aggregateList}->[$j]</li>";
        }
        $out .= "</ol></div>";
    }
    
	# buckets from past answers
    for my $bucket ( @{$self->{bucketList}} ) {
        $out .= "<div class='hidden past_answers bucket' data-bucket-id='$bucket->{bucket_id}' data-removable='$bucket->{removable}'>";
        $out .= "<div class='label'>$bucket->{label}</div>"; 
        $out .= "<ol class='answer'>";
        
        for my $index ( @{$bucket->{indices}} ) {
            $out .= "<li data-shuffled-index='$index'>$self->{aggregateList}->[$index]</li>";
        }
        $out .= "</ol>";
        $out .= "</div>"; 
    }    
    $out .= '</div>';
    $out .= "<br clear='all'><div><a class='btn reset_buckets'>reset</a>";    
    if ($self->{AllowNewBuckets} == 1) {
        $out .= "<a class='btn add_bucket' data-ans='$self->{answerInputId}'>add bucket</a>";
    }
	$out .= "</div>";
    
    return $out;
}

sub TeX {
    my $self = shift;
    	
    my $out = "";
        
    # default buckets;
    for (my $i = 0; $i < @{ $self->{defaultBuckets} }; $i++) {
		$out .= "\n";
        my $defaultBucket = $self->{defaultBuckets}->[$i];
		if ( @{$defaultBucket->{indices}} > 0 ) {
			$out .= "\n\\hrule\n\\begin{itemize}";		
			for my $j ( @{$defaultBucket->{indices}} ) {
				$out .= "\n\\item[$j.]\n $self->{aggregateList}->[$j]";
			}
			$out .= "\n\\end{itemize}";
		}
		$out .= "\n\\hrule\n";
    }
    return $out;
}
1;