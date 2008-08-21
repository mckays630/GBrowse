#-*-Perl-*-

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'
use lib '/home/lstein/projects/bioperl-live';
use strict;
use warnings;
use Module::Build;
use Bio::Root::IO;
use File::Path 'rmtree';
use IO::String;
use CGI;
use FindBin '$Bin';

use constant TEST_COUNT => 4;
use constant CONF_FILE  => "$Bin/testdata/conf/GBrowse.conf";

my $PID;

BEGIN {
  # to handle systems with no installed Test module
  # we include the t dir (where a copy of Test.pm is located)
  # as a fallback
  eval { require Test; };
  if( $@ ) {
    use lib 't';
  }
  use Test;
  plan test => TEST_COUNT;

  $PID = $$;

  rmtree '/tmp/gbrowse_testing';
}
END {
#    rmtree '/tmp/gbrowse_testing' if $$ == $PID;
}

# %ENV = ();

chdir $Bin;
use lib "$Bin/../libnew";
use Bio::Graphics::Browser;
use Bio::Graphics::Karyotype;

# create objects we need to test the karyotype generator
my $globals = Bio::Graphics::Browser->new(CONF_FILE);
my $session = $globals->session;
my $source  = $globals->create_data_source('volvox');

my $kg      = Bio::Graphics::Karyotype->new(source   => $source);

my @motifs = $source->open_database()->features('motif');
$kg->sort_sub(sub ($$) 
	      {
		  my $a = shift;
		  my $b = shift;
		  return $b->length<=>$a->length;
	      }
    );

ok($kg);

$kg->add_hits(\@motifs);
my $html    = $kg->to_html($source);
ok($html);
my @divs = $html =~ /(<div)/g;
ok(scalar @divs,62);
my @imgs = $html =~ /(<img)/g;
ok(scalar @imgs,17);

if (1) { # set this to true to see the image
    $html =~ s!/tmpimages!/tmp/gbrowse_testing/tmpimages!g;

    open my $f,'>','foo.html';
    print $f <<'END';
<!DOCTYPE html
	PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
	 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US" xml:lang="en-US">
<head>
<title>karyotype test</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<script type="text/javascript" src="../htdocs/js/prototype.js" </script>
<script type="text/javascript" src="../htdocs/js/karyotype.js" </script>
<link   type="text/css"        rel="stylesheet"  href="../htdocs/css/karyotype.css" />
</head>
<body>
<h1>karyotype test</h1>
END
;

    print $f $html;

    print $f <<'END';
</body>
</html>
END
    ;
    close $f;
    system "firefox ./foo.html";
}

exit 0;
