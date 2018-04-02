# xymonWays
Different ways to get to the xymon data

You can capture the status messages or data coming in, parse them, and store those in a database (ie; influxdb), or you can query xymondboard (http://xymon.sourceforge.net/xymon/help/manpages/man1/xymon.1.html) directly from your code, in realtime.

you don't need the xymon client

## perl 

ie. perl to query for the disk status of serverX 

       1 #!/usr/bin/perl -w
       2 use strict;
       3 use IO::Socket;
       4 $| = 1;
       5 my $sock = new IO::Socket::INET (
       6    PeerAddr => '127.0.0.1',
       7    PeerPort => '1984',
       8    Proto => 'tcp',
       9 ) or warn "Cannot connect to xymon : $!\n";
      10
      11 print $sock "xymondboard host=serverX test=disk\n";
      12 shutdown($sock,1);
      13 my $answer =<$sock>;
      14 print "$answer\n";
      15 close ($sock);

### result

   $ perl query_xymon.pl
   
   serverX|disk|red||1522068617|1522309817|1522311617|0|0|x.x.x.x|845851|red Thu Mar 29 09:50:08 CEST 2018 - Filesystems NOT ok

## python

        1 import socket
        2 import sys
        3
        4 try:
        5     s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        6 except socket.error:
        7     print 'Failed to create socket'
        8     sys.exit()
        9
       10 host = '127.0.0.1';
       11 port = 1984;
       12
       13 try:
       14     remote_ip = socket.gethostbyname( host )
       15 except socket.gaierror:
       16     sys.exit()
       17
       18 s.connect((remote_ip , port))
       19
       20 message = "xymondboard host=serverX test=disk"
       21 try :
       22     #Set the whole string
       23     s.sendall(message)
       24 except socket.error:
       25     print 'Send failed'
       26     sys.exit()
       27
       28 result = []
       29 s.shutdown(socket.SHUT_WR)
       30 while True:
       31   chunk = s.recv(4096)
       32   if not chunk:
       33         break
       34   result+= [chunk]
       35 s.close()
       36
       37 print result
       
### result

   $ python query_xymon.py
   
   ['serverX|disk|red||1522068617|1522318217|1522320017|0|0|x.x.x.x|845851|red Thu Mar 29 12:10:08 CEST 2018 - Filesystems NOT ok\n']

       

## node.js 

        1 var net = require('net');
        2
        3 var client = new net.Socket();
        4
        5 client.connect(1984, '127.0.0.1', function() {
        6   client.write('xymondboard host=serverX test=disk');
        7   client.end();
        8 });
        9
       10 client.on('data', function(data){
       11   console.log(data.toString());
       12 });

       
### result

   $ node query_x.js
   
   serverX|disk|red||1522068617|1522317617|1522319417|0|0|x.x.x.x|845851|red Thu Mar 29 12:00:09 CEST 2018 - Filesystems NOT ok

## Powershell

     $port=1984
     $remoteHost = "localhost"
     $Message = 'xymondboard test=disk'
     $socket = new-object System.Net.Sockets.TcpClient($remoteHost, $port)
     $data = [System.Text.Encoding]::ASCII.GetBytes($message)
     $stream = $socket.GetStream()
     $buffer = New-Object System.Byte[] 1024
     $encoding = New-Object System.Text.AsciiEncoding
     $stream.Write($data, 0, $data.Length)
     $socket.client.shutdown(1)
     $read = $stream.Read( $buffer, 0, 1024 )
     Write-Host -n ($encoding.GetString( $buffer, 0, $read ))
     $socket.close()

### result
    
     PS /home/jeroen/scripts> ./testtcp.ps1         
     
     FLNX|disk|green||1521983717|1522397168|1522398968|0|0|127.0.0.1||green Fri Mar 30 10:06:03 CEST 2018 - Filesystems ok
