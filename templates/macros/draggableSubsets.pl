# Done: show possible choices in TeX mode
# To do: display student answers and correct answers in TeX mode properly.
# To do: put jquery.nestable.js in a universal spot on every webwork server.

loadMacros("PGchoicemacros.pl",
"MathObjects.pl",
"dragndrop.pl"
);

sub _draggableSubsets_init {
	PG_restricted_eval("sub DraggableSubsets {new draggableSubsets(\@_)}");

}

package draggableSubsets;
# our @ISA = qw(Value::List);

sub new {
	my $self = shift; 
	my $class = ref($self) || $self;
	
	my $set = shift || []; 
	my $cosets = shift || []; 
	my $default_indices = shift || [];
	
	my $numProvided = scalar(@$set);
	my @order = main::shuffle($numProvided);
	my @unorder = main::invert(@order);

	my $shuffled_set = [ map {$set->[$_]} @order ];
	
	warn main::pretty_print [ @order ];
	warn main::pretty_print $set;
	warn main::pretty_print $shuffled_set;
	
	warn main::pretty_print $default_indices;
	my @shuffled_defaults = ();
	if (@$default_indices) {
		for my $default (@$default_indices) {
			my @shuffled_default = map {$order[$_]} @$default;
			push(@shuffled_defaults, [ @shuffled_default ]);
		} 
	} else {
		@shuffled_defaults = ( [ 0..$numProvided-1 ] );
	}
	warn main::pretty_print [ @shuffled_defaults ];
	
	my $shuffled_defaults = [ @shuffled_defaults ];
	my $ans_input_id = main::NEW_ANS_NAME() unless $self->{ans_input_id};	
	my $dnd = new DragNDrop($ans_input_id, $shuffled_set, $shuffled_defaults, AllowNewBuckets => 1);	
	
	my $previous = $dnd->getPrevious;	
	warn main::pretty_print $previous;
	warn $previous; 
	if ($previous == []) {
		for my $default ( @shuffled_defaults ) {
			warn $default;
			$dnd->addBucket($default);
		}
	} else {
		warn $previous;
		my @matches = ( $previous =~ /(\(\d*(?:,\d+)*\))+/g );
		for(my $i = 0; $i < @matches; $i++) {
			my $match = @matches[$i] =~ s/\(|\)//gr;			
			my $removable = $i == 0 ? 0 : 1;
			my $indices = [ split(',', $match) ];
			warn main::pretty_print $indices;
			$dnd->addBucket($indices, '', removable => $removable);
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