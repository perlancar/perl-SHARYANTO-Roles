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
        $ENV{INTERACTIVE} // (-t STDOUT);
    },
);

has use_color => (
    is      => 'rw',
    default => sub {
        my $self = shift;
        $ENV{COLOR} // $ENV{INTERACTIVE} //
            $self->detect_terminal->{color_depth} > 0;
    },
);

has color_depth => (
    is      => 'rw',
    default => sub {
        my $self = shift;
        return $ENV{COLOR_DEPTH} if defined $ENV{COLOR_DEPTH};
        return $self->detect_terminal->{color_depth} // 16;
    },
);

has use_box_chars => (
    is      => 'rw',
    default => sub {
        my $self = shift;
        return $ENV{BOX_CHARS} if defined $ENV{BOX_CHARS};
        return $self->detect_terminal->{box_chars} // 0;
    },
);

has use_utf8 => (
    is      => 'rw',
    default => sub {
        my $self = shift;
        return $ENV{UTF8} if defined $ENV{UTF8};
        my $termuni = $self->detect_terminal->{unicode};
        if (defined $termuni) {
            return $termuni &&
                (($ENV{LANG} || $ENV{LANGUAGE} || "") =~ /utf-?8/i ? 1:0);
        }
        0;
    },
);

has term_width => (
    is      => 'rw',
    default => sub {
        my $self = shift;
        if ($ENV{COLUMNS}) {
            return $ENV{COLUMNS};
        }
        my ($termw, undef) = $self->_term_size;
        if (!$termw) {
            # sane default, on windows printing to rightmost column causes
            # cursor to move to the next line.
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
            return $ENV{LINES};
        }
        my (undef, $termh) = $self->_term_size;
        if (!$termh) {
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
