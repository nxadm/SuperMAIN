#!/usr/bin/env raku
use lib 'lib';
use SuperMAIN;

multi sub MAIN($positional, Str :n(:$named)) {
    say "POSITIONAL: $positional" if $positional.defined;
    say "NAMED: $named"           if $named.defined;
}

multi sub MAIN($positional, Str :n(:$named), Str :$other-named) {
    say "POSITIONAL: $positional"    if $positional.defined;
    say "NAMED: $named"              if $named.defined;
    say "OTHER-NAMED:: $other-named" if $other-named.defined;
}

multi MAIN($positional1, $positional2?, Str :n(:$named),
        Str :$other-named, Str :$diff-named) {
    say "POSITIONAL1: $positional1" if $positional1.defined;
    say "POSITIONAL2: $positional2" if $positional2.defined;
    say "NAMED: $named"             if $named.defined;
    say "OTHER-NAMED: $other-named" if $other-named.defined;
    say "DIFF-NAMED: $diff-named"   if $diff-named.defined;
}

multi MAIN($positional1, $positional2?,
        Str :n(:$named),  Str :$other-named,
        Str :$diff-named, Str :$otterparam) {
    say "POSITIONAL1: $positional1" if $positional1.defined;
    say "POSITIONAL2: $positional2" if $positional2.defined;
    say "NAMED: $named"             if $named.defined;
    say "OTHER-NAMED: $other-named" if $other-named.defined;
    say "DIFF-NAMED: $diff-named"   if $diff-named.defined;
    say "OTTER-NAMED: $otterparam"  if $otterparam.defined;
}

multi MAIN($positional1, $positional2?, Str :n(:$named), Bool :$bool, Bool :$diff-bool) {
    say "POSITIONAL1: $positional1" if $positional1.defined;
    say "POSITIONAL2: $positional2" if $positional2.defined;
    say "NAMED: $named"             if $named.defined;
    say "BOOL: "      ~ so $bool;
    say "DIFF-BOOL: " ~ so $diff-bool;
}
