# SuperMAIN, Raku MAIN() with superpowers

[![Build Status](https://travis-ci.org/nxadm/SuperMAIN.svg?branch=master)](https://travis-ci.org/nxadm/SuperMAIN)

[MAIN](https://docs.raku.org/language/create-cli#sub_MAIN) is one of the many
nice features that makes Raku a very fun language to work with. Command Line
Interfaces (CLI) can be easily be created in a very intuitive way.

This modules adds features to MAIN without changing the syntax (or semantics).
Everything works as before, just with some nice-to-haves for the users of the
CLI.

## Features

The following features were added to MAIN:

- Allow named parameters to be used everywhere instead of only after the 
positional parameters (corresponds with
`%SUB-MAIN-OPTS<named-anywhere> = True`):

```
$ prog.raku <positional> [--named1=<Str>] [--named2=<Str>]
$ prog.raku [--named1=<Str>] [--named2=<Str>] <positional>
$ prog.raku [--named1=<Str>] <positional> [--named2=<Str>] 
```

- Allow spaces as separator between a named parameter and its values (the Raku
default is to only accept '=' as the separator).
```
$ prog.raku [--named1=<Str>]
$ prog.raku [--named1 <Str>] 
```

- Auto-alias named parameters without the need to declare an alias, e.g. to
make "--n" an alias of "--named", you need to declare the alias in the
signature:

```raku
sub MAIN(Str :n(:$named)) { ... }
```

With SuperMain, an alias will be automatically created to the shortest *unique*
parameter identifier, e.g. for the signature

```raku
sub MAIN(Str :$named, Str :$other-named )) { ... }
```

the alias "-n" and "-o" will be accepted. If MAIN already has an alias for a
parameter no new alias will be created for that specific parameter.

```
$ prog.raku [--named=<Str>] [--other-named=<Str>]
$ prog.raku [-n=<Str>] [-o=<Str>]
$ prog.raku [--named <Str>] [--other-named <Str>]
$ prog.raku [-n <Str>] [-o <Str>]
```
 
## Usage

Add this to the script handling the CLI:

```raku
use SuperMAIN;

# That's it: just use `sub MAIN` or `multi MAIN` as usual.
```

## Installation

Through the ecosystem:
```
$ zef install SuperMAIN
```

Locally:

```
$ git clone https://github.com/nxadm/SuperMAIN
$ cd SuperMAIN
$ zef install .
```
