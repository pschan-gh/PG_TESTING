# Done: show possible choices in TeX mode
# To do: fix css clash for <ul> between draggableProof.pl and the webwork instructor tools menu.
# To do: display student answers and correct answers in TeX mode properly.
# To do: get the drag and drop features in draggableProof.pl to work on iPad using jquery.ui.touch-punch.min.js and also put this js library in a universal spot on every webwork server.

loadMacros(
"PGchoicemacros.pl",
);

sub _draggableProof2inf_init {
  PG_restricted_eval("sub DraggableProof2inf {new draggableProof2inf(\@_)}");

  $courseHtmlUrl = $envir{htmlURL};

  main::POST_HEADER_TEXT(main::MODES(TeX=>"", HTML=><<"  END_SCRIPTS"));
<!--  The next to scripts may need to be included on older versions of WeBWoRK (before 2.9 or so.
    <script type="text/javascript" src=" https://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js"></script>
    <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jqueryui/1.8.18/jquery-ui.min.js"></script>
-->

<script src="$courseHtmlUrl/js/jquery.nestable.js"></script>

<script>
  function _nestableUpdate (e) {
      var dd = e.length ? e : \$(e.target);
      var ans = dd["0"].getAttribute("data-ans");
      var li_tags = dd["0"].getElementsByTagName("li");
      var list = [];
      for (var i = 0, n = li_tags.length; i < n; i++) {
          list.push(li_tags[i].id);
      }
      \$("#"+ans).val(list.join(","));
  }
</script>
  END_SCRIPTS
}

package draggableProof2inf;

my $n = 0;  # number of sortable lists so far

sub new {
  $n++;
  my $self = shift; my $class = ref($self) || $self;
  my $proof = shift || {};
  my $proof2 = shift || {};
  # my ($proof, $proof2, $extra) = @_;
  # my $extra = shift || [];

  my @aux =

  my %options = (
    SourceLabel => "Choose from these sentences:",
    TargetLabel => "Your Proof:",
    id => "P$n",
    orig_proof => $proof->{statements},
    orig_proof2 => $proof2->{statements}
    # @_
    # ($proof, $proof2)
  );

  # my $lines = [@$proof, @$proof2, @$extra];
  # warn main::pretty_print $proof;
  # warn main::pretty_print $proof2;

  my $lines = [ @{ $proof->{statements}}, @{ $proof2->{statements} }];
  my $numNeeded = scalar(@{ $proof->{statements} });
  my $numNeeded2 = scalar(@{ $proof2->{statements} });
  my $numProvided = scalar(@$lines);
  my @order = main::shuffle($numProvided);
  my @unorder = main::invert(@order);

  my @cob = ();
  my @vec_array;
  for (@order) {
      @vec_array = (0) x $numProvided;
      $vec_array[$_] = 1;
      push @cob, '['.join(',' , @vec_array).']';
  }
  main::Context("Matrix");
  my $COB = main::Matrix('['.join(',', @cob).']');

  # warn main::pretty_print $COB;

  my @row = (0) x $numNeeded2;

  my @INF = ();
  for (@{$proof->{inf}}) {
      my @aux = @{ $_ };
      push @aux, @row;
      push @INF, \@aux;
  }
  my @zero_matrix_array = zero_matrix_array($numNeeded2, $numProvided);
  # warn main::pretty_print @zero_matrix_array;
  my $padded_INF = main::Matrix((@INF, @zero_matrix_array));
  # warn main::pretty_print $padded_INF;

  my @row = (0) x $numNeeded;

  my @INF2 = ();
  for (@{$proof2->{inf}}) {
      my @aux = @row;
      push @aux, @{ $_ };
      push @INF2, \@aux;
  }
  my @zero_matrix_array = zero_matrix_array($numNeeded, $numProvided);
  my $padded_INF2 = main::Matrix((@zero_matrix_array, @INF2));
  my $shuffled_INF = $COB * $padded_INF * ($COB->inverse);
  my $shuffled_INF2 = $COB * $padded_INF2 * ($COB->inverse);

  $self = bless {
    lines => $lines,
    numNeeded => $numNeeded, numNeeded2 => $numNeeded2, numProvided => $numProvided,
    order => \@order, unordered => \@unorder,
    proof => "$options{id}-".join(",$options{id}-",@unorder[0..$numNeeded-1]),
    proof2 => "$options{id}-".join(",$options{id}-",@unorder[$numNeeded..$numNeeded + $numNeeded2-1]),
    inf => $shuffled_INF,
    inf2 => $shuffled_INF2,
    %options,
  }, $class;
  $self->AnswerRule;
  $self->ScriptAndStyles;
  $self->GetAnswer;
  return $self;
}

sub lines {my $self = shift; return @{$self->{lines}}}
sub numNeeded {(shift)->{numNeeded}}
sub numProvided {(shift)->{numProvided}}
sub order {my $self = shift; return @{$self->{order}}}
sub unorder {my $self = shift; return @{$self->{unorder}}}

sub ScriptAndStyles {
  my $self = shift; my $id = $self->{id};

  main::POST_HEADER_TEXT(main::MODES(TeX=>"", HTML=><<"  SCRIPT_AND_STYLE"));
    <script type="text/javascript">
      \$(document).ready(function() {
          \$("#nestable-$id-source").nestable({
              group: "$id",
              maxDepth: 1,
              scroll: true,
              callback: _nestableUpdate
          });
          \$("#nestable-$id-source").on('lostItem', _nestableUpdate);
          \$("#nestable-$id-target").nestable({
              group: "$id",
              maxDepth: 1,
              scroll: true,
              callback: _nestableUpdate
          });
          \$("#nestable-$id-target").on('lostItem', _nestableUpdate);
      });
    </script>

    <style type="text/css">
    .nestable-$id-container {
        width: 350px;
        float: left;
        margin: 10px;
        padding: 0;
        color: #000000;
        border:1 px solid #388E8E;
        text-align: center;
    }
    .nestable-label {
        margin: 10px 0 10px 0;
    }
    .dd, .dd-list, .dd-item {
        display: block;
        position: relative;
        list-style: none;
        margin: 0;
        padding: 0;
        min-height: 30px;
    }
    .dd-empty, .dd-handle, .dd-placeholder {
        display: block;
        position: relative;
        margin: 0 10px 10px 10px;
        padding: 4px;
        min-height: 30px;
        -moz-box-sizing: border-box;
        box-sizing: border-box;
    }
    .dd-handle {
        background: #F5DEB3;
        border: 1px solid #388E8E;
        -webkit-border-radius: 5px;
        border-radius: 5px;
        text-align: center;
    }
    .dd-handle:hover {
        cursor: pointer;
    }
    .dd-placeholder {
        background: #f2fbff;
        border: 1px dashed #b6bcbf;
        -webkit-border-radius: 5px;
        border-radius: 5px;
    }
    .dd-dragel {
        position: absolute;
        pointer-events: none;
        z-index: 9999;
    }
    .dd-dragel > .dd-item .dd-handle {
        margin-top: 0;
    }
    .dd-dragel .dd-handle {
        -webkit-box-shadow: 2px 4px 6px 0 rgba(0,0,0,.1);
        box-shadow: 2px 4px 6px 0 rgba(0,0,0,.1);
        opacity: 0.8;
    }
    </style>
  SCRIPT_AND_STYLE
}

sub AnswerRule {
  my $self = shift;
  my $rule = main::ans_rule(1);
  $self->{tgtAns} = ""; $self->{tgtAns} = $1 if $rule =~ m/id="(.*?)"/;
  $self->{srcAns} = $self->{tgtAns}."-src";
  main::RECORD_FORM_LABEL($self->{srcAns}); # use this for release 2.13 and comment out for develop
  #$main::PG->store_persistent_data;  # uncomment this for develop and releases beyond 2.13
  my $ext = main::NAMED_ANS_RULE_EXTENSION($self->{srcAns},1,answer_group_name=>$self->{srcAns}.'-src');
  main::TEXT( main::MODES(TeX=>"", HTML=>'<div style="display:none" id="Proof">'.$rule.$ext.'</div>'));
}

sub GetAnswer {
    my $self = shift; my $previous;

    # Retrieve the previous state of the right column.
    $previous = $main::inputs_ref->{$self->{tgtAns}} || "";
    $previous =~ s/$self->{id}-//g; $self->{previousTarget} = [split(/,/,$previous)];

    # Calculate the complement of the right column.
    my %prevTarget = map {$_ => 1} @{$self->{previousTarget}};
    my @diff = grep {not $prevTarget{$_}} (0..$self->{numProvided}-1);

    # If the previous state of the left column has been saved, use it. (This ensures that the tiles
    # in the left column are kept in the same order that the user had arranged them). If it has not
    # been saved, use the complement of the right column.
    $previous = $main::inputs_ref->{$self->{srcAns}} || "$self->{id}-".join(",$self->{id}-",@diff);
    $previous =~ s/$self->{id}-//g; $self->{previousSource} = [split(/,/,$previous)];
}

sub Print {
  my $self = shift;

  if ($main::displayMode ne "TeX") { # HTML mode

    return join("\n",
       '<div style="min-width:650px;">',
          $self->Source,
          $self->Target,
       '<br clear="all" />',
      '</div>'
    );

  } else { # TeX mode

    return join("\n",
          $self->Source,
          $self->Target,
    );

  }

}

sub Source {
  my $self = shift;
  return $self->Bucket("source",$self->{srcAns},$self->{SourceLabel},$self->{previousSource});
}

sub Target {
  my $self = shift;
  return $self->Bucket("target",$self->{tgtAns},$self->{TargetLabel},$self->{previousTarget});
}

sub Bucket {
  my $self = shift; my $id = $self->{id};
  my ($name,$ans,$label,$previous) = @_;

  if ($main::displayMode ne "TeX") { # HTML mode

    my @lines = ();
    push(@lines, '<div class="nestable-'.$id.'-container">',
      '<div class="nestable-label">'.$label.'</div>',
      '<div class="dd" id="nestable-'.$id.'-'.$name.'" data-ans="'.$ans.'">'
    );
    if (scalar @{$previous} > 0) {
      push(@lines, '<ol class="dd-list">');
      foreach my $i (@{$previous}) {
        push(@lines, '<li class="dd-item" id="'.$id.'-'.$i.'"><div class="dd-handle">'.$self->{lines}[$self->{order}[$i]].'</div></li>');
      }
      push(@lines, '</ol>');
    }
    push(@lines,
      '</div>',
      '</div>'
    );
    return join("\n",@lines);

  } else { # TeX mode

    if (@{$previous}) { # array is nonempty
      my @lines = ('\\begin{itemize}');
      foreach my $i (@{$previous}) {
        push(@lines,'\\item '.$self->{lines}[$self->{order}[$i]] )
      }
      push(@lines,'\\end{itemize}');
      return join("\n",@lines);
    } else {
      return '';
    }
  }

}

sub cmp {
  # my $self = shift;
  # return main::str_cmp($self->{proof})->withPreFilter("erase")->withPostFilter(sub {$self->filter(@_)});
  my $self = shift;
  my $answer_evaluator = new AnswerEvaluator;

  my $proof = $self->{proof};
  my $proof2 = $self->{proof2};

  my $inf = $self->{inf};
  my $inf2 = $self->{inf2};

  my $numProvided = $self->{numProvided};

  $answer_evaluator->ans_hash(
  correct_ans => "Undefined",
  # @_,
  score => 0,
  );

  $answer_evaluator->install_evaluator(sub {
      my $rh_ans = shift;

      $student->{original_student_ans} = (defined $student->{original_student_ans})? $student->{original_student_ans} : '';

      my $answer_value = $rh_ans->{original_student_ans};
      $answer_value =~ s/P[0-9,]-//g;

      $proof =~ s/P[0-9,]-//g;
      $proof2 =~ s/P[0-9,]-//g;

      main::Context("Matrix");
      warn main::pretty_print $inf;
      warn main::pretty_print $inf2;

      my $total_inf = (row_of_ones($numProvided)*($inf*col_of_ones($numProvided)))->element(1, 1);
      my $total_inf2 = (row_of_ones($numProvided)*($inf2*col_of_ones($numProvided)))->element(1, 1);
      my @ans_indices = split(',' , $answer_value);
      my @vector_indices = map { elem_vector($_, $numProvided) } @ans_indices;

      my $inference_score = 0;
      for (my $j = 0; $j < scalar @vector_indices; $j++) {
          my $aux = 0;
          for (my $i = $j - 1; $i >= 0; $i--) { # reject gaps in the discourse
              my $product = (($vector_indices[$j]*$inf)*($vector_indices[$i]->transpose))->element(1, 1);
              if ($product > 0) {
                  $aux += $product;
              } else {
                  last;
              }
          }
          $inference_score += $aux;
          my $full_inference = main::Vector(col_of_ones($numProvided)) . main::Vector($inf*elem_vector($j, $numProvided));
          # warn $student_matches[$id_matches[$col]]." ".$aux." full inf: ".$full_inference;
          # if ($aux < $full_inference) {
          #     $result->{messages} .= "<br><font color=red>We don't follow why</font><b> "." "."</b> <font color=red>holds.</font></b>"
          # }
      }
      # warn $inference_score;

      my $inference_score2 = 0;
      for (my $j = 0; $j < scalar @vector_indices; $j++) {
          my $aux = 0;
          for (my $i = $j - 1; $i >= 0; $i--) { # reject gaps in the discourse
              my $product = (($vector_indices[$j]*$inf2)*($vector_indices[$i]->transpose))->element(1, 1);
              if ($product > 0) {
                  $aux += $product;
              } else {
                  last;
              }
          }
          $inference_score2 += $aux;
          my $full_inference = main::Vector(col_of_ones($numProvided)) . main::Vector($inf2*elem_vector($j, $numProvided));
          # warn $student_matches[$id_matches[$col]]." ".$aux." full inf: ".$full_inference;
          # if ($aux < $full_inference) {
          #     $result->{messages} .= "<br><font color=red>We don't follow why</font><b> "." "."</b> <font color=red>holds.</font></b>"
          # }
      }

      # warn $inference_score2;

      my $score = main::max($inference_score/$total_inf, $inference_score2/$total_inf2);

      my @line = $self->lines; my @order = $self->order;

      # my $correct = $ans->{correct_ans}; $correct =~ s/$self->{id}-//g;
      my $student_ans = $rh_ans->{original_student_ans};

      $student_ans =~ s/$self->{id}-//g;
      my @ans_array = @line[map {@order[$_]} split(/,/,$student_ans)];

      my $rh_hash = new AnswerHash(
      'score'=> $score,
      'correct_ans'=> '',
      'student_ans'=>'(see preview)',
       'original_student_ans' => $student_ans->{original_student_ans} || '',
      # 'type' => 'essay',
      # 'ans_message'=> "Partial Credit $score",
      'preview_text_string'=>'',
      );
      $rh_hash->{'preview_latex_string'} = "\\begin{array}{l}\\text{" . join("}\\\\\\text{", @ans_array) . "}\\end{array}";
      $rh_hash;
  }
  );
  return $answer_evaluator;
}


sub filter {
  my $self = shift; my $ans = shift;
  my @line = $self->lines; my @order = $self->order;
  my $correct = $ans->{correct_ans}; $correct =~ s/$self->{id}-//g;
  my $student = $ans->{student_ans}; $student =~ s/$self->{id}-//g;
  my @correct = @line[map {@order[$_]} split(/,/,$correct)];
  my @student = @line[map {@order[$_]} split(/,/,$student)];
  $ans->{preview_latex_string} = "\\begin{array}{l}\\text{".join("}\\\\\\text{",@student)."}\\end{array}";
  $ans->{student_ans} = "(see preview)";
  $ans->{correct_ans_latex_string} = "\\begin{array}{l}\\text{".join("}\\\\\\text{",@correct)."}\\end{array}";
  $ans->{correct_ans} = join("<br />",@correct);
  return $ans;
}

# elem_vector(m,n)    generates a row vector of length n, with 1 at
#                     (m+1)-position and 0 else where
sub elem_vector {
    main::Context("Matrix");
    my @vec_array = (0) x $_[1]; $vec_array[$_[0]] = 1;
    main::Matrix([@vec_array]);
}

# row_of_one(n)        generates a row vector of 1's of length n
sub row_of_ones { main::Context("Matrix"); main::Matrix([(1) x shift]) }
# row_of_zeroes(n)        generates a row vector of 0's of length n
sub row_of_zeroes { main::Context("Matrix"); main::Matrix([(0) x shift]) }

# col_of_one(n)        generates a column vector of 1's of length n
sub col_of_ones { main::Context("Matrix"); main::Matrix(row_of_ones($_[0]))->transpose }

# zero_matrix(m, n)     m x n zero matrix
sub zero_matrix_array{
    my ($m, $n) = @_;
    main::Context("Matrix");
    my @row = (0) x $n;
    my @matrix = ();
    for (1..$m){
        push @matrix, \@row;
    }
    # main::Matrix(@matrix);
    @matrix
}

1;
