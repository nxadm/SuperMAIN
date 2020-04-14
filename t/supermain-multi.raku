#!/usr/bin/env raku
use lib 'lib';
use SuperMAIN;

multi sub MAIN($positional, Str :n(:$named)) {
    say "POSITIONAL: $positional" if $positional.defined;
    say "NAMED: $named"           if $named.defined;
}

multi sub MAIN($positional, Str :n(:$named1), Str :$named2) {
    say "POSITIONAL: $positional" if $positional.defined;
    say "NAMED1: $named1"         if $named1.defined;
    say "NAMED2: $named2"         if $named2.defined;
}

multi MAIN($positional1, $positional2, Str :n(:$named1), Str :$named2, Str :$named3) {
    say "POSITIONAL1: $positional1" if $positional1.defined;
    say "POSITIONAL2: $positional2" if $positional2.defined;
    say "NAMED1: $named1"           if $named1.defined;
    say "NAMED2: $named2"           if $named2.defined;
    say "NAMED3: $named3"           if $named3.defined;
}

multi MAIN($positional1, $positional2, Str :n(:$named1), Str :$named2, Str :$otherparam) {
    say "POSITIONAL1: $positional1" if $positional1.defined;
    say "POSITIONAL2: $positional2" if $positional2.defined;
    say "NAMED1: $named1"           if $named1.defined;
    say "NAMED2: $named2"           if $named2.defined;
    say "OTHER:  $otherparam"       if $otherparam.defined;
}

multi MAIN($positional1, $positional2, Str :n(:$named1), Str :$named2,
        Str :$otherparam, Str :$otterparam) {
    say "POSITIONAL1: $positional1" if $positional1.defined;
    say "POSITIONAL2: $positional2" if $positional2.defined;
    say "NAMED1: $named1"           if $named1.defined;
    say "NAMED2: $named2"           if $named2.defined;
    say "OTHER: $otherparam"        if $otherparam.defined;
    say "OTTER: $otterparam"        if $otterparam.defined;
}