#!/usr/bin/env raku
use lib 'lib';
use SuperMAIN;

enum Choice <1 2 3 4>;

sub MAIN($positional1, $positional2?,
        :n(:$named), :$other-named,
        Choice :$choice,
        Bool :$bool, Bool :$diff-bool) {
    say "POSITIONAL1: [$positional1]" if $positional1.defined;
    say "POSITIONAL2: [$positional2]" if $positional2.defined;
    say "NAMED: [$named]"             if $named.defined;
    say "OTHER-NAMED: [$other-named]" if $other-named.defined;;
    say "CHOICE: [$choice]"           if $choice.defined;
    say "BOOL: "      ~ so $bool;
    say "DIFF-BOOL: " ~ so $diff-bool;
}