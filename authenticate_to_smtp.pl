#!/usr/bin/perl -w

use strict;
use warnings FATAL => qw(uninitialized);

use Getopt::Long qw(:config no_auto_abbrev require_order);
use IO::Socket;
use IO::Socket::INET;
use IO::Select;
use MIME::Base64;

my %long_opts = (remote => "smtpauth", port => "smtp");
GetOptions("remote=s" => \$long_opts{remote},
	   "port=i" => \$long_opts{port},
	   "login=s" => \$long_opts{login},
	   "pw=s" => \$long_opts{pw},
    ) or die "bad options";

&usage unless defined($long_opts{login}) && defined($long_opts{pw});

sub usage
{
    printf "usage: %s [-remote=smtpauth.domain.tld] [-port=smtp] -login=postmaster\@domain.tld -pw=password\n", $0;
    exit 1;
}

my $s = IO::Socket::INET->new(PeerAddr => $long_opts{remote}, PeerPort => $long_opts{port}) or die;
while (<$s>)
{
    chomp;

    printf "<- %s\n", $_;
    last if $_ =~ m/^220 /o;
}


print "-> EHLO domain.tld\n";
print $s "EHLO domain.tld\n";

while (<$s>)
{
    chomp;

    printf "<- %s\n", $_;
    last if $_ =~ m/^250 /o;
}

my $credentials = sprintf("AUTH PLAIN %s", encode_base64($long_opts{login}."\0".$long_opts{login}."\0".$long_opts{pw}, ""));
printf "-> %s\n", $credentials;
printf $s "%s\n", $credentials;

while (<$s>)
{
    chomp;

    printf "<- %s\n", $_;
    last if $_ =~ m/^235 /o;
}
