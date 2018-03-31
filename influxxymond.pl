#!/usr/bin/perl
#
#  An example to use xymond_channel messages by storing them in an influx db
#
#
use EV;
use AnyEvent;
use AnyEvent::Socket;
use AnyEvent::Handle;
use AnyEvent::InfluxDB;
use strict;
use warnings;
use Data::Dumper::Simple;

my $start='@@status';
my $stop='^@@$';
my $influxdb = 'http://yourinfluxdb:8086';
my $filename;
my @out;
my $counter=1;
my $found=0;

my $db = AnyEvent::InfluxDB->new(
    server => $influxdb,  #
    username => '',   #use a username and pw
    password => '',
);

sub listenXymond {
    while (<>) {
        my $data = $_;
        if( /$start/../$stop/ ) {
            if( /$start/ ) {
                #print "pid $$";
                @out = ($data);
            }
            elsif ( /$stop/ ) {
                $found = 0;
                 push @out, $data;
                 
                  my $pid = fork;
                   if (not defined $pid) {
                        die "Cannot fork child: $?\n";
                    } elsif ($pid == 0) { 
                        parseMessage(@out);
                    } else {
                        exit(0);

                    }
            
            } else {
                if ($found == 0) {
                    push @out, $data;
                    $found=1;
                } else {
                      push @out, $data;
                }
            }
        }
    }
}

sub writeInflux {
  my ($hostname, $sender, $measurement, $sensor, $value) = @_;  
  #print Dumper($hostname, $sender, $measurement, $sensor, $value);
  my $cv = AE::cv;
    $db->write(
        database => 'testdb',
        precision => 'n',
        data => [
            {
                measurement => $measurement,
                tags => {
                    host => $hostname,
                    ipaddress => $sender
                },
                fields => {
                    value => $value,
                    sensor => '"' . $sensor . '"'
                
                },
                time => time() * 10**9
            }],

        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to write data: @_");
        }
    );
    $cv->recv;
}

sub parseMemory{
    my %data = @_;
    #print Dumper(%data);
        #map { print "$_ : ". $data{$_} . "\n" if defined $data{$_} } keys %data;
    my %toDB;
    #my $physical
    if ($data{'testname'} eq "memory"){
                #         restString : status webkids.memory green Sat Jan  6 11:49:43 UTC 2018 - Memory OK
                #    Memory                  Used       Total  Percentage
                # &green Real/Physical          1534M       1839M         83%
                # &green Actual/Virtual          721M       1839M         39%
                # &green Swap/Page                 0M          0M          0%

                # @@

        my @pmems = split(/\s+/,(split(/\n/,$data{'restString'}))[2]);
        #print Dumper(@pmems);
        my @p = splice(@pmems,2,3);
        chop(@p);
        my ($pUsed, $pTotal, $pPercent) = @p;
        #print Dumper($pUsed, $pTotal,$pPercent);

        my @vmems = split(/\s+/,(split(/\n/,$data{'restString'}))[3]);
        my @v = splice(@vmems,2,3);
        chop(@v);
        my ($vUsed, $vTotal, $vPercent) = @v;
        #print Dumper($vUsed, $vTotal, $vPercent);
       
       my $hostname   = $data{'hostname'};
       my $sender     = $data{'sender'};
       my $measurement   = $data{'testname'};


        %toDB = (
                'pUsed'         => $pUsed,
                'pTotal'        => $pTotal,
                'pPercent'      => $pPercent,
                'vUsed'         => $vUsed,
                'vTotal'        => $vTotal,
                'vPercent'      => $vPercent,
            );

        foreach my $metric (keys %toDB) {
                #print "sending metric: $metric\n";
            writeInflux($hostname,$sender,$measurement . "_" . $metric, $metric, $toDB{$metric});
        };
        #print Dumper(%toDB);
        #writeInflux(%toDB);
    };
};

sub parseMessage {
    my @rawMessage = @_;
                    # from xymond_rrd.c: update_rrd(hostname, testname, restofmsg, tstamp, sender, ldef, classname, pagepaths);

                    # if ((metacount >= 14) && (strncmp(metadata[0], "@@status", 8) == 0) && restofmsg) {
                    #     /*
                    #      * @@status|timestamp|sender|origin|hostname|testname|expiretime|color|testflags|\
                    #      * prevcolor|changetime|ackexpiretime|ackmessage|disableexpiretime|disablemessage|\
                    #      * clienttstamp|flapping|classname|pagepaths
                    #      */
    my ($status, $timestamp, $sender, $origin, $hostname, $testname, $expiration, $color, $testflags, 
           $prevcolor, $changetime, $ackexpiretime, $ackmessage, $disableexpirationtime, $disablemessage, $clienmsgtimestamp, $flapping,$classname,$pagepaths) = split(/\|/, shift(@rawMessage));

    my $restString = join("", @rawMessage);
    #removed the eval vars
    my %retHash = (
        'status'                => $status || "",
        'timestamp'             => $timestamp || "",
        'sender'                => $sender || "",
        'origin'                => $origin || "",
        'hostname'              => $hostname || "",
        'testname'              => $testname || "",
        'expiration'            => $expiration || "",
        'color'                 => $color || "",
        'testflags'             => $testflags || "",
        'prevcolor'             => $prevcolor || "",
        'changetime'            => $changetime || "",
        'ackexpiretime'         => $ackexpiretime || "",
        'ackmessage'            => $ackmessage || "",
        'disableexpirationtime' => $disableexpirationtime || "",
        'disablemessage'        => $disablemessage || "",
        'clienmsgtimestamp'     => $clienmsgtimestamp || "",
        'flapping'              => $flapping || "",
        'restString'            => $restString || "",
        'classname'             => $classname || "",
        'pagepaths'             => $pagepaths || ""
    );

    print "testname: $testname\n";
 

    
        if ($testname eq "memory")  {parseMemory(%retHash)}
        elsif ($testname eq"cpu")   {print Dumper(%retHash);}
        else                        {} # no action defined for test $testname
    


    # if($testname eq "memory") {
    #     parseMemory(%retHash);
    # }
}

sub main(){  
    listenXymond;
}

main();
