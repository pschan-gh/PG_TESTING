# Done: show possible choices in TeX mode
# To do: display student answers and correct answers in TeX mode properly.
# To do: put jquery.nestable.js in a universal spot on every webwork server.

loadMacros("PGchoicemacros.pl",
"MathObjects.pl",
"levenshtein.pl",
"DragNDrop.pl"
);

sub _draggableProofModular_init {
	PG_restricted_eval("sub DraggableProofModular {new draggableProofModular(\@_)}");
}

package draggableProofModular;
# our @ISA = qw(Value::List);

sub new {
	my $self = shift; 
	my $class = ref($self) || $self;
	
	my $proof = shift || []; 
	my $extra = shift || [];	
	my %options = (
		SourceLabel => "Choose from these sentences:",
		TargetLabel => "Your Proof:",
		NumBuckets => 2,
		Levenshtein => 0,
		@_
	);
	
	my $lines = [@$proof,@$extra];	
	my $numNeeded = scalar(@$proof);
	my $numProvided = scalar(@$lines);
	my @order = main::shuffle($numProvided);
	my @unorder = main::invert(@order);

	my $shuffled_lines = [ map {$lines->[$_]} @order ];
	
	my $ans_input_id = main::NEW_ANS_NAME() unless $self->{ans_input_id};
	
	my $dnd;
	if ($options{NumBuckets} == 2) {
		$dnd = new DragNDrop($ans_input_id, $shuffled_lines, [{indices=>[0..$numProvided-1], label=>$options{'SourceLabel'}}, {indices=>[], label=>$options{'TargetLabel'}}], AllowNewBuckets => 0);
	} elsif($options{NumBuckets} == 1) {
		$dnd = new DragNDrop($ans_input_id, $shuffled_lines, [{indices=>[0..$numProvided-1], label=>$options{'TargetLabel'}}], AllowNewBuckets => 0);
	}
	
	my $proof = $options{NumBuckets} == 2 ? 
	main::List(main::List(@unorder[$numNeeded .. $numProvided - 1]), main::List(@unorder[0..$numNeeded-1]))
	: main::List('('.join(',', @unorder[0..$numNeeded-1]).')');
		
	$self = bless {
		lines => $lines,
		shuffled_lines => $shuffled_lines,
		numNeeded => $numNeeded, 
		numProvided => $numProvided,
		order => \@order, 
		unorder => \@unorder,
		proof => $proof,
		ans_input_id => $ans_input_id,
		dnd => $dnd,
		%options,
	}, $class;
	
	my $previous = $dnd->getPrevious;
	
	if ($previous eq "") {
		if ($self->{NumBuckets} == 2) {
			$dnd->addBucket([0..$numProvided-1], $options{'SourceLabel'});
			$dnd->addBucket([], $options{'TargetLabel'});
		} elsif ($self->{NumBuckets} == 1) {
			$dnd->addBucket([0..$numProvided-1], $options{'TargetLabel'});
		}
	} else {
		my @matches = ( $previous =~ /(\(\d*(?:,\d+)*\))+/g );
		if ($self->{NumBuckets} == 2) {
			my $indices1 = [ split(',', @matches[0] =~ s/\(|\)//gr) ];		
			$dnd->addBucket($indices1, $options{'SourceLabel'});		
			my $indices2 = [ split(',', @matches[1] =~ s/\(|\)//gr) ];
			$dnd->addBucket($indices2, $options{'TargetLabel'});
		} else {
			my $indices1 = [ split(',', @matches[0] =~ s/\(|\)//gr) ];
			$dnd->addBucket($indices1, $options{'TargetLabel'});
		}
	}
		
	return $self;
}
sub loadJS {
	my $self = shift;
	return $self->{dnd}->toHTML;
}

sub Print {
	my $self = shift;

	if ($main::displayMode ne "TeX") { # HTML mode
		return join("\n",
			'<div style="min-width:750px;">',
			$self->{dnd}->ans_rule,
			'<br clear="all" />',
			'</div>',
		);
	} else { # TeX mode
		return join("\n",
			$self->{dnd}->ans_rule,
		);
	}
}

sub cmp {
	my $self = shift;	
	if ($self->{Levenshtein} == 0) {
		return $self->{proof}->cmp(ordered => 1, removeParens => 1)->withPreFilter("erase")->withPostFilter(sub {$self->filter(@_)});
	} else {
		return $self->{proof}->cmp(ordered => 1, removeParens => 1)->withPreFilter("erase")->withPostFilter(sub {$self->levenshtein_filter(@_)});
	}
}

sub filter {
	my $self = shift; my $anshash = shift;
		
	my @lines = @{$self->{lines}}; 
	my @order = @{$self->{order}};
	
	my $actual_answer = $anshash->{student_ans} =~ s/\(|\)|\s*//gr;
	my $correct = $anshash->{correct_ans} =~ s/\(|\)|\s*//gr;
	
	if ($self->{NumBuckets} == 2) {
		my @matches = ( $anshash->{student_ans} =~ /(\(\d*(?:,\s*\d+)*\)|\d+)/g );
		$actual_answer = @matches == 2 ? $matches[1] =~ s/\(|\)|\s*//gr : '';
		
		@matches = ( $anshash->{correct_ans} =~ /(\(\d*(?:,\s*\d+)*\)|\d+)/g );
		$correct = @matches == 2 ? $matches[1] =~ s/\(|\)|\s*//gr : '';
		
		$anshash->{correct_ans} = main::List($correct); # change to main::Set if order does not matter
		$anshash->{student_ans} = main::List($actual_answer); # change to main::Set if order does not matter
		$anshash->{original_student_ans} = $anshash->{student_ans};
		$anshash->{student_value} = $anshash->{student_ans};
		$anshash->{student_formula} = $anshash->{student_ans};
		
		if ($anshash->{correct_ans} eq $anshash->{student_ans}) {
			$anshash->{score} = 1;
		}
	}
	
	my @correct = @lines[map {@order[$_]} split(/,/, $correct)];
	my @student = @lines[map {@order[$_]} split(',', $actual_answer)];
	 
	$anshash->{student_ans} = "(see preview)";
	$anshash->{correct_ans_latex_string} = "\\begin{array}{l}\\text{".join("}\\\\\\text{",@correct)."}\\end{array}";
	$anshash->{correct_ans} = join("<br />",@correct);
	$anshash->{preview_latex_string} = "\\begin{array}{l}\\text{".join("}\\\\\\text{",@student)."}\\end{array}";
	
	return $anshash;
}

sub levenshtein_filter {
	my $self = shift; my $anshash = shift;
		
	my @lines = @{$self->{lines}}; 
	my @order = @{$self->{order}};
	
	my $actual_answer = $anshash->{student_ans} =~ s/\(|\)|\s*//gr;
	my $correct = $anshash->{correct_ans} =~ s/\(|\)|\s*//gr;
	
	if ($self->{NumBuckets} == 2) {
		my @matches = ( $anshash->{student_ans} =~ /(\(\d*(?:,\s*\d+)*\)|\d+)/g );
		$actual_answer = @matches == 2 ? $matches[1] =~ s/\(|\)|\s*//gr : '';
		
		@matches = ( $anshash->{correct_ans} =~ /(\(\d*(?:,\s*\d+)*\)|\d+)/g );
		$correct = @matches == 2 ? $matches[1] =~ s/\(|\)|\s*//gr : '';
		
		$anshash->{correct_ans} = main::List($correct); # change to main::Set if order does not matter
		$anshash->{student_ans} = main::List($actual_answer); # change to main::Set if order does not matter
		$anshash->{original_student_ans} = $anshash->{student_ans};
		$anshash->{student_value} = $anshash->{student_ans};
		$anshash->{student_formula} = $anshash->{student_ans};
		
	}
	
	$anshash->{score} = 1 - levenshtein::levenshtein($correct, $actual_answer, ',');
	 
	my @correct = @lines[map {@order[$_]} split(/,/, $correct)];
	my @student = @lines[map {@order[$_]} split(',', $actual_answer)];
	$anshash->{student_ans} = "(see preview)";
	$anshash->{correct_ans_latex_string} = "\\begin{array}{l}\\text{".join("}\\\\\\text{",@correct)."}\\end{array}";
	$anshash->{correct_ans} = join("<br />",@correct);
	$anshash->{preview_latex_string} = "\\begin{array}{l}\\text{".join("}\\\\\\text{",@student)."}\\end{array}";
	
	return $anshash;
}
1;
