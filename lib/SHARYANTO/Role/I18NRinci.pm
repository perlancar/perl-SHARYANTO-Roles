package SHARYANTO::Role::I18NRinci;

use 5.010;
use Log::Any '$log';
use Moo::Role;
use Perinci::Object;

# VERSION

with 'SHARYANTO::Role::I18N';

requires 'lang';

sub langprop {
    my ($self, $meta, $prop) = @_;
    my $opts = {
        lang=>$self->lang,
    };
    rimeta($meta)->langprop($prop, $opts);
}

1;
# ABSTRACT: Role for class that wants to work with language and Rinci metadata

=head1 METHODS

=head2 $obj->langprop($meta, $prop)

=cut
