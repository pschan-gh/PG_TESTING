# Done: show possible choices in TeX mode
# To do: display student answers and correct answers in TeX mode properly.
# To do: put jquery.nestable.js in a universal spot on every webwork server.

loadMacros("PGchoicemacros.pl",
"MathObjects.pl",
"dragndrop.pl"
);

sub _draggableProofModular_init {
	PG_restricted_eval("sub DraggableProofModular {new draggableProofModular(\@_)}");

}

package draggableProofModular;

sub new {
	my $self = shift; 
	my $class = ref($self) || $self;
	
	my $proof = shift || []; 
	my $extra = shift || [];	
	my %options = (
		SourceLabel => "Choose from these sentences:",
		TargetLabel => "Your Proof:",
		# id => "$main::PG->{QUIZ_PREFIX}P$n",
		@_
	);
	
	my $lines = [@$proof,@$extra];	
	my $numNeeded = scalar(@$proof);
	my $numProvided = scalar(@$lines);
	my @order = main::shuffle($numProvided);
	my @unorder = main::invert(@order);

	my $shuffled_lines = [ map {$lines->[$_]} @order ];
	# warn main::pretty_print $shuffled_lines;
	
	my $ans_input_id = main::NEW_ANS_NAME() unless $self->{ans_input_id};
	warn $ans_input_id;
	my $dnd = new DragNDrop($ans_input_id, AllowNewBuckets => 0);
	$dnd->addBucket($shuffled_lines, 'source', $options{'SourceLabel'});
	$dnd->addBucket([], 'target', $options{'TargetLabel'});
		
	$self = bless {
		lines => $lines,
		shuffled_lines => $shuffled_lines,
		numNeeded => $numNeeded, 
		numProvided => $numProvided,
		order => \@order, 
		unordered => \@unorder,
		proof => main::List(main::List(), main::List(@unorder[0..$numNeeded-1])),
		ans_input_id => $ans_input_id,
		dnd => $dnd,
		%options,
	}, $class;
	my $aux = $self->{proof};
	warn $aux;
	warn main::pretty_print $self->{proof}->value;
	return $self;
}

# sub lines {my $self = shift; return @{$self->{lines}}}
# sub numNeeded {(shift)->{numNeeded}}
# sub numProvided {(shift)->{numProvided}}
# sub order {my $self = shift; return @{$self->{order}}}
# sub unorder {my $self = shift; return @{$self->{unorder}}}

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
	return $self->{proof}->cmp(ordered => 1, removeParens => 0)->withPreFilter("erase")->withPostFilter(sub {$self->filter(@_)});
}

sub filter {
	my $self = shift; my $ans = shift;
		
	my @lines = @{$self->{lines}}; 
	my @order = @{$self->{order}};
	# my $correct = $ans->{correct_ans}; 
	my $student = $ans->{student_ans}; 	
	
	my @matches = ( main::List($ans->{student_ans})->string =~ /(\(\d*(?:,\s*\d+)*\)|\d+)/g );
	warn 'matches';
	warn main::pretty_print [ @matches ];
	my $actual_answer = $matches[1] =~ s/\(|\)|\s*//gr;
	
	$ans->{student_ans} = main::List(split(',', $actual_answer));
	
	@matches = ( main::List($ans->{correct_ans})->string =~ /(\(\d*(?:,\s*\d+)*\)|\d+)/g );
	my $correct = $matches[1] =~ s/\(|\)|\s*//gr;
	
	$ans->{correct_ans} = $correct;
	$ans->{original_student_ans} = $ans->{student_ans};
	$ans->{student_value} = $ans->{student_ans};
	$ans->{student_formula} = $ans->{student_ans};
	
	if ($ans->{correct_ans} eq $ans->{student_ans}) {
		$ans->{score} = 1;
	}
	
	my @correct = @lines[map {@order[$_]} split(/,/, $correct)];
	my @student = @lines[map {@order[$_]} split(',', $actual_answer =~ s/\(|\)|\s*//gr)];
	# 
	$ans->{student_ans} = "(see preview)";
	$ans->{correct_ans_latex_string} = "\\begin{array}{l}\\text{".join("}\\\\\\text{",@correct)."}\\end{array}";
	$ans->{correct_ans} = join("<br />",@correct);
	$ans->{preview_latex_string} = "\\begin{array}{l}\\text{".join("}\\\\\\text{",@student)."}\\end{array}";
	return $ans;
}
1;
