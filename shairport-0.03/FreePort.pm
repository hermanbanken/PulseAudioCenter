#!/usr/bin/perl
sub local_port_is_free {
     my ($portnumber) = @_;
     my $proto = getprotobyname('tcp');
     my $iaddr = inet_aton('localhost');
     my $timeout = 5;
     my $freeport = 0;
     my $paddr = sockaddr_in($portnumber, $iaddr);
     socket(SOCKET, PF_INET, SOCK_STREAM, $proto);
     eval {
         local $SIG{ALRM} = sub { die "timeout" };
         alarm($timeout);
         connect(SOCKET, $paddr) || error();
     };
     if ($@) {
         eval {close SOCKET; };
         $freeport = $portnumber;
     } else {
         eval {close SOCKET; };
     }
     alarm(0);
     return $freeport;
}

sub get_next_free_local_port {
     my ($startport) = @_;
     my $freeport = 0;
     my $tryport = $startport;
     while(not $freeport = local_port_is_free($tryport) ) {
         $tryport ++;
         die("Cannot find free port") if $tryport > ($startport + 100);
     }
     return $freeport;
}