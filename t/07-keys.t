#!/usr/bin/perl

use strict;
use warnings;

use Net::SSH::Perl::Key;

use Test::More;

use vars qw( $USER_AUTHORIZED_KEYS );

BEGIN { unshift @INC, 't/' }
require 'test-common.pl';

open my $fh, "<", $USER_AUTHORIZED_KEYS or die "can't read $USER_AUTHORIZED_KEYS: $!";

my $line_number = 0;
while ( my $line = <$fh> ) {
    $line_number++;
    $line =~ s/#.*//;   # Strip comments
    chomp($line);
    next unless length $line;
    my $type_offset;
    foreach my $t (@Net::SSH::Perl::Key::KEY_TYPES) {
        $type_offset=index($line,$t);
        last if $type_offset >= 0;
    }
    next unless defined $type_offset && $type_offset >= 0;
    my ($type,$pubkey,$comment) = split /\s+/, substr($line,$type_offset), 3;
    my $test_id = sprintf("L:%d,C:%s", $line_number, $comment);
    my $k;
    eval {
        $k = Net::SSH::Perl::Key->extract_public($line);
        1;
    } or do {
        my $errstr=$@;
        if( $comment =~ /FAIL/ ) {
            pass("$test_id fail");
        }
        else {
            diag("ERROR: $errstr");
            fail("$test_id parse");
        }
        next;
    };
    pass("$test_id parse");

    my $key_type = lc((split /::/, ref($k))[-1]);
    # We might run addition tests;
    if( $k->comment ) {
        my %attrs=();
        foreach my $pair ( split /\s*,\s*/, $k->comment ) {
            my($k,$v) = split /=/, $pair, 2;
            next unless defined $v;
            $attrs{lc $k} = $v;
        }
        if( exists $attrs{type} ) {
            ok(lc $attrs{type} eq $key_type, "$test_id type");
        }
        if( exists $attrs{size} && defined $k->size ) {
            ok($attrs{size} == $k->size, "$test_id size");
        }
    }
}
close $fh;

done_testing();