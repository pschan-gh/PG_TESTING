package levenshtein;

sub levenshtein {
    my @ar1 = split /$_[2]/, $_[0];
    my @ar2 = split /$_[2]/, $_[1];
    # initialize  @dist = ( [0,1,..,n], [1], [2], ..., [m] )
    my @dist = ([0 .. @ar2]);
    $dist[$_][0] = $_ for (1 .. @ar1);

    for my $i (0 .. $#ar1) {
        for my $j (0 .. $#ar2) {
            $dist[$i+1][$j+1] = main::min($dist[$i][$j+1] + 1, $dist[$i+1][$j] + 1,
            $dist[$i][$j] + ($ar1[$i] ne $ar2[$j]) );
        }
    }
    main::min(1, $dist[-1][-1]/(@ar1));
}

sub levenshtein_cmp {
    my $self = shift;
    
    my $ans = new AnswerEvaluator;

    my $proof = $self->{proof};
    my $proof2 = $self->{proof2};

    $ans->ans_hash(
	type => "List",
	correct_ans => $proof,
	correct_value => $proof,
	);

    $ans->install_evaluator(sub {
        my $student = shift;
                
        $student->{original_student_ans} = (defined $student->{original_student_ans})? $student->{original_student_ans} : '';
    
    
        my $answer_value = $student->{original_student_ans};
            
        $answer_value =~ s/P[0-9,]-//g;
        $proof =~ s/P[0-9,]-//g;
        $proof2 =~ s/P[0-9,]-//g;

        my $dist = levenshtein($proof, $answer_value, ",");
        my $dist2 = levenshtein($proof2, $answer_value, ",");
        
        my $dist =  main::min($dist, $dist2);
        my $score = 1 - $dist;
    
        my @line = $self->lines; my @order = $self->order;
        my $student_ans = $student->{original_student_ans};
        $student_ans =~ s/$self->{id}-//g;
        my @ans_array = @line[map {@order[$_]} split(/,/,$student_ans)];
        
        my $ans_hash = new AnswerHash(
        'score'=> $score,
        'correct_ans'=> $self->{proof},
        'student_ans'=>'(see preview)',
        'original_student_ans' => $student->{original_student_ans},
        'type' => 'List',
        'ans_message'=> "Partial Credit $score",
        'preview_text_string'=>'',
        'preview_latex_string' => "\\begin{array}{l}\\text{" . join("}\\\\\\text{", @ans_array) . "}\\end{array}",
        );
        return $ans_hash;
    }
    );
    return $ans;

}
