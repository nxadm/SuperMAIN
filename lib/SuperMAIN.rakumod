unit module SuperMAIN;

# Allow named variables at any location
PROCESS::<%SUB-MAIN-OPTS><named-anywhere> = True;

# Allow space separated named parameters
sub ARGS-TO-CAPTURE(&main, @args --> Capture) is export {
    # Early exit, passthrough function
    return &*ARGS-TO-CAPTURE(&main, @args) unless @args;

    # %args-rewritten<args> rewrite @args allowing spaces for named params values
    # %args-rewritten<maybe-boolean-idx> keeps the indices of parameters that
    # may be boolean, and possibly incorrectly joined with a positional parameter
    # as a value.
    my %args-rewritten = rewrite-separator(@args);

    # When multi is used for MAINs, &main is a proto and to the matched MAIN.
    # We need to retrieve all the candidates to find the matching signature.
    # Boolean parameters joined with a value are fixed here.
    my @args-new = rewrite-with-autoalias(
            &main.candidates.map(*.signature).list, %args-rewritten
    );

    return &*ARGS-TO-CAPTURE(&main, @args-new);
}

sub create-aliases(Signature $sig --> Hash) {
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

sub rewrite-separator(@args --> Hash) {
    my (%response, @args-new, @maybe-boolean-idx);
    my $prev-arg = "";
    my Bool $prev-named;
    for @args -> $a {
        given True {
            # Passthrough --param=value named parameter
            when $a.starts-with('-') && $a.contains('=') {
                @args-new.push: $a;
                $prev-arg = "";
                $prev-named = True;
            }
            # Named parameter with no value attached
            when $a.starts-with('-') {
                # Parameter part of a "--param value" construction
                $prev-arg = $a;
                $prev-named = True;
            }
            # Value of named parameter of a positional in a confusing place
            when $prev-arg ne "" {
                if $prev-named {
                    @maybe-boolean-idx.push: @args.new.elems;
                    @args-new.push: "$prev-arg=$a";
                }
                $prev-arg = "";
                $prev-named = False;
            }
            # Passthrough positional parameters
            default {
                @args-new.push: $a;
                $prev-arg = "";
                $prev-named = False;
            }
        }
    }

    if @args-new.defined { %response<args> = @args-new; }

    if @maybe-boolean-idx.defined {
        %response<maybe-boolean-idx> = @maybe-boolean-idx;
    }

    return %response;
}

sub rewrite-with-autoalias(List $signatures, %rewritten-args --> Array) {
    my %aliases; # Key: Signatures, Value: Hash of alias as key and param as value.
    my @signatures = $signatures.Array;
    # Needed for smart matching the signature
    my @args-pairs = rewrite-with-pairs(%rewritten-args);


    # Short circuit if a signature already matches
    for @signatures -> $s {
        if @args-pairs ~~ $s {
            return @args
        }
        %aliases{$s} = create-aliases($s);
    }

    # Rewrite args
    for @signatures -> $s {
        my @args-tmp = @args-pairs.clone;
        my Bool $changed = False;
        for @args-pairs.kv -> $i, $a {
            if $a ~~ Pair && (%aliases{$s}{$a.key} :exists) {
                @args-tmp[$i] = %aliases{$s}{$a.key} => $a.value;
                $changed = True;
            }
        }

        if $changed {
            return rewrite-as-cli(@args-tmp);
        }
    }

    return @args;
}

sub rewrite-with-pairs(%rewritten-args --> Array) {
    my @candidates;
    push @candidates, %rewritten-args<args>;

    if %rewritten-args<maybe-boolean-idx> :exists {
        for %rewritten-args<maybe-boolean-idx> -> $idx {
            my @candidate = %rewritten-args<args>.clone;
            my @parts = @candidate[$idx]
            # Create list of variations of split params
        }
    }

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
    return @args-new
}

sub rewrite-as-cli(@args --> Array) {
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