#!/usr/bin/env raku
use lib 'lib';
use SuperMAIN;

sub MAIN($positional, Str :n(:$named1), Str :$named2, Bool :$bool) {
    say "POSITIONAL: $positional" if $positional.defined;
    say "NAMED1: $named1"         if $named1.defined;
    say "NAMED2: $named2"         if $named2.defined;
    say "BOOL:   $bool";
}
