unit module SuperMAIN;

# Allow named variables at any location
PROCESS::<%SUB-MAIN-OPTS><named-anywhere> = True;

# Allow space separated named parameters
sub ARGS-TO-CAPTURE(&main, @args --> Capture) is export {
    # Passthrough
    return &*ARGS-TO-CAPTURE(&main, @args) unless @args;

    my %args-rewritten = convert-space-separator(@args);
    say %args-rewritten.raku;

    # When multi is used for MAINs, &main is a proto and to the matched MAIN.
    # We need to retrieve all the candidates to find the matching signature.
    my @args-new = match-to-signatures(
            %args-rewritten, &main.candidates.map(*.signature).list
    );
    say @args-new.raku;

    return &*ARGS-TO-CAPTURE(&main, @args-new);
}

# convert-space-separator rewrites @args allowing spaces for named parameter
# values. The returned hash has 2 keys:
# - args: an array of the rewritten @args.
# - maybe-boolean-idx: array of indices of the rewritten @args keeps for
# incorrect parameter=value combinations that may be the combination of a
# boolean named and a positional parameter (that must be split).
sub convert-space-separator(@args --> Hash) {
    my (%args-rewritten, @args-new, @maybe-boolean-idx);
    my $prev-named = "";

    for @args -> $a {
        given True {
            # Passthrough --param=value named parameter
            when $a.starts-with('-') && $a.contains('=') {
                @args-new.push: $a;
                $prev-named = "";
            }
            # Named parameter with no value attached with '='.
            when $a.starts-with('-') {
                if $prev-named ne "" {
                    @args-new.push: $prev-named; # boolean named parameter
                }

                $prev-named = $a;
            }
            # Not a named parameter (no starting '-').
            when $prev-named ne "" {
                # it may be a positional after a named boolean
                @maybe-boolean-idx.push: @args-new.elems;
                @args-new.push: "$prev-named=$a";
                $prev-named = "";
            }
            # Positional parameters
            default {
                @args-new.push: $a;
                $prev-named = "";
            }
        }
    }
    @args-new.push: $prev-named if $prev-named ne '';


    %args-rewritten<args> = @args-new;
    %args-rewritten<maybe-boolean-idx> = @maybe-boolean-idx;
    return %args-rewritten;
}

sub match-to-signatures(%args-rewritten, List $signatures --> Array) {
    my @args;
    my @args-pairs = create-args-variations-with-pairs(%args-rewritten);
    return @args;
}

sub create-args-variations-with-pairs(%rewritten-args --> Array) {
    # Creats @args for all the possible combinations
    my @candidates;

    my @combinations = %rewritten-args<maybe-boolean-idx>.combinations;
    say "COMBINATIONS: " ~ @combinations.raku;
    for @combinations -> $c {
        my @candidate = %rewritten-args<args>.clone;
        my Int $move-right = 0;
        for $c.Array -> $idx {
            my @parts = @candidate[$idx].split('=');
            my $named-bool = @parts[0].subst(/^\-+/, '');
            my $positional = @parts[1..*-1].join('');
            @candidate.splice: $idx + $move-right, 1, ($named-bool, $positional);
            $move-right++;
        }
        push @candidates, @candidate;
    }

    say @candidates.raku;
#
#    # Args as is after space separator conversion
#    push @candidates, %rewritten-args<args>;
#
#    if %rewritten-args<maybe-boolean-idx>.defined {
#        for %rewritten-args<maybe-boolean-idx> -> $idx {
#            my @candidate = %rewritten-args<args>.clone;
#            my @parts = @candidate[$idx].split('=');
#            my $named-bool = @parts[0].subst(/^\-+/, '');
#            my $positional = @parts[1..*-1].join('');
#    }
#}
#
#        my @args-new;
#        for @args -> $a {
#            if $a.starts-with('-') && $a.contains('=') {
#                my @parts = $a.split('=');
#                my $key   = @parts[0].subst(/^\-+/, '');
#                my $value = @parts[1 .. *-1].join('');
#                push @args-new: $key => $value;
#                next;
#            }
#    push @args-new: $a;
#        }
    return @candidates;
}


sub create-aliases-for-signature(Signature $sig --> Hash) {
    my (%aliases, @to-shorten, @reserved);

    for $sig.params -> $p {
        next unless $p.named;
        push @reserved: | $p.named_names;
        if $p.named_names.elems == 1 {
            push @to-shorten: |$p.named_names;
        }
    }

    for @to-shorten.kv -> $idx, $pname {
        my @other-params   = @to-shorten.grep(none $pname);
        my @other-reserved = @reserved.grep(none $pname);
        my @chars = |$pname.comb;
        loop (my $i = 0; $i < @chars.elems; $i++) {
            my $alias = substr($pname, 0..$i);
            my @existing = (@other-params, @other-reserved).flat;
            if $alias ne $pname && ! grep { .starts-with($alias) }, @existing  {
                %aliases{$alias} = $pname;
                last;
            }
        }
    }

    return %aliases;
}


#
#sub rewrite-with-autoalias(List $signatures, %rewritten-args --> Array) {
#    my %aliases; # Key: Signatures, Value: Hash of alias as key and param as value.
#    my @signatures = $signatures.Array;
#    # Needed for smart matching the signature
#    my @args-pairs = rewrite-with-pairs(%rewritten-args);
#
#
#    # Short circuit if a signature already matches
#    for @signatures -> $s {
#        if @args-pairs ~~ $s {
#            return @args
#        }
#        %aliases{$s} = create-aliases($s);
#    }
#
#    # Rewrite args
#    for @signatures -> $s {
#        my @args-tmp = @args-pairs.clone;
#        my Bool $changed = False;
#        for @args-pairs.kv -> $i, $a {
#            if $a ~~ Pair && (%aliases{$s}{$a.key} :exists) {
#                @args-tmp[$i] = %aliases{$s}{$a.key} => $a.value;
#                $changed = True;
#            }
#        }
#
#        if $changed {
#            return rewrite-as-cli(@args-tmp);
#        }
#    }
#
#    return @args;
#}
#
#sub rewrite-with-pairs(%rewritten-args --> Array) {
#    my @candidates;
#    push @candidates, %rewritten-args<args>;
#
#    if %rewritten-args<maybe-boolean-idx> :exists {
#        for %rewritten-args<maybe-boolean-idx> -> $idx {
#            my @candidate = %rewritten-args<args>.clone;
#            my @parts = @candidate[$idx]
#            # Create list of variations of split params
#        }
#    }
#
#    my @args-new;
#    for @args -> $a {
#        if $a.starts-with('-') && $a.contains('=') {
#            my @parts = $a.split('=');
#            my $key   = @parts[0].subst(/^\-+/, '');
#            my $value = @parts[1 .. *-1].join('');
#            push @args-new: $key => $value;
#            next;
#        }
#        push @args-new: $a;
#    }
#    return @args-new
#}
#
#sub rewrite-as-cli(@args --> Array) {
#    my @args-new;
#    for @args -> $a {
#        if $a ~~ Pair {
#            push @args-new: '--' ~ $a.key ~ '=' ~ $a.value;
#            next;
#        }
#        push @args-new: $a;
#    }
#    return @args-new
#}