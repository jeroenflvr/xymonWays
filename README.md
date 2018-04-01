# xymonWays
Different ways to get to the xymon data

## XyMonAPI.js 

This a restful api interface to xymondboard. standard filters are hostname, test, color, page and fields.

it uses node.js express library and xml2js (both install via 'npm install' command). Express is used for the api, xml2js to convert xml results to json.

## readfromXymon 

Shows how to query xymondboard (xymondxboard for xml) without the xymon client directly from code in perl, python, node and even powershell.

## inflyxXymond.pl

Perl script that illustrates how to hook into xymon's status channel, parse the data and store it in an influxdb timeseries database.
