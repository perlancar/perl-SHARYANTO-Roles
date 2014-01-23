package SHARYANTO::Role::TermAttrs;

use 5.010;
use Moo::Role;

# VERSION

my $dt_cache;
sub detect_terminal {
    my $self = shift;

    if (!$dt_cache) {
        require Term::Detect::Software;
        $dt_cache = Term::Detect::Software::detect_terminal_cached();
        #use Data::Dump; dd $dt_cache;
    }
    $dt_cache;
}

my $termw_cache;
my $termh_cache;
sub _term_size {
    my $self = shift;

    if (defined $termw_cache) {
        return ($termw_cache, $termh_cache);
    }

    ($termw_cache, $termh_cache) = (0, 0);
    if (eval { require Term::Size; 1 }) {
        ($termw_cache, $termh_cache) = Term::Size::chars();
    }
    ($termw_cache, $termh_cache);
}

has interactive => (
    is      => 'rw',
    default => sub {
        my $self = shift;
        if (defined $ENV{INTERACTIVE}) {
            $self->{_term_attrs_debug_info}{interactive_from} =
                'INTERACTIVE env';
            return $ENV{INTERACTIVE};
        } else {
            $self->{_term_attrs_debug_info}{interactive_from} =
                '-t STDOUT';
            return (-t STDOUT);
        }
    },
);

has use_color => (
    is      => 'rw',
    default => sub {
        my $self = shift;
        if (defined $ENV{COLOR}) {
            $self->{_term_attrs_debug_info}{use_color_from} =
                'COLOR env';
            return $ENV{COLOR};
        } else {
            $self->{_term_attrs_debug_info}{use_color_from} =
                'interactive + color_deth';
            return $self->interactive && $self->color_depth > 0;
        }
    },
);

has color_depth => (
    is      => 'rw',
    default => sub {
        my $self = shift;
        if (defined $ENV{COLOR_DEPTH}) {
            $self->{_term_attrs_debug_info}{color_depth_from} =
                'COLOR_DEPTH env';
            return $ENV{COLOR_DEPTH};
        } elsif (defined(my $cd = $self->detect_terminal->{color_depth})) {
            $self->{_term_attrs_debug_info}{color_depth_from} =
                'detect_terminal';
            return $cd;
        } else {
            $self->{_term_attrs_debug_info}{color_depth_from} =
                'hardcoded default';
            return 16;
        }
    },
);

has use_box_chars => (
    is      => 'rw',
    default => sub {
        my $self = shift;
        if (defined $ENV{BOX_CHARS}) {
            $self->{_term_attrs_debug_info}{use_box_chars_from} =
                'BOX_CHARS env';
            return $ENV{BOX_CHARS};
        } elsif (!$self->interactive) {
            # most pager including 'less -R' does not support interpreting
            # boxchar escape codes.
            $self->{_term_attrs_debug_info}{use_box_chars_from} =
                '(not) interactive';
            return 0;
        } elsif (defined(my $bc = $self->detect_terminal->{box_chars})) {
            $self->{_term_attrs_debug_info}{use_box_chars_from} =
                'detect_terminal';
            return $bc;
        } else {
            $self->{_term_attrs_debug_info}{use_box_chars_from} =
                'hardcoded default';
            return 0;
        }
    },
);

has use_utf8 => (
    is      => 'rw',
    default => sub {
        my $self = shift;
        if (defined $ENV{UTF8}) {
            $self->{_term_attrs_debug_info}{use_utf8_from} =
                'UTF8 env';
            return $ENV{UTF8};
        } elsif (defined(my $termuni = $self->detect_terminal->{unicode})) {
            $self->{_term_attrs_debug_info}{use_utf8_from} =
                'detect_terminal + LANG/LANGUAGE env must include "utf8"';
            return $termuni &&
                (($ENV{LANG} || $ENV{LANGUAGE} || "") =~ /utf-?8/i ? 1:0);
        } else {
            $self->{_term_attrs_debug_info}{use_utf8_from} =
                'hardcoded default';
            return 0;
        }
    },
);

has _term_attrs_debug_info => (is => 'rw', default=>sub{ {} });

has term_width => (
    is      => 'rw',
    default => sub {
        my $self = shift;
        if ($ENV{COLUMNS}) {
            $self->{_term_attrs_debug_info}{term_width_from} = 'COLUMNS env';
            return $ENV{COLUMNS};
        }
        my ($termw, undef) = $self->_term_size;
        if ($termw) {
            $self->{_term_attrs_debug_info}{term_width_from} = 'term_size';
        } else {
            # sane default, on windows printing to rightmost column causes
            # cursor to move to the next line.
            $self->{_term_attrs_debug_info}{term_width_from} =
                'hardcoded default';
            $termw = $^O =~ /Win/ ? 79 : 80;
        }
        $termw;
    },
);

has term_height => (
    is      => 'rw',
    default => sub {
        my $self = shift;
        if ($ENV{LINES}) {
            $self->{_term_attrs_debug_info}{term_height_from} = 'LINES env';
            return $ENV{LINES};
        }
        my (undef, $termh) = $self->_term_size;
        if ($termh) {
            $self->{_term_attrs_debug_info}{term_height_from} = 'term_size';
        } else {
            $self->{_term_attrs_debug_info}{term_height_from} = 'default';
            # sane default
            $termh = 25;
        }
        $termh;
    },
);

1;
#ABSTRACT: Role for terminal-related attributes

=head1 DESCRIPTION

This role gives several options to turn on/off terminal-oriented features like
whether to use UTF8 characters, whether to use colors, and color depth. Defaults
are set from environment variables or by detecting terminal
software/capabilities.


=head1 ATTRIBUTES

=head2 use_utf8 => BOOL (default: from env, or detected from terminal)

The default is retrieved from environment: if C<UTF8> is set, it is used.
Otherwise, the default is on if terminal emulator software supports Unicode
I<and> language (LANG/LANGUAGE) setting has /utf-?8/i in it.

=head2 use_box_chars => BOOL (default: from env, or detected from OS)

Default is 0 for Windows.

=head2 interactive => BOOL (default: from env, or detected from terminal)

=head2 use_color => BOOL (default: from env, or detected from terminal)

=head2 color_depth => INT (default: from env, or detected from terminal)

=head2 term_width => INT (default: from env, or detected from terminal)

=head2 term_height => INT (default: from env, or detected from terminal)


=head1 METHODS

=head2 detect_terminal() => HASH

Call L<Term::Detect::Software>'s C<detect_terminal_cached>.

=head1 ENVIRONMENT

=over

=item * UTF8 => BOOL

Can be used to set C<use_utf8>.

=item * INTERACTIVE => BOOL

Can be used to set C<interactive>.

=item * COLOR => BOOL

Can be used to set C<use_color>.

=item * COLOR_DEPTH => INT

Can be used to set C<color_depth>.

=item * BOX_CHARS => BOOL

Can be used to set C<use_box_chars>.

=item * COLUMNS => INT

Can be used to set C<term_width>.

=item * LINES => INT

Can be used to set C<term_height>.

=back

=cut
