#!perl

use 5.010;
use strict;
use warnings;

package MyPkg;
use Moo;
with 'SHARYANTO::Role::Doc::Section';

package main;
use Test::More 0.98;
my $doc = MyPkg->new;

$doc->doc_sections([qw/a b c/]);
$doc->add_doc_section_before('j', 'a');
is_deeply($doc->doc_sections, [qw/j a b c/], 'add_doc_section_before (1)')
    or diag explain $doc->doc_sections;
$doc->add_doc_section_before('k', 'a');
is_deeply($doc->doc_sections, [qw/j k a b c/], 'add_doc_section_before (2)')
    or diag explain $doc->doc_sections;
$doc->add_doc_section_before('l', 'z');
is_deeply($doc->doc_sections, [qw/l j k a b c/], 'add_doc_section_before (3)')
    or diag explain $doc->doc_sections;

$doc->doc_sections([qw/a b c/]);
$doc->add_doc_section_after('j', 'c');
is_deeply($doc->doc_sections, [qw/a b c j/], 'add_doc_section_after (1)')
    or diag explain $doc->doc_sections;
$doc->add_doc_section_after('k', 'c');
is_deeply($doc->doc_sections, [qw/a b c k j/], 'add_doc_section_after (2)')
    or diag explain $doc->doc_sections;
$doc->add_doc_section_after('l', 'z');
is_deeply($doc->doc_sections, [qw/a b c k j l/], 'add_doc_section_after (3)')
    or diag explain $doc->doc_sections;

$doc->doc_sections([qw/a b c/]);
$doc->delete_doc_section('a');
is_deeply($doc->doc_sections, [qw/b c/], 'delete_doc_section (1)');
$doc->delete_doc_section('c');
is_deeply($doc->doc_sections, [qw/b/], 'delete_doc_section (2)');
$doc->delete_doc_section('a');
is_deeply($doc->doc_sections, [qw/b/], 'delete_doc_section (3)');

DONE_TESTING:
done_testing();
