#!/usr/bin/perl

while(<>) {
  $line = $_;
  if( $line=~ /^([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,\n]+)$/) {
    print "$1 $2 type=tec_common tec_type=$3 maxspeed=$4 tec_dirtype=$5 tec_direction=$6\n";
  }
  elsif( $line=~ /^([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,\n]+)$/) {
    print "$2 $3 type=tec_common tec_type=$4 maxspeed=$5 tec_dirtype=$6 tec_direction=$7\n";
  }
}

