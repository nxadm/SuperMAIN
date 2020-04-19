#!/usr/bin/env raku
use lib 'lib';
use SuperMAIN;

sub MAIN($positional1, $positional2,
        :n(:$named1), :$named2,
        Bool :$bool1, Bool :$bool2) {
    say "POSITIONAL1: $positional1" if $positional1.defined;
    say "POSITIONAL2: $positional2" if $positional2.defined;
    say "NAMED1: $named1"           if $named1.defined;
    say "NAMED2: $named2"           if $named2.defined;
    say "BOOL1: $bool1";
    say "BOOL2: $bool2";
}
