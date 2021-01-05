unit module SuperMAIN;

our $VERSION = '0.1.4';

# Allow named variables at any location
PROCESS::<%SUB-MAIN-OPTS><named-anywhere> = True;

# Manipulate @args
sub ARGS-TO-CAPTURE(&main, @args --> Capture) is export {
    # Passthrough
    return &*ARGS-TO-CAPTURE(&main, @args) unless @args;

    my %args-rewritten = convert-space-separator(@args);
    my @args-new = match-to-signatures(
            %args-rewritten, &main.candidates.map(*.signature).list, @args
    );

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
    my @candidates;
    push @candidates, rewrite-args-with-pairs(%rewritten-args<args>);
    my @combinations = %rewritten-args<maybe-boolean-idx>.combinations;
    for @combinations -> $c {
        next if $c.elems == 0;
        my @candidate = %rewritten-args<args>.clone;
        my Int $move-right = 0;
        for $c.list -> $idx {
            my @parts = @candidate[$idx + $move-right].split('=',2);
            my $named-bool = @parts[0];
            my $positional = @parts[1];
            @candidate.splice: $idx + $move-right, 1, ($named-bool, $positional);
            $move-right++;
        }

        # Replace key=value by Pairs so we can match signatures later on
        push @candidates, rewrite-args-with-pairs(@candidate);
    }

    return @candidates;
}

# create-aliases-for-signature create a Hash with the auto-aliases as keys and
# full names as values.
sub create-aliases-for-signature(Signature $sig --> Hash) {
    my (%aliases, @to-shorten, @reserved);

    for $sig.params -> $p {
        next unless $p.named;
        push @reserved: | $p.named_names;
        if $p.named_names.elems == 1 {
            push @to-shorten: |$p.named_names;
        }
    }

    for @to-shorten.values -> $pname {
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

# match-to-signatures matches the rewritten @args to signatures and returned a
# valid @arg is it matches with a signature. If nothing matches, the original
# args is returned.
sub match-to-signatures(%args-rewritten, List $signatures, @args-orig --> Array) {
    my %aliases; # Key: Signature, Value: Hash with alias as key & param as value.

    my @args-variations = create-args-variations-with-pairs(%args-rewritten);
    for @args-variations -> $v {
        # Short circuit if a signature already matches
        return rewrite-args-as-cli($v.Array) if $v ~~ any $signatures;
        my @args-full-paramnames = $v.list;
        for $signatures.list -> $s {
            %aliases = create-aliases-for-signature($s);
            for $v.kv -> $i, $p {
                if $p ~~ Pair {
                    if  (%aliases{$p.key} :exists) {
                        @args-full-paramnames[$i] = %aliases{$p.key} => $p.value;
                    }
                    next;
                }
                if $p.starts-with('-') { # boolean named param
                    my $key = $p.subst(/^\-+/, '');
                    if (%aliases{$key} :exists) {
                        @args-full-paramnames[$i] = %aliases{$key}
                    }
                    next;
                }
            }
            return rewrite-args-as-cli(@args-full-paramnames)
                if @args-full-paramnames ~~ $s;
        }
    }

    return @args-orig; # already in param=value format instead of Pairs
}

# rewrite-args-as-cli rewrites an args with Pairs to the CLI format of
# param=value.
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

# rewrite-args-with-pairs rewrites an args in CLI format of
# param=value to Pairs.
sub rewrite-args-with-pairs(@args --> Array) {
    my @args-new;
    for @args -> $a {
        if $a.starts-with('-') {
            my ($key, $value);
            if $a.contains('=') {
                my @parts = $a.split('=',2);
                $key   = @parts[0].subst(/^\-+/, '');
                $value = @parts[1];
            } else { # boolean named parameter
                $key = $a.subst(/^\-+/, '');
                $value = True;
            }
            push @args-new: $key => $value;
        } else {
            push @args-new: $a;
        }
    }
    return @args-new;
}