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
	# my %options = (
	# 	SourceLabel => "Choose from these sentences:",
	# 	TargetLabel => "Your Proof:",
	# 	# id => "$main::PG->{QUIZ_PREFIX}P$n",
	# 	@_
	# );
	
	my $numProvided = scalar(@$set);
	my @order = main::shuffle($numProvided);
	my @unorder = main::invert(@order);

	my $shuffled_set = [ map {$set->[$_]} @order ];
	# warn main::pretty_print $shuffled_lines;
	
	my $ans_input_id = main::NEW_ANS_NAME() unless $self->{ans_input_id};
	warn $ans_input_id;
	
	my $dnd = new DragNDrop($ans_input_id, AllowNewBuckets => 1);
	
	my $previous = $dnd->getPrevious;
	
	if ($previous eq "") {
		$dnd->addBucket($shuffled_set, '', '');
	} else {
		my @matches = ( $previous =~ /(\(\d*(?:,\d+)*\))+/g );
		for(my $i = 0; $i < @matches; $i++) {
			my $match = @matches[$i] =~ s/\(|\)//gr;
			# warn $match;
			my $removable = $i == 0 ? 0 : 1;
			warn main::pretty_print [ map{ $shuffled_set->[$_] } split(',', $match) ];
			$dnd->addBucket([ map{ $shuffled_set->[$_] } split(',', $match) ], '', removable => $removable);
		}
	}
		
	my @shuffled_cosets_array = ();
	
	warn main::pretty_print $cosets;
	for my $coset ( @$cosets ) {
		my @shuffled_coset = map {$unorder[$_]} @$coset;
		warn main::pretty_print [ @shuffled_coset ];
		push(@shuffled_cosets_array, main::Set(join(',', @shuffled_coset)));
	}
	# my $shuffled_cosets_string = join(',', @shuffled_cosets_array);
	# warn main::pretty_print $shuffled_cosets_string;
	my $shuffled_cosets = main::List(@shuffled_cosets_array);
	warn main::pretty_print $shuffled_cosets;
			
	$self = bless {
		set => $set,
		shuffled_set => $shuffled_set,
		numProvided => $numProvided,
		order => \@order, 
		unordered => \@unorder,
		shuffled_cosets => $shuffled_cosets,
		ans_input_id => $ans_input_id,
		dnd => $dnd,
		%options,
	}, $class;
	
	return $self;
}

sub Print {
	my $self = shift;
	warn main::pretty_print 'testing';
	warn $self->{dnd}->getPrevious;
	
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