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

# create-args-variations-with-pairs create an Array of Arrays with all the
# possible args combinations to make sure named boolean parameters are not
# joined to a positional parameter as a value.
sub create-args-variations-with-pairs(%rewritten-args --> Array) {
    # Create @args for all the possible combinations
    my @candidates;
    my @combinations = %rewritten-args<maybe-boolean-idx>.combinations;
    for @combinations -> $c {
        next if $c.elems == 0;
        my @candidate = %rewritten-args<args>.clone;
        my Int $move-right = 0;
        for $c.list -> $idx {
            my @parts = @candidate[$idx + $move-right].split('=');
            my $named-bool = @parts[0].subst(/^\-+/, '');
            my $positional = @parts[1..*-1].join('');
            @candidate.splice: $idx + $move-right, 1, ($named-bool, $positional);
            $move-right++;
        }

        # Replace key=value by Pairs so we can match signatures later on
        push @candidates, rewrite-args-with-pairs(@candidate);
    }

    return @candidates;
}

sub match-to-signatures(%args-rewritten, List $signatures --> Array) {
    my @args;
    my %aliases; # Key: Signature, Value: Hash with alias as key & param as value.
    my @args-variations = create-args-variations-with-pairs(%args-rewritten);

    # Short circuit if a signature already matches
    for $signatures.list -> $s {
        for @args-variations -> $a {
            return $a.Array if $a.list ~~ $s;
        }
        # TODO: check if better PAIRS of cli
        %aliases{$s} = create-aliases-for-signature($s);
    }


    return @args;
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



sub rewrite-args-as-cli(@args --> Array) {
    my @args-new;
    for @args -> $a {
        if $a ~~ Pair {
            push @args-new: '--' ~ $a.key ~ '=' ~ $a.value;
            next;
        }
        push @args-new: $a;
    }
    return @args-new
}

sub rewrite-args-with-pairs(@args --> Array) {
    my @args-new;
    for @args -> $a {
        if $a.starts-with('-') && $a.contains('=') {
            my @parts = $a.split('=');
            my $key   = @parts[0].subst(/^\-+/, '');
            my $value = @parts[1 .. *-1].join('');
            push @args-new: $key => $value;
            next;
        }
        push @args-new: $a;
    }
    return @args-new;
}