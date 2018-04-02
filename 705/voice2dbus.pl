#!/usr/bin/perl

while(<>) {
  $line = $_;
  if($line =~ /^0000\d+?\:(.*)\(/ ) {
    $words = $1;
    if($line !~ /^\s*$/) {
      print "SEND $words\n";
      system "dbus-send --print-reply --dest=org.navit_project.navit /org/navit_project/navit/default_navit org.navit_project.navit.navit.add_voice_data string:'$words'"
    }
  }
}

