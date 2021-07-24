# TODO: Implement Damerau–Levenshtein to accomodate transpositions

package levenshtein;

sub levenshtein {
    my @ar1 = split /$_[2]/, $_[0];
    my @ar2 = split /$_[2]/, $_[1];
    
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

sub adjacentDamerauLevenshtein {
    my @ar1 = split /$_[2]/, $_[0];
    my @ar2 = split /$_[2]/, $_[1];
    
    my @da = (0) x (@ar1 + @ar2);
    
    
}

1;
