#!/usr/bin/env perl

use warnings;
use strict;
use Data::Dumper;
use Getopt::Long;
use Pod::Usage;
use Monitoring::Livestatus;

$Data::Dumper::Sortkeys = 1;

#########################################################################
# parse and check cmd line arguments
my ($opt_h, $opt_v, @opt_f, $opt_l);
Getopt::Long::Configure('no_ignore_case');
if(!GetOptions (
   "h"              => \$opt_h,
   "l=i"            => \$opt_l,
   "<>"             => \&add_file,
)) {
    pod2usage( { -verbose => 1, -message => 'error in options' } );
    exit 3;
}

if(defined $opt_h) {
    pod2usage( { -verbose => 1 } );
    exit 3;
};
$opt_l = 1 unless defined $opt_l;

#########################################################################
my $ml = Monitoring::Livestatus->new(
                                     peer        => \@opt_f,
                                     verbose     => $opt_v,
                                     keepalive   => 1,
                                     warnings    => 0,
                                   );

#########################
# get tables
my $data            = $ml->selectall_hashref("GET columns\nColumns: table", 'table');
my @tables          = sort keys %{$data};

for my $type (@tables) {
    my $filter = "";
    $filter  = "Filter: time > ".(time() - 86400)."\n" if $type =~ m/(log|statehist)/mi;
    $filter .= "Filter: time < ".(time())."\n"         if $type =~ m/(log|statehist)/mi;

    my $statement = "GET $type\n".$filter."Limit: ".$opt_l;
    print STDERR $statement,"\n";
    my $keys  = $ml->selectrow_hashref($statement);

    my $file = 'docs/development/tables/'.$type.'.txt';
    open(my $fh, '>', $file) or die("cannot write to $file: $!");
    print $fh Dumper($keys);
    close($fh);
}

#########################################################################
sub add_file {
    my $file = shift;
    push @opt_f, $file;
    return 1;
}

=head1 NAME

thruk_update_table_docs.pl - Update Table Docs

=head1 SYNOPSIS

thruk_update_table_docs.pl [ -h ] <socket|server>

=head1 DESCRIPTION

Updates the table docs

=head1 AUTHORS

Sven Nierlein, 2009, <nierlein@cpan.org>

=head1 COPYRIGHT

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
