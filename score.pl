

use strict;


my $ansfile = shift(@ARGV);
my $goldfile = shift(@ARGV);
my $type =  shift(@ARGV);
my $scoretype = shift(@ARGV);
my $verbose = shift(@ARGV);

if (!$ansfile || !$goldfile || ($ansfile =~ /-\w/) || ($goldfile =~ /-\w/)) {
  print "scorer.pl usage: systemfile goldfile [-t best|oot|mw] [-v]\n";
  undef $scoretype;
}

if (!$type) {
  $scoretype = 'best';
}
elsif (($type eq '-v') && !$scoretype && !$verbose) {
  $scoretype = 'best';
  $verbose = '-v';
}
elsif ($type && ($type ne '-t')) {
  print "scorer.pl usage: systemfile goldfile [-t best|oot|mw] [-v]\n";
  undef $scoretype;
}

if ($scoretype) {

  if ($scoretype eq 'best') {
    scorebest($goldfile,$ansfile); # supplying best answers
  }
  elsif ($scoretype eq 'oot') {
    scoreOOT($goldfile,$ansfile); #supplying up to 10 answers
  }
  elsif ($scoretype eq 'mw') {
    scoreMW($goldfile,$ansfile);
  }
  elsif ($scoretype) {
    print "scorer.pl usage: systemfile goldfile [-t best|oot|mw] [-v]\n";
  }
}

# Systems not scored wrong for space instead of hyphen if hyphen in GS.
# Systems are score wrong for hyphen (instead of space)
# Gold standard will be in lower case

sub scorebest {
  my($goldfile,$ansfile) = @_;
  my(%idws,%idres,%idmodes);
  my($line,$id,$wpos,$res,@res,$numguesses,$hu,$totmodatt,$besteqmode);
  my($totitems,$idcorr,$corr,$precision,$recall,$totmodes,$itemsattempted);
  my($sub,%norms,%done,$score);
  my $dp = 3;
  my $lcnt = 0;
  ($totitems,$totmodes) = readgoldfile($goldfile,\%idws,\%idres,\%idmodes);
  # read into arrays like read agr
  open(SYS,$ansfile);
  while ($line = <SYS>) {
    $lcnt++;    
    undef $idcorr;
    undef %norms;
    if ($line =~ /([\w.]+) (\S+) \:\: (.*)/) {
      $id = $2;
      $wpos = $1;
      $res = $3;      
      $hu = sumvalues(\%{$idres{$id}});
      normalisevalues(\%{$idres{$id}},\%norms,$hu);
      if ($hu && !$done{$id}) {
	$done{$id} = 1;
	if ($res =~ /\S/) {
	  $itemsattempted++;
	}
	@res = split(';',$res); # can't do on spaces because of MWEs
	$numguesses = $#res + 1;      
	if ($idmodes{$id}) {
	  $totmodatt++;
#	  if ($idmodes{$id} eq $res[0]) {
	  if (myequal($idmodes{$id},$res[0])) {
	    $besteqmode++;
	    if ($verbose) {
	      print "$wpos Item $id mode '$idmodes{$id}' : system '$res[0]'  correct\n";
	    }
	  }
	  elsif ($verbose) {
	      print "$wpos Item $id mode '$idmodes{$id}' : system '$res[0]' wrong\n";
	    }
	}
	foreach $sub (@res) {
	  $idcorr += $norms{$sub}; # same if we normalise before / by hu
	  #    $idcorr += $idres{$id}{$sub};
	 }        
	  if ($idcorr) {
	    $score = (($idcorr / $numguesses)); # / $hu); so each item worth 1
	  # $score = (($idcorr / $numguesses) / $hu);
	    $corr += $score;
	  }
	if ($verbose) {
	  print "$wpos Item $id credit $idcorr guesses $numguesses human responses $hu: score is $idcorr\n";
	}

      }
    } # item
    elsif ($line =~ /\S/) {
       print "Error in $ansfile on line $lcnt\n";
    }    
  }
  $precision = $corr / $itemsattempted;
  $precision = myround($precision,$dp);
  $recall = $corr / $totitems;
  $recall = myround($recall,$dp);
  print "Total = $totitems, attempted = $itemsattempted\n";
  print "precision = $precision, recall = $recall\n";
  $precision = $besteqmode / $totmodatt; # where there was a mode and
                         # system had an answer
  $precision = myround($precision,$dp);
  $recall = $besteqmode / $totmodes;
  $recall = myround($recall,$dp);
  print "Total with mode $totmodes attempted $totmodatt\n";
  print "precision = $precision, recall = $recall\n";
  close(SYS);
}

sub scoreOOT {
  my($goldfile,$ansfile) = @_;
  my(%idws,%idres,%idmodes);
  my($line,$id,$wpos,$res,@res,$numguesses,$hu,$totmodatt,$foundmode);
  my($totitems,$idcorr,$corr,$precision,$recall,$totmodes,$itemsattempted);
  my($sub,%norms,%done,$score);
  my $dp = 3;
  my $lcnt = 0;
  ($totitems,$totmodes) = readgoldfile($goldfile,\%idws,\%idres,\%idmodes);
  # read into arrays like read agr
  open(SYS,$ansfile);
  while ($line = <SYS>) {
    $lcnt++;
    undef $idcorr;
    undef %norms;
    if ($line =~ /([\w.]+) (\S+) \:\:\: (.*)/) {
      $id = $2;
      $wpos = $1;
      $res = $3;
      $hu = sumvalues(\%{$idres{$id}});
      normalisevalues(\%{$idres{$id}},\%norms,$hu);
      if ($hu && !$done{$id}) {
	$done{$id} = 1;
	if ($res =~ /\S/) {
	  $itemsattempted++;
	}
	@res = split(';',$res); # can't do on spaces because of MWEs
	#$numguesses = $#res + 1;
	
	if ($idmodes{$id}) {
	  $totmodatt++;
	  #if (strmember($idmodes{$id},@res)) {
	  if (strhypmember($idmodes{$id},@res)) { # hyphens
	    $foundmode++; # mode is in guesses	    
	    if ($verbose) {
	      print "$wpos Item $id mode '$idmodes{$id}'  found in guesses\n";
	    }
	  }
	  elsif ($verbose) {
	      print "$wpos Item $id mode '$idmodes{$id}'  not found\n";
	    }
	}
	foreach $sub (@res) {
	  $idcorr += $norms{$sub}; #
	  #$idres{$id}{$sub}; # check if this isn't defined
	}      
	if ($idcorr) {
	  $corr += $idcorr; #  / $hu); but don't consider 10 guesses, just amount
	                    # of normalised answers in 10
	}	
	if ($verbose) {
	  print "$wpos Item $id credit $idcorr human responses $hu: score is $idcorr\n";
	}
      } # if $hu, humans said something
    } # item
    elsif ($line =~ /\S/) { 
      print "Error in $ansfile on line $lcnt\n";
    }    
  }
  $precision = $corr / $itemsattempted;
  $precision = myround($precision,$dp);
  $recall = $corr / $totitems;
  $recall = myround($recall,$dp);
  print "Total = $totitems, attempted = $itemsattempted\n";
  print "precision = $precision, recall = $recall\n";
  $precision = $foundmode / $totmodatt; # where there was a mode and
                         # system had an answer
  $precision = myround($precision,$dp);
  $recall = $foundmode / $totmodes;
  $recall = myround($recall,$dp);
  print "Total with mode $totmodes attempted $totmodatt\n";
  print "precision = $precision, recall = $recall\n";
  close(SYS);
  }

# will take MW as mode lemmatised
# score for identifying MW on this line - precision (/attempts) 
# recall (/ actual MW)
# score for guessing correct MW, assuming lemmatised mode - min 2 verdicts

sub scoreMW {
  my($goldfile,$ansfile) = @_;
  my(%idmodes);
  my($line,$id,$wpos,$res,$sysmwtot,$corrmode,$totmodes);
  my($totitems,$idcorr,$corr,$precision,$recall,$totmodes,$sysmwatt);
  my($sub,%norms,%done);
  my $dp = 3;
  my $lcnt = 0;
  $totmodes = readmwfile($goldfile,\%idmodes); # recall denom
  # read into arrays like read agr
  open(SYS,$ansfile);
  while ($line = <SYS>) {
    $lcnt++;    
    undef $idcorr;
    undef %norms;
    if ($line =~ /([\w.]+)\s+(\d+)\s*\:\:\s*(.*)\s*$/) {
      $id = $2;
      $wpos = $1;
      $res = $3;      
      if (!$done{$id}) {
	$done{$id} = 1;
	if ($res =~ /\S/) {
	  $sysmwtot++; # prec denom
	}
	if ($idmodes{$id}) {
	  $sysmwatt++; # how many modes did system say were MWs
	  if ($idmodes{$id} eq $res) {
	    $corrmode++; # did system get MW correct?
	  } 
	  if ($verbose) {
	    print "$wpos $id human mode is $idmodes{$id} system $res\n";
	  }
	}
	elsif ($verbose) {
	  print "$wpos $id No MW found by annotators, system $res\n";
	}
	
      }
    }
    elsif ($line =~ /\S/) {
      print "Error in $ansfile on line $lcnt\n";
    }
  }
# is there a MW
  if ($sysmwtot) {
    $precision = $sysmwatt/ $sysmwtot;
    $precision = myround($precision,$dp);
  }
  $recall = $sysmwatt / $totmodes;
  $recall = myround($recall,$dp);
  print "Total MWs in GS = $totmodes, System found $sysmwtot of which $sysmwatt were genuine\n";
  print "Detection precision = $precision, recall = $recall\n";
  if ($sysmwtot) {
    $precision = $corrmode / $sysmwtot; # where systems ans matched GS,
                         # and system had an answer
    $precision = myround($precision,$dp);
  }
  $recall = $corrmode / $totmodes;
  $recall = myround($recall,$dp);
  print "Number that matched GS\n";
  print "Identification precision = $precision, recall = $recall\n";
  close(SYS);

}


sub readmwfile {
  my($gsfile,$modes) = @_;
  my($line,$id,$wpos,$rest,@res,$mw,$num,$mode,$modenum,$i,$totitems,$totmodes);
  my($res,$first,$ms);
  my $lcnt = 0;
  open(GS,"$gsfile");
  while ($line = <GS>) {
    $lcnt++;
    if ($line =~ /([\w.]+)\s+(\d+)\s*\:\: (.*)/) {
      $id = $2;
      $wpos = $1;
      $rest = $3;
      undef $mode;
      undef $modenum;
      undef $ms;
      @res = split(';',$rest);     
      $first = $res[0];
      if ($first =~ /[\w-\s]+ (\d+)/) {
	  $num = $1;
      }
#      if (($#res > 0) || ($num > 1)) { # i.e. 2 or more
      if ($num > 1) { # for mws want 2 humans to have same 
                    # response (though after lemmatising
	$totitems++;
	#	$$idwarr{$id} = $wpos;
	foreach $res (@res) {
	  if ($res =~ /(\w[\w-\s]+) (\d+)/) {
	    $mw = $1;
	    $num = $2;
	  if ((!$mode) && ($num > 1)) { # $i == 0) { # also cond below will take care of those of 1
	    # though we will only take ids where at least 2 responses
	    $mode = $mw;	  
	    $modenum = $num;
	    $$modes{$id} = $mode;	 
	    $totmodes++;
	  }
	  elsif (!$ms && $mode && ($num == $modenum)) { # mode found was not the most freq	  
	    delete $$modes{$id};	 
	    $totmodes--;
	    $ms = 1; # so we don't do this twice for 1 id
	  }
	 # $$resarr{$id}{$sub} = $num;
	  }	 
	}     
      }
    }
    elsif ($line =~ /\S/) {
       print "Error in $gsfile on line $lcnt\n";
    }
  }
  close(GS);
#  return ($totitems,$totmodes);
  return $totmodes;
  }



sub readgoldfile {
  my($gsfile,$idwarr,$resarr,$modes) = @_;
  my($line,$id,$wpos,$rest,@res,$sub,$num,$mode,$modenum,$i,$totitems,$totmodes);
  my($res,$ms,$first);
  open(GS,"$gsfile");
  while ($line = <GS>) {
    if ($line =~ /([\w.]+) (\S+) \:\: (.*)/) {
      $id = $2;
      $wpos = $1;
      $rest = $3;
      undef $mode;
      undef $modenum;
      undef $ms;
      @res = split(';',$rest);
      @res = removeall('pn',@res);
      $first = $res[0];
      if ($first =~ /[\w-\s]+ (\d+)/) {
	  $num = $1;
      }
      if (($#res > 0) || ($num > 1)) { # i.e. 2 or morenon nil and non pn (proper noun)
	$totitems++;
	$$idwarr{$id} = $wpos;
	foreach $res (@res) {
	  if ($res =~ /(\w[\w-\s]+) (\d+)/) {
	    $sub = $1;
	    $num = $2;
	    #for ($i = 0;$i <= $#res;$i++) {
	    #$sub = $res[$i];
	  if (!$mode) { # && ($num > 1)) { # $i == 0) { # also cond below will take care of those of 1
	    $mode = $sub;	  
	    $modenum = $num;
	    $$modes{$id} = $mode;	 
	    $totmodes++;
	  }
	  elsif (!$ms && $mode && ($num == $modenum)) { # mode found was not the most freq	  
	    delete $$modes{$id};	 
	    $totmodes--;
	    $ms = 1; # so we don't do this twice for 1 id
	  }
	  $$resarr{$id}{$sub} = $num;
	  }	 
	}      
    }
    }
  }
  close(GS);
  return ($totitems,$totmodes);
}

###  utilities


# rounds by $db decimal places
sub myround {
    my($number,$dp) = @_;
	my($mult,$result,$dec,$len,$dpo,$diff);
	$dpo = '0' x $dp;
	$mult = 1 . $dpo;
	$number = $number * $mult;
    	$result =  int($number + .5);
	$result = $result /  $mult;
	if ($result =~ /\.(\d+)/) {
		$dec = $1;
		$len = length($dec);
		$diff = $dp - $len;
		while ($diff) {
			$result .= '0';
			$diff--;
		}
	}
	else {
		$result .= ".$dpo";
	}
	return $result;
}


sub sumvalues {
    my($array) = @_;
    my($key,$val,$result);
    while (($key,$val) = each %$array) {
        $result += $val;
    }
    return $result;
}


# normalise by sum, and account for hyphens  in GS
# so if humans put hyphens, then could be spaces or hyphens
# but if humans didn't and systems do systems may be found incorrect
sub normalisevalues {
  my($source,$target,$sum) = @_;
  my($key,$val,$key2,$result);
  while (($key,$val) = each %$source) {
        $$target{$key} = $val / $sum;
	if ($key =~ /-/) {
	  $key2 = $key;
	  $key2 =~ s/-/ /g;
	  $$target{$key2} = $val / $sum;
	}
    }
}

sub strhypmember {
  my($item,@list) = @_;
    my($index);
    for ($index = 0; $index <= $#list; $index++) {
        if (myequal($list[$index],$item)) { # item is GS
            return $index + 1;
            last;
        }
    }
}

sub myequal {
  my($item,$item2) = @_;
  if ($item eq $item2) {
    return 1;
  }
  elsif ($item2 =~ /-/) {
    $item2 =~ s/-/ /g; # get rid of hyphens in GS
    if ($item eq $item2) {
      return 1;
    }
  }
  else {
    return 0;
  }
}

sub strmember {
    my($item,@list) = @_;
    my($index);
    for ($index = 0; $index <= $#list; $index++) {
        if ($list[$index] eq $item) {
            return $index + 1;
            last;
        }
    }
}




sub removeall {
        my($item,@list) = @_;
        my($i,@result);
        foreach $i (@list) {
                if ($i ne $item) {
                        push(@result,$i);
                }
        }
        return @result;
}


