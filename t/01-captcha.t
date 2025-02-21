use strict;
use warnings;

package Faux::Context;

########################################################################
sub new {
########################################################################
  my ( $class, %options ) = @_;

  my $self = bless \%options, $class;

  return $self;
}

########################################################################
sub cgi_header_in    { }
sub send_http_header { }
sub cgi_header_out   { }
########################################################################

########################################################################
sub getCookieValue {
########################################################################
  my ( $self, $name ) = @_;

  return $ENV{$name};
}

########################################################################
sub getInputValue {
########################################################################
  my ( $self, $name ) = @_;

  return $ENV{$name};
}

########################################################################
package main;
########################################################################

use Test::More;

use Bedrock qw(slurp_file);
use Bedrock::BedrockConfig;
use Bedrock::Constants qw(:defaults :chars :booleans);
use Bedrock::Handler qw(bind_module);
use Bedrock::XML;
use Cwd;
use Data::Dumper;
use English qw(-no_match_vars);
use File::Temp qw(tempfile tempdir);

our $BLM_STARTUP_MODULE = 'BLM::Startup::Captcha';
our $CLEANUP => 0;

########################################################################
sub slurp {
########################################################################
  my ($file) = @_;

  local $RS = undef;

  open my $fh, '<', $file
    or die "could not open $file";

  my $content = <$fh>;

  close $fh;

  return $content;
}

########################################################################
sub get_module_config {
########################################################################
  my $fh = *DATA;

  my $config = Bedrock::XML->new($fh);

  return $config->{config};
}

my $module_config = get_module_config;

my $ctx = Faux::Context->new( CONFIG => { SESSION_DIR => tempdir( CLEANUP => $CLEANUP ) } );

my $blm;

use_ok($BLM_STARTUP_MODULE);

my $config_str = Bedrock::XML::writeXMLString($module_config);

########################################################################
subtest 'bind module' => sub {
########################################################################
  $blm
    = eval { return bind_module( context => $ctx, config => $module_config, module => $BLM_STARTUP_MODULE, ); };

  ok( !$EVAL_ERROR, 'bound module' )
    or BAIL_OUT($EVAL_ERROR);

  isa_ok( $blm, $BLM_STARTUP_MODULE )
    or do {
    diag( Dumper( [$blm] ) );
    BAIL_OUT( $BLM_STARTUP_MODULE . ' is not instantiated properly' );
    };
};

########################################################################
subtest 'image_url' => sub {
########################################################################
  my $output_folder = $blm->context->{CONFIG}->{SESSION_DIR};

  $blm->output_folder($output_folder);

  my $data_folder = tempdir( CLEANUP => $CLEANUP );
  $blm->data_folder($data_folder);

  my $url = $blm->image_url;

  ok( $url, 'returned a URL' );

  ok( -s "$output_folder$url", 'image created' );

  ok( -s "$data_folder/codes.txt", 'codes.txt create' );

  my $codes = slurp("$data_folder/codes.txt");

  my $md5sum = $blm->get_md5sum();

  ok( $codes =~ /$md5sum/, 'image md5sum found in codes' );
};

done_testing;

1;

__DATA__
<object>
  <scalar name="binding">captcha</scalar>
  <scalar name="module">BLM::Startup::Captcha</scalar>
  <object name="config">
    <scalar name="verbose">2</scalar>
    <scalar name="default_length">5</scalar>
    <scalar name="data_folder"></scalar>
    <scalar name="output_folder"></scalar>
    <scalar name="image_path"></scalar>
    <scalar name="verify_folders">0</scalar>
 </object>
</object>
