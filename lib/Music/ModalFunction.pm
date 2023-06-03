package Music::ModalFunction;

# ABSTRACT: Inspect Musical Modal Functions

our $VERSION = '0.0100';

use Moo;
use strictures 2;
use AI::Prolog;
use Carp qw(croak);
use lib map { "$ENV{HOME}/sandbox/$_/lib" } qw(MIDI-Util);
use MIDI::Util qw(midi_format);
use Music::Note ();
use Music::Scales qw(get_scale_notes);
use namespace::clean;

=head1 SYNOPSIS

  use Music::ModalFunction ();

  my $m = Music::ModalFunction->new(
    chord_note   => 'd',
    chord        => 'maj',
    key_function => 'dominant',
  );

  my $q = $m->chord_key;
  # [[ 'chord_key', 'g', 'ionian', 'd', 'maj', 'dominant' ],
  #  [ 'chord_key', 'g', 'lydian', 'd', 'maj', 'dominant' ]],

=head1 DESCRIPTION

C<Music::ModalFunction> allows querying of a musical database of
Prolog facts and rules that bind notes, chords, modes, keys and
diatonic functionality.

* Currently there is a database of facts called C<chord_key/5> and one
rule named C<pivot_chord_keys/8>.

=head1 ATTRIBUTES

=head2 chord_note

=head2 chord

=head2 mode_note

=head2 mode

=head2 mode_function

=head2 key_note

=head2 key

=head2 key_function

=head2 verbose

=cut

has [qw(chord_note chord mode_note mode mode_function key_note key key_function)] => (
    is => 'ro',
);

has verbose => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a boolean" unless $_[0] =~ /^[01]$/ },
    default => sub { 0 },
);

has _modes => (
    is => 'lazy',
);
sub _build__modes {
    return {
        ionian => [
            { chord => 'maj', roman => 'r_I',   function => 'tonic' },
            { chord => 'min', roman => 'r_ii',  function => 'supertonic' },
            { chord => 'min', roman => 'r_iii', function => 'mediant' },
            { chord => 'maj', roman => 'r_IV',  function => 'subdominant' },
            { chord => 'maj', roman => 'r_V',   function => 'dominant' },
            { chord => 'min', roman => 'r_vi',  function => 'submediant' },
            { chord => 'dim', roman => 'r_vii', function => 'leading_tone' }
        ],
        dorian => [
            { chord => 'min', roman => 'r_i',   function => 'tonic' },
            { chord => 'min', roman => 'r_ii',  function => 'supertonic' },
            { chord => 'maj', roman => 'r_III', function => 'mediant' },
            { chord => 'maj', roman => 'r_IV',  function => 'subdominant' },
            { chord => 'min', roman => 'r_v',   function => 'dominant' },
            { chord => 'dim', roman => 'r_vi',  function => 'submediant' },
            { chord => 'maj', roman => 'r_VII', function => 'subtonic' }
        ],
        phrygian => [
            { chord => 'min', roman => 'r_i',   function => 'tonic' },
            { chord => 'maj', roman => 'r_II',  function => 'supertonic' },
            { chord => 'maj', roman => 'r_III', function => 'mediant' },
            { chord => 'min', roman => 'r_iv',  function => 'subdominant' },
            { chord => 'dim', roman => 'r_v',   function => 'dominant' },
            { chord => 'maj', roman => 'r_VI',  function => 'submediant' },
            { chord => 'min', roman => 'r_vii', function => 'subtonic' }
        ],
        lydian => [
            { chord => 'maj', roman => 'r_I',   function => 'tonic' },
            { chord => 'maj', roman => 'r_II',  function => 'supertonic' },
            { chord => 'min', roman => 'r_iii', function => 'mediant' },
            { chord => 'dim', roman => 'r_iv',  function => 'subdominant' },
            { chord => 'maj', roman => 'r_V',   function => 'dominant' },
            { chord => 'min', roman => 'r_vi',  function => 'submediant' },
            { chord => 'min', roman => 'r_vii', function => 'leading_tone' }
        ],
        mixolydian => [
            { chord => 'maj', roman => 'r_I',   function => 'tonic' },
            { chord => 'min', roman => 'r_ii',  function => 'supertonic' },
            { chord => 'dim', roman => 'r_iii', function => 'mediant' },
            { chord => 'maj', roman => 'r_IV',  function => 'subdominant' },
            { chord => 'min', roman => 'r_v',   function => 'dominant' },
            { chord => 'min', roman => 'r_vi',  function => 'submediant' },
            { chord => 'maj', roman => 'r_VII', function => 'subtonic' }
        ],
        aeolian => [
            { chord => 'min', roman => 'r_i',   function => 'tonic' },
            { chord => 'dim', roman => 'r_ii',  function => 'supertonic' },
            { chord => 'maj', roman => 'r_III', function => 'mediant' },
            { chord => 'min', roman => 'r_iv',  function => 'subdominant' },
            { chord => 'min', roman => 'r_v',   function => 'dominant' },
            { chord => 'maj', roman => 'r_VI',  function => 'submediant' },
            { chord => 'maj', roman => 'r_VII', function => 'subtonic' }
        ],
        locrian => [
            { chord => 'dim', roman => 'r_i',   function => 'tonic' },
            { chord => 'maj', roman => 'r_II',  function => 'supertonic' },
            { chord => 'min', roman => 'r_iii', function => 'mediant' },
            { chord => 'min', roman => 'r_iv',  function => 'subdominant' },
            { chord => 'maj', roman => 'r_V',   function => 'dominant' },
            { chord => 'maj', roman => 'r_VI',  function => 'submediant' },
            { chord => 'min', roman => 'r_vii', function => 'subtonic' }
        ]
    }
}

has _database => (
    is => 'lazy',
);
sub _build__database {
    my ($self) = @_;
    my @chromatic = get_scale_notes('c', 'chromatic', 0, 'b');
    my $database = '';
    for my $base (@chromatic) {
        my ($mode_base) = map { lc } midi_format($base);
        for my $mode (sort keys %{ $self->_modes }) {
            my @pitches;
            my @notes = get_scale_notes($base, $mode);
            warn "$base $mode @notes\n" if $self->verbose;
            for my $note (@notes) {
                my $n = Music::Note->new($note, 'isobase');
                $n->en_eq('flat') if $note =~ /#/;
                push @pitches, map { lc } midi_format($n->format('isobase'));
            }
            my $i = 0;
            for my $pitch (@pitches) {
                my $chord = $self->_modes->{$mode}[$i]{chord};
                my $function = $self->_modes->{$mode}[$i]{function};
                $database .= "chord_key($mode_base, $mode, $pitch, $chord, $function).\n";
                $i++;
            }
        }
    }
    $database .=<<'RULE';
% Can a chord in one key function in a second?
pivot_chord_keys(ChordNote, Chord, Key1Note, Key1, Key1Function, Key2Note, Key2, Key2Function) :-
    % bind the chord to the function of the first key
    chord_key(Key1Note, Key1, ChordNote, Chord, Key1Function),
    % bind the chord to the function of the second key
    chord_key(Key2Note, Key2, ChordNote, Chord, Key2Function),
    % the functions cannot be the same
    Key1Function \= Key2Function.
RULE
    warn "$database\n" if $self->verbose;
    return $database;
}

=head1 METHODS

=head2 new

  $m = Music::ModalFunction->new(%args);

Create a new C<Music::ModalFunction> object.

=head2 chord_key

  $q = $m->chord_key;

Ask the database a question about what chords are in what keys.

Arguments:

  chord_key(ModeNote, Mode, ChordNote, Chord, KeyFunction)

If defined, the argument in that position will be bound to that value
(e.g. C<'_'> even). Otherwise an unbound variable is used.

=cut

sub chord_key {
    my ($self) = @_;
    my $prolog = AI::Prolog->new($self->_database);
    my $query = sprintf 'chord_key(%s, %s, %s, %s, %s).',
        defined $self->mode_note    ? $self->mode_note    : 'ModeNote',
        defined $self->mode         ? $self->mode         : 'Mode',
        defined $self->chord_note   ? $self->chord_note   : 'ChordNote',
        defined $self->chord        ? $self->chord        : 'Chord',
        defined $self->key_function ? $self->key_function : 'KeyFunction',
    ;
    $prolog->query($query);
    my @return;
    while (my $result = $prolog->results) {
        push @return, $result;
    }
    return \@return;
}

=head2 pivot_chord_keys

  $q = $m->pivot_chord_keys;

Ask the database a question about what chords share common keys.

Arguments:

  pivot_chord_keys(ChordNote, Chord, ModeNote, Mode, ModeFunction, KeyNote, Key, KeyFunction)

If defined, the argument in that position will be bound to that value
(e.g. C<'_'> even). Otherwise an unbound variable is used.

=cut

sub pivot_chord_keys {
    my ($self) = @_;
    my $prolog = AI::Prolog->new($self->_database);
    my $query = sprintf 'pivot_chord_keys(%s, %s, %s, %s, %s, %s, %s, %s).',
        defined $self->chord_note    ? $self->chord_note    : 'ChordNote',
        defined $self->chord         ? $self->chord         : 'Chord',
        defined $self->mode_note     ? $self->mode_note     : 'ModeNote',
        defined $self->mode          ? $self->mode          : 'Mode',
        defined $self->mode_function ? $self->mode_function : 'ModeFunction',
        defined $self->key_note      ? $self->key_note      : 'KeyNote',
        defined $self->key           ? $self->key           : 'Key',
        defined $self->key_function  ? $self->key_function  : 'KeyFunction',
    ;
    $prolog->query($query);
    my @return;
    while (my $result = $prolog->results) {
        push @return, $result;
    }
    return \@return;
}

1;
__END__

=head1 SEE ALSO

L<Moo>

L<AI::Prolog>

L<MIDI::Util>

L<Music::Note>

L<Music::Scales>

L<https://en.wikipedia.org/wiki/Prolog>

=cut
