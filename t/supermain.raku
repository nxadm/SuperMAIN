#!/usr/bin/env raku
use lib 'lib';
use SuperMAIN;

sub MAIN($positional1='', $positional2='',
        :n(:$named)='', :$other-named='',
        Bool :$bool, Bool :$diff-bool) {
    say "POSITIONAL1: $positional1";
    say "POSITIONAL2: $positional2";
    say "NAMED: $named";
    say "OTHER-NAMED2: $other-named";
    say "BOOL: " ~ so $bool;
    say "DIFF-BOOL2: " ~ so $diff-bool;
}
