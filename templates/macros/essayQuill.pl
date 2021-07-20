loadMacros("PGessaymacros.pl");

sub _essayQuill_init {

    PG_restricted_eval("sub EssayQuill {new essayQuill(\@_)}");    
    my $courseHtmlUrl = $envir{htmlURL};
    # my $list_string = join ',' , map { qq/"$_"/ }  @{$self->{choices}};
    main::HEADER_TEXT(main::MODES(TeX=>"", HTML=><<"END_SCRIPTS"));
    <link rel="stylesheet" src="$courseHtmlUrl/essayquill/learnosity/mathquill.css"/>    
    <script type="text/javascript" src="$courseHtmlUrl/essayquill/learnosity/mathquill.js"></script>
    <link rel="stylesheet" href="$courseHtmlUrl/essayquill/essayquill.css"/>
    <script type="text/javascript" src="$courseHtmlUrl/essayquill/essayquill.js"></script>
    <script>
    var MQ = MathQuillMatrix.getInterface(2);
    </script>
    <style>
    table.mq-non-leaf > tbody > tr > td {
        padding:5px;
        border: solid 1px #bbb;
    }
    .mq-non-leaf :not(.mq-supsub, .mq-scaled){
        vertical-align:middle !important;
    }
    #editor {
        float:left;
        margin-left:0px;
        width:90%;
        height:20em;
        overflow-y:auto;
        border: solid 2px #ddd;
        font-family:serif;
        font-size:larger;
        padding:1em;
    }
    .mathbox, .mq-editable-field {
        border: none !important;
    }

    </style>
END_SCRIPTS
}

package essayQuill;

sub new {
    my $self = shift; my $class = ref($self) || $self;
    my $choices = shift || [];
    
    $self = bless { 
        choices => $choices,
    }, $class;
    return $self;
}

sub choices_text {
    my $self = shift;
    my $list = $self->{choices};
    my $output = join ', ', map { qq/$_/ } @{$list};
    return $output;
}

sub Print {
    my $self = shift;    
    
    if ($main::displayMode ne "TeX") {
        return 'ALLOWED <span id="authorized_words">'.$self->choices_text().'</span>        
        <div style="width:95%;height:auto;position:relative;overflow-x:auto"> 
            Press "back tick" $BBOLD ` $EBOLD to <input type="button" class="btn" id="mathquill" value="Insert Math Symbols" style="margin-top:5px"/>, press again to <input type="button" class="btn" id="exit_mathquill" value="Exit Math Box" style="margin-top:5px"/>.
            $BR
            Before submitting your answer, click on the $BBOLD Export to LaTeX $EBOLD button first.
            $BR
            <!-- Matrix mode: $BBOLD Shift-Spacebar $EBOLD to add column, $BBOLD Shift-Enter $EBOLD to add row. $BBOLD Backspace $EBOLD on a cell in an empty row/column deletes the row/column. -->
            <div id="editor" style="height:35em" contenteditable="false">
                <div class="text" contenteditable>  </div>
            </div></div>
            <div style="clear:left">
                <a class="btn" onclick="latexGen();">Export to LaTeX</a>
            </div>(The content below is what will actually be submitted.)<br/>
        '.&main::essay_box();
    }
    
}

sub cmp {
    my $self = shift;
    return &main::essay_cmp();
}

1;
