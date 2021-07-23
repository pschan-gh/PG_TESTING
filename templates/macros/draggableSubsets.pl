# Done: show possible choices in TeX mode
# To do: display student answers and correct answers in TeX mode properly.
# To do: put jquery.nestable.js in a universal spot on every webwork server.

loadMacros("PGchoicemacros.pl",
"MathObjects.pl",
"DragNDrop.pl"
);

sub _draggableSubsets_init {
	PG_restricted_eval("sub DraggableSubsets {new draggableSubsets(\@_)}");
}

package draggableSubsets;

sub new {
	my $self = shift; 
	my $class = ref($self) || $self;
	
	# user arguments
	my $set = shift || []; 
	my $cosets = shift || []; 
	my $default_buckets = shift || [];
	# end user arguments
	
	my $numProvided = scalar(@$set);
	my @order = main::shuffle($numProvided);
	my @unorder = main::invert(@order);

	my $shuffled_set = [ map {$set->[$_]} @order ];
	
	my $default_shuffled_buckets = [];
	if (@$default_buckets) {
		for my $default_bucket (@$default_buckets) {
			my $shuffled_indices = [ map {$unorder[$_]} @{ $default_bucket->{indices} } ];
			my $default_shuffled_bucket = { 
				label => $default_bucket->{label}, 
				indices => $shuffled_indices,
				removable => $default_bucket->{removable},
			};
			push(@$default_shuffled_buckets, $default_shuffled_bucket);			
		} 
	} else {
		push(@$default_shuffled_buckets, [ { 
			label => '', 
			indices => [ 0..$numProvided-1 ]
		} ]);
	}
		
	my $ans_input_id = main::NEW_ANS_NAME() unless $self->{ans_input_id};	
	my $dnd = new DragNDrop($ans_input_id, $shuffled_set, $default_shuffled_buckets, AllowNewBuckets => 1);	
	
	my $previous = $dnd->getPrevious;
	
	if ($previous eq '') {
		for my $default_bucket ( @$default_shuffled_buckets ) {
			$dnd->addBucket($default_bucket->{indices}, $default_bucket->{label});
		}
	} else {
		my @matches = ( $previous =~ /(\(\d*(?:,\d+)*\))+/g );
		for(my $i = 0; $i < @matches; $i++) {
			my $match = @matches[$i] =~ s/\(|\)//gr;			
			my $indices = [ split(',', $match) ];
			my $label = $i < @$default_shuffled_buckets ? $default_shuffled_buckets->[$i]->{label} : '';
			my $removable = $i < @$default_shuffled_buckets ? $default_shuffled_buckets->[$i]->{removable} : 1;
			$dnd->addBucket($indices, $label, removable => $removable);
		}
	}	
		
	my @shuffled_cosets_array = ();
	for my $coset ( @$cosets ) {
		my @shuffled_coset = map {$unorder[$_]} @$coset;
		push(@shuffled_cosets_array, main::Set(join(',', @shuffled_coset)));
	}	
	my $shuffled_cosets = main::List(@shuffled_cosets_array);
			
	
	$self = bless {
		set => $set,
		shuffled_set => $shuffled_set,
		numProvided => $numProvided,
		order => \@order, 
		unordered => \@unorder,
		shuffled_cosets => $shuffled_cosets,
		ans_input_id => $ans_input_id,
		dnd => $dnd,
	}, $class;
	
	return $self;
}

sub Print {
	my $self = shift;
	
	if ($main::displayMode ne "TeX") { # HTML mode
		return join("\n",
			'<div style="min-width:750px;">',
			$self->{dnd}->ans_rule,
			'<br clear="all" />',
			'</div>'
		);
	} else { # TeX mode
		return join("\n",
			$self->{dnd}->ans_rule,
		);
	}
}

sub cmp {
	my $self = shift;	
	return $self->{shuffled_cosets}->cmp(ordered => 0, removeParens => 1)->withPreFilter(sub {$self->prefilter(@_)});
}

sub prefilter {
	my $self = shift; my $anshash = shift;	
	
	my @student = ( $anshash->{original_student_ans} =~ /(\(\d*(?:,\s*\d+)*\)|\d+)/g );
	
	my @student_ans_array;
	for my $match ( @student ) {
		push(@student_ans_array, main::Set($match =~ s/\(|\)//gr));
	}
	
	$anshash->{student_ans} = main::List(@student_ans_array);
	
	return $anshash;
}
1;