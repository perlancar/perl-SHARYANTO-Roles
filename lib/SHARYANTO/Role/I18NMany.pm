package SHARYANTO::Role::I18NMany;

use 5.010;
use Log::Any '$log';
use Moo::Role;

# VERSION

has langs => (
    is => 'rw',
    default => sub { ['en_US'] },
);
has loc_class => (
    is => 'rw',
    default => sub {
        my $self = shift;
        ref($self) . '::I18N';
    },
);

sub lh {
    my ($self, $lang) = @_;
    die "Please specify lang" unless $lang;

    state $obj;
    if (!$obj) {
        require Module::Load;
        Module::Load::load($self->loc_class);
        $obj = $self->loc_class->new;
    }

    state $lhs = {};
    return $lhs->{$lang} if $lhs->{$lang};

    my $lh = $obj->get_handle($lang)
        or die "Can't get language handle for lang=$lang";
    #$log->tracef("lhs=%s, lh=%s", $lhs, $lh);
    my $c = ref($lh);
    my %class;
    for (my ($l, $h) = each %$lhs) {
        my $c2 = ref($h);
        die "Lang=$lang falls back to lang=$l (class=$c2)" if $class{$c};
        $class{$c2} = $l;
    }

    $lhs->{$lang} = $lh;
    $lh;
}

sub locl {
    my ($self, $lang, @args) = @_;
    $self->lh($lang)->maketext(@args);
}


1;
# ABSTRACT: Role for internationalized class

=head1 DESCRIPTION

This role is like L<SHARYANTO::Role::I18N> but for class that wants to localize
text for more than one languages. Its locl() accepts desired language as its
first argument.


=head1 ATTRIBUTES

=head2 langs => ARRAY

Defaults to a single element array with value of LANG or LANGUAGE environment
variable, or C<en_US>.

=head2 loc_class => STR

Project class name. Defaults to $class::I18N.


=head1 METHODS

=head2 $doc->lh($lang) => OBJ

Get language handle for a certain language. $lang is required.

=head2 $doc->locl($lang, @args) => STR

Shortcut for C<$doc->lh($lang)->maketext(@args)>.

=cut
