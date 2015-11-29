#!/usr/bin/perl

# Author: VxP
#
# Additional Contributions: d20pfsrd community
#
# Description: creates HTML output from PDF input
# tries to preserve paragraphs and formatting
#
# Usage: PDF_extract.pl <intput_file.pdf>

use strict;
use warnings;
use Getopt::Std;


### OPTIONS

our($opt_f, $opt_l, $opt_h, $opt_s);
getopts('f:l:hs');

$Getopt::Std::STANDARD_HELP_VERSION = 1;

sub HELP_MESSAGE {
  print <<"  END";

  Usage: PDF_extract [OPTIONS] <INPUT_FILE>

  The extractifier translates PDF input into HTML output using the pdftohtml
  utility as a back end, and performs some janitorial purposes with the
  resulting output.

      -h            display this help information and exit

      -f P          specify an (optional) starting page number in the PDF
                    # broken by for loop iterator

      -l P          specify an (optional) ending page number in the PDF

      -s            specify simplified output
                    # may be subject to change if it should be default

  KNOWN BUGS:  One of the current developers (as of this writing) will try to
  ensure that known bugs are always tracked using the issue tracker at a public
  BitBucket repository:

      http://bitbucket.org/d20pfsrd/extractifier/issues

  If you wish to report any bugs, you may use that issue tracker or (at this
  time at least) the d20pfsrd-contributors Google group.

  END

  exit;
}

if ($opt_h) {
  HELP_MESSAGE();
}


### PDFTOHTML OPTIONS

my $pdftohtml_opts = "-i -stdout";

if ($opt_f) {
  $pdftohtml_opts = "$pdftohtml_opts" . " -f $opt_f";
}

if ($opt_l) {
  $pdftohtml_opts = "$pdftohtml_opts" . " -l $opt_l";
}

if (!$opt_s) {
  $pdftohtml_opts = "$pdftohtml_opts" . ' -c';
}


### MAIN PROGRAM

my @data = `pdftohtml $pdftohtml_opts $ARGV[0]`;
my $name = substr($ARGV[0], 0, -4);
my @textfile;
my $i=0;

for (my $n=0; $n<=$#data; $n++) {
  my $filenumber = $n+1;
  my $filename = $name."-".$filenumber.".html";
  open DATA, $filename or die $!;
  while (my $line = <DATA>) {
    if ($line =~ m/^<DIV/) {
      if ($line !~ m/>(\d+<|paizo.com|TM|®|™)/) {
        chomp $line;
        $line =~ s/^<DIV.*?>/<DIV>/;
        $line =~ s/<nobr><span.*?>//;
        $line =~ s/<\/span><\/nobr>//;
        $textfile[$i] = $line;
        $i++;
      }
    }
  }
  close DATA;
  unlink $filename;
}

for (my $m=0; $m<=$#textfile; $m++) {
  $textfile[$m] =~ s/(<i>|<\/i>)//g;
  if ($textfile[$m] =~ m/(&nbsp;<\/DIV>|>\w<)/) {
    $textfile[$m] =~ s/<\/DIV>//;
    $textfile[$m+1] =~ s/<DIV>//;
  }
  if ($textfile[$m] =~ m/<DIV>([a-z]|&nbsp;|[,.;-]|’)/) {
    $textfile[$m-1] =~ s/<\/DIV>//;
    $textfile[$m] =~ s/<DIV>//;
  }
  $textfile[$m] =~ s/&nbsp;<br>/ /g;
  $textfile[$m] =~ s/-<br>/-/g;
  $textfile[$m] =~ s/—<br>/—/g;
  $textfile[$m] =~ s/<br>/<\/DIV><DIV>/g;
  $textfile[$m] =~ s/<\/DIV>/<\/DIV>\n/g;
}

my $outfile1 = $name.".tmp";
my $handle1 = ">".$outfile1;
open OUTPUT, $handle1 or die $!;
print OUTPUT '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"><HTML><HEAD><TITLE>'.$name.'</TITLE><META http-equiv="Content-Type"content="text/html; charset=UTF-8"></HEAD>';
print OUTPUT @textfile;
print OUTPUT "</DIV></BODY></HTML>";
close OUTPUT;

my $outfile2 = $name.".html";
my $handle2 = ">".$outfile2;
open EDITINPUT, $outfile1 or die $!;
open EDITOUTPUT, $handle2 or die $!;
while (my $line = <EDITINPUT>) {
  $line =~ s/&nbsp;&nbsp;/&nbsp;/g;
  $line =~ s/&nbsp;/ /g;
#  my $count = ()= $line =~ m/\w+/g;
  print EDITOUTPUT $line;
}
close EDITINPUT;
close EDITOUTPUT;
unlink $outfile1;

my $filename2 = $name."-outline.html";
unlink $filename2;
my $filename3 = $name."_ind.html";
unlink $filename3;
