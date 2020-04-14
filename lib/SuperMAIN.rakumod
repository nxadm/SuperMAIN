unit module SuperMAIN;

# Allow named variables at any location
PROCESS::<%SUB-MAIN-OPTS><named-anywhere> = True;

# Allow space separated named parameters
sub ARGS-TO-CAPTURE(&main, @args --> Capture) is export {
    # Early exit, passthrough function
    return &*ARGS-TO-CAPTURE(&main, @args) unless @args;

    # Convert the args to what MAIN expects: allow spaced for named params
    my @args-new = rewrite-separator(@args);

    # When multi is used for MAINs, &main is a proto and to the matched MAIN.
    # We need to retrieve all the candidates to find the matching signature.
    # The signature in order to avoid
    @args-new = rewrite-with-autoalias(&main.candidates.map(*.signature).list, @args-new);

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

sub rewrite-separator(@args --> Array) {
    my @args-new;
    my $prev = "";
    for @args -> $a {
        given True {
            when $a.starts-with('-') && $a.contains('=') {
                # Passthrough --param=value named parameter
                @args-new.push: $a;
                $prev = "";
            }
            when $a.starts-with('-') {
                # Parameter part of a "--param value" construction
                $prev = $a;
            }
            when $prev ne "" {
                # Value part of a "--param value" construction
                @args-new.push: "$prev=$a";
                $prev = "";
            }
            default {
                # Passthrough leftover parameters
                @args-new.push: $a;
                $prev = "";
            }
        }
    }
    return @args-new
}

sub rewrite-with-autoalias(List $signatures, @args --> Array) {
    my %aliases; # Key: Signatures, Value: Hash of alias as key and param as value.
    my @signatures = $signatures.Array;
    # Needed for smart matching the signature
    my @args-pairs = rewrite-with-pairs(@args);

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

sub rewrite-with-pairs(@args --> Array) {
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