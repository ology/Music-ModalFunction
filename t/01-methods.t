;#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Music::ModalFunction';

subtest defaults => sub {
    my $obj = new_ok 'Music::ModalFunction' => [
        verbose => 1,
    ];
    is $obj->chord_note, undef, 'chord_note';
    is $obj->chord, undef, 'chord';
    is $obj->mode_note, undef, 'mode_note';
    is $obj->mode, undef, 'mode';
    is $obj->mode_function, undef, 'mode_function';
    is $obj->key_note, undef, 'key_note';
    is $obj->key, undef, 'key';
    is $obj->key_function, undef, 'key_function';
    is $obj->verbose, 1, 'verbose';
    is_deeply [sort keys %{ $obj->_modes }],
        [qw(aeolian dorian ionian locrian lydian mixolydian phrygian)],
        '_modes';
};

subtest chord_key => sub {
    my $obj = new_ok 'Music::ModalFunction' => [
        chord_note   => 'd',
        chord        => 'maj',
        key_function => 'dominant',
    ];
    my $got = $obj->chord_key;
    my $expect = [
        [ 'chord_key', 'g', 'ionian', 'd', 'maj', 'dominant' ],
        [ 'chord_key', 'g', 'lydian', 'd', 'maj', 'dominant' ],
    ];
    is_deeply $got, $expect, 'chord_key';
};

subtest pivot_chord_keys => sub {
    my $obj = new_ok 'Music::ModalFunction' => [
        chord_note   => 'g',
        chord        => 'maj',
        mode_note    => 'c',
        key_function => 'subdominant',
    ];
    my $got = $obj->pivot_chord_keys;
    my $expect = [
        [ 'pivot_chord_keys', 'g', 'maj', 'c', 'ionian', 'dominant', 'd', 'dorian', 'subdominant' ],
        [ 'pivot_chord_keys', 'g', 'maj', 'c', 'ionian', 'dominant', 'd', 'ionian', 'subdominant' ],
        [ 'pivot_chord_keys', 'g', 'maj', 'c', 'ionian', 'dominant', 'd', 'mixolydian', 'subdominant' ],
        [ 'pivot_chord_keys', 'g', 'maj', 'c', 'lydian', 'dominant', 'd', 'dorian', 'subdominant' ],
        [ 'pivot_chord_keys', 'g', 'maj', 'c', 'lydian', 'dominant', 'd', 'ionian', 'subdominant' ],
        [ 'pivot_chord_keys', 'g', 'maj', 'c', 'lydian', 'dominant', 'd', 'mixolydian', 'subdominant' ],
    ];
    is_deeply $got, $expect, 'pivot_chord_keys';
};

done_testing();
