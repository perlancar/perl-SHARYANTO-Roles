package SHARYANTO::Role::ColorTheme;

use 5.010;
use Moo::Role;

require Win32::Console::ANSI if $^O =~ /Win/;
use Color::ANSI::Util qw(ansi16fg ansi16bg
                         ansi256fg ansi256bg
                         ansi24bfg ansi24bbg);

# VERSION

with 'SHARYANTO::Role::TermAttrs';

has color_theme_args  => (is => 'rw', default => sub { {} });
has _all_color_themes => (is => 'rw');

sub color_theme_class_prefix {
    my $self = shift;

    (ref($self) ? ref($self) : $self ) . '::ColorTheme';
}

sub color_theme {
    my $self = shift;

    if (!@_) { return $self->{color_theme} }
    my $ct = shift;

    my $p2 = "";
    if (!ref($ct)) {
        $p2 = " named $ct";
        $ct = $self->get_color_theme($ct);
    }

    my $err;
    if (!$ct->{no_color} && !$self->use_color) {
        $err = "color theme uses color but use_color is set to false";
    }
    die "Can't select color theme$p2: $err" if $err;

    $self->{color_theme} = $ct;
}

sub get_color_theme {
    my ($self, $ct) = @_;

    my $prefix = $self->color_theme_class_prefix;
    my $cts;
    my $pkg;
    if ($ct =~ s/(.+):://) {
        $pkg = "$prefix\::$1";
        my $pkgp = $pkg; $pkgp =~ s!::!/!g;
        require "$pkgp.pm";
        no strict 'refs';
        $cts = \%{"$pkg\::color_themes"};
    } else {
        #$cts = $self->list_color_themes(1);
        die "Please use SubPackage::name to choose color theme, ".
            "use list_color_themes() to list available themes";
    }
    $cts->{$ct} or die "Unknown color theme name '$ct'".
        ($pkg ? " in package $pkg" : "");
    ($cts->{$ct}{v} // 1.0) == 1.1 or die "Color theme '$ct' is too old ".
        "(v < 1.1)". ($pkg ? ", please upgrade $pkg" : "");
    $cts->{$ct};
}

sub get_theme_color {
    my ($self, $item_name, $args) = @_;

    return undef if $self->{color_theme}{no_color};
    return $self->{color_theme}{colors}{$item_name};
}

sub themecol2ansi {
    my ($self, $c, $args, $is_bg) = @_;

    $args //= {};
    if (ref($c) eq 'CODE') {
        $c = $c->($self, %$args);
    }

    # empty? skip
    return '' if !defined($c) || !length($c);

    if ($self->{color_depth} >= 2**24) {
        if (ref $c) {
            my $ansifg = $c->{ansi_fg};
            $ansifg //= ansi24bfg($c->{fg}) if defined $c->{fg};
            $ansifg //= "";
            my $ansibg = $c->{ansi_bg};
            $ansibg //= ansi24bbg($c->{bg}) if defined $c->{bg};
            $ansibg //= "";
            $c = $ansifg . $ansibg;
        } else {
            $c = $is_bg ? ansi24bbg($c) : ansi24bfg($c);
        }
    } elsif ($self->{color_depth} >= 256) {
        if (ref $c) {
            my $ansifg = $c->{ansi_fg};
            $ansifg //= ansi256fg($c->{fg}) if defined $c->{fg};
            $ansifg //= "";
            my $ansibg = $c->{ansi_bg};
            $ansibg //= ansi256bg($c->{bg}) if defined $c->{bg};
            $ansibg //= "";
            $c = $ansifg . $ansibg;
        } else {
            $c = $is_bg ? ansi256bg($c) : ansi256fg($c);
        }
    } else {
        if (ref $c) {
            my $ansifg = $c->{ansi_fg};
            $ansifg //= ansi16fg($c->{fg}) if defined $c->{fg};
            $ansifg //= "";
            my $ansibg = $c->{ansi_bg};
            $ansibg //= ansi16bg($c->{bg}) if defined $c->{bg};
            $ansibg //= "";
            $c = $ansifg . $ansibg;
        } else {
            $c = $is_bg ? ansi16bg($c) : ansi16fg($c);
        }
    }
    $c;
}

sub get_theme_color_as_ansi {
    my ($self, $item_name, $args) = @_;
    my $c = $self->get_theme_color($item_name, $args) // '';
    $self->themecol2ansi(
        $c, {name=>$item_name, %{ $args // {} }},
        $item_name =~ /_bg$/);
}

sub list_color_themes {
    require Module::List;
    require Module::Load;

    my ($self, $detail) = @_;

    my $prefix = $self->color_theme_class_prefix;
    my $all_ct = $self->_all_color_themes;

    if (!$all_ct) {
        my $mods = Module::List::list_modules("$prefix\::",
                                              {list_modules=>1, recurse=>1});
        no strict 'refs';
        $all_ct = {};
        for my $mod (sort keys %$mods) {
            #$log->tracef("Loading color theme module '%s' ...", $mod);
            Module::Load::load($mod);
            my $ct = \%{"$mod\::color_themes"};
            for (keys %$ct) {
                my $cutmod = $mod;
                $cutmod =~ s/^\Q$prefix\E:://;
                my $name = "$cutmod\::$_";
                $ct->{$_}{name} = $name;
                $all_ct->{$name} = $ct->{$_};
            }
        }
        $self->_all_color_themes($all_ct);
    }

    if ($detail) {
        return $all_ct;
    } else {
        return sort keys %$all_ct;
    }
}

1;
# ABSTRACT: Role for class wanting to support color themes

=head1 DESCRIPTION

This role is for class that wants to support color themes. For description about
color themes, currently please refer to L<Text::ANSITable>.

Color theme is a defhash containing C<v> (float, should be 1.1), C<name> (str),
C<summary> (str), C<no_color> (bool, should be set to 1 if this is a color theme
without any colors), and C<colors> (hash, the colors for items).

A color should be a scalar containing a single color code which is 6-hexdigit
RGB color (e.g. C<ffc0c0>), or a hashref containing multiple color codes, or a
coderef which should produce a color code (or a hash of color codes).

Multiple color codes are keyed by: C<fg> (RGB value for foreground), C<bg> (RGB
value for background), C<ansi_fg> (ANSI color escape code for foreground),
C<ansi_bg> (ANSI color escape code for background). Future keys like C<css> will
be defined.

Allowing coderef as color allows for flexibility, e.g. for doing gradation
border color, random color, etc (see L<Text::ANSITable::ColorTheme::Demo> for an
example). Code will be called with C<< ($self, %args) >> where C<%args> contains
various information, like C<name> (the item name being requested), etc. In
Text::ANSITable, you can get the row position from C<< $self->{_draw}{y} >>.


=head1 ATTRIBUTES

=head2 color_theme => HASH

=head2 color_theme_args => HASH

=head2 color_theme_class_prefix => STR (default: CLASS + "::ColorTheme")


=head1 METHODS

=head2 $cl->list_color_themes($detail) => ARRAY

=head2 $cl->get_color_theme($name) => HASH

=head2 $cl->get_theme_color($item_name, \%args) => STR

Get an item's color from the current color theme.

=head2 $cl->get_theme_color_as_ansi($item_name, \%args) => STR

Get an item's color from the current color theme, converted to ANSI codes.

=head2 $cl->themecol2ansi($col_code, \%args) => STR

Convert a color from color theme (which can be a scalar containing color code,
or a coderef that generates a color code) to ANSI escape code. C<< %args >> will
be sent to coderef.

=cut
