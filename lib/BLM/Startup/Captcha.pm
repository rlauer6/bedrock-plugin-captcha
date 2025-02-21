package BLM::Startup::Captcha;
# poor man's captcha via Authen::Captcha
# ...when good enough is good enough

use strict;
use warnings;

use Authen::Captcha;
use Data::Dumper;
use English qw(-no_match_vars);

our $VERSION = '2.0.0';

use parent qw(Bedrock::Application::Plugin Class::Accessor::Fast);

__PACKAGE__->follow_best_practice();
__PACKAGE__->mk_accessors(
  qw(
    md5sum
    errno
    captcha
    data_folder
    output_folder
    verify_folders
  )
);

use Readonly;

Readonly::Hash our %VERIFY_TEXT => (
  1  => 'Passed',
  0  => 'Code not checked',
  -1 => 'Failed: code expired',
  -2 => 'Failed: invalid code (not in database)',
  -3 => 'Failed: invalid code (code does not match crypt)',
);

Readonly::Scalar our $TRUE           => 1;
Readonly::Scalar our $FALSE          => 0;
Readonly::Scalar our $DEFAULT_LENGTH => 5;

########################################################################
sub init_plugin {
########################################################################
  my ($self) = @_;

  $self->set_captcha( Authen::Captcha->new );
  my $config = $self->config;

  if ( $config->get('use_session') ) {
    my $data_folder = eval {
      $self->set_output_folder( $self->session->create_session_dir );
      return $self->set_data_folder( $self->session->create_session_dir );
    };

    die "no output folder\n$EVAL_ERROR"
      if $EVAL_ERROR || !$data_folder;
  }
  else {
    $self->set_output_folder( $config->get('output_folder') );
    $self->set_data_folder( $config->get('data_folder') );
  }

  my $verify_folders = $config->get('verify_folders');

  if ( ( !defined $verify_folders ) || $verify_folders ) {
    die "No directory for data folder.\n"
      if !-d $self->get_data_folder();

    die "No directory for output folder.\n"
      if !-d $self->get_output_folder();
  }

  $self->get_captcha->data_folder( $self->get_data_folder() );

  $self->get_captcha->output_folder( $self->get_output_folder() );

  return $TRUE;
}

########################################################################
sub data_folder {
########################################################################
  my ( $self, $folder ) = @_;

  return $self->get_captcha->data_folder($folder);
}

########################################################################
sub output_folder {
########################################################################
  my ( $self, $folder ) = @_;

  return $self->get_captcha->output_folder($folder);
}

########################################################################
sub image {
########################################################################
  my ( $self, $number_of_characters ) = @_;
  $number_of_characters ||= $self->config->get('default_length') || $DEFAULT_LENGTH;

  # create a captcha. Image filename is "$md5sum.png"
  $self->set_md5sum( scalar $self->get_captcha->generate_code($number_of_characters) );

  return sprintf '%s.png', $self->get_md5sum();
}

########################################################################
sub verify {
########################################################################
  my ( $self, $code, $md5sum ) = @_;

  my $retcode = $self->get_captcha->check_code( $code, $md5sum );

  $self->set_errno($retcode);

  return $retcode;
}

########################################################################
sub errstr {
########################################################################
  my ($self) = @_;

  return $self->verify_text( $self->get_errno() );
}

########################################################################
sub get_errstr { goto &errstr; }
########################################################################

########################################################################
sub verify_text {
########################################################################
  my $self = shift;

  return $VERIFY_TEXT{ $self->verify(@_) };
}

########################################################################
sub image_url {
########################################################################
  my ($self) = @_;

  my $image_path = $self->config->get('use_session') ? '/session' : $self->config->get('image_path');

  die "image path is undefined\n"
    if !defined $image_path;

  return sprintf '%s/%s', $image_path, $self->image();
}

########################################################################
sub verify_or_reset_image {
########################################################################
  my ( $self, $input ) = @_;

  my $session = $self->session;

  # assume we're not verified
  $session->set( captcha_verified => $FALSE );

  my %rsp = (
    success     => $self->verify( $input->{code}, $input->{md5sum} ),
    errstr      => $self->errstr(),
    your_code   => $input->{code},
    your_md5sum => $input->{md5sum},
  );

  if ( $rsp{success} eq '1' ) {
    $session->set( 'captcha_verified', $TRUE );
    $rsp{errstr} = q{};
  }
  else {
    $rsp{image}  = $self->image_url();
    $rsp{md5sum} = $self->get_md5sum();
  }

  return Bedrock::Hash->new(%rsp);
}

1;

## no critic (RequirePodSections)

__END__

=pod

=head1 PUBLIC

BLM::Startup::Captcha

=head1 SYNOPSIS

 <if $input.code >
   <if $captcha.verify($input.code, $input.md5sum) --eq "1">
     Success!
   <else>
     Error: <var $input.code> : <var $captcha.errstr()>
   </if>
 <else>
   <form name="captcha" method="post" action="captcha.roc">
     <img src="<var $captcha.image_url()>" align="absmiddle">&nbsp;
     <input type="text" name="code">&nbsp;
     <input type="submit" value="Submit">
     <input type="hidden" value="<var $captcha.get_md5sum()>" name="md5sum">
   </form>
 </if>


=head1 DESCRIPTION

Implements a Bedrock Application Plugin that uses L<Authen::Captcha>
... "for creating captcha's to verify the human element in
transactions."

The idea here is to show the user a graphic that is sufficiently
ambiguous such that only a human (or at least some humans) in theory
can decode it.  The user then enters the digits that he sees and we
report back on whether they were correct. In practice, there are
probably people with so much time on their hands that they could
figure out image filters that might crack the algorithm.  A "number of
tries" lockout might be appropriate.

The link between the image and the actual digits is via a digest
values (C<md5sum>). Th Captcha Plugin makes an image and the digest
value available to you. So...

=over 5 

=item 1. Create and display the image that is available via the C<image_url()> method

=item 2. Ask the user to enter the digits

=item 3. Submit the digits the user guesses along with the digest
value you got from the C<$captcha.get_md5sum()> method to the 
C<$capcha.verify()> method.

=back

The C<$captcha> object recalculates the digest value based on the
digits sent and compares that to the digest value originally sent to
you.  If they match, then presumably the user entered the correct
digits since the digest calculation is sufficiently unique that any
variation in the digits would have resulted in digests that don't
match.

=head1 NOTES

When installed, the C<BLM::Startup::Captcha> installs a configuration
file similar to the one shown below.

  <object>
    <scalar name="binding">captcha</scalar>
    <scalar name="module">BLM::Startup::Captcha</scalar>
  
    <object name="config">
      <scalar name="verbose">2</scalar>
      <scalar name="default_length">5</scalar>
      <scalar name="data_folder">/var/www/session</scalar>
      <scalar name="output_folder">/var/www/img/png</scalar>
      <scalar name="image_path">/img/png</scalar>
      <scalar name="verify_folders">1</scalar>
    </object>
  
  </object>

The relevant configuration values here are:

=over 5

=item * binding

The binding name. default: captcha

=item * data_folder

The location for L<Authen::Captcha> to store its database of
information.

=item * output_folder

The directory where images will be stored (C<output_folder>).  

=item * image_path

The path relative to your web server's root where users can access the
captcha image. This path should be path translated by your web server
to the output folder.

=item * verify_folders

Boolean that indicates whether or not to verify the existence of the
folders. You can set the folders after instantiation of the class
using the C<output_folder()> and C<data_folder()> methods.

=back

Configure these values based on your needs.  Since the
C<output_folder> will serve up your graphic, it will require
appropriate permissions.


=head2 Using a Session Directory as the C<output_folder>

Set the configuration variable C<use_session> to use a session
directory as the output for image creation.  Using Bedrock's
L<Bedrock::Apache::BedrockSessionFiles> handler will allow your
webserver to serve files from a user's session directory.

Using session directories has a couple of advantages:

=over 5

=item * restricts access of the captcha image to a specific user

=item * session directories can be cleaned up automatically up after a session expires

=item * using a session directory that is accessible by multiple
webserver nodes (an NFS or EFS mount e.g) will help create a stateless
webnode

=back

See L<Bedrock::Apache::BedrockSessionFiles> for details on setting up
session directories.

=head1 METHODS AND SUBROUTINES

=head2 image

image( [num-digits] )

Creates and returns the name of an image composed of C<num-digits>
characters and sets the C<md5sum> element of the object. B<This method is not designed to be used directly.>

I<Use C<image_url()> to return the URL of the image.>

<img src="<var $captcha.image_url(5)>">&nbsp;<input type="text" name="code" size="5">
<input type="hidden" name="md5sum" value="<var $captcha.md5sum>">


=head2 verify

verify( digits, md4sum )

Returns an integer value that indicates whether the digits sent match
the captcha.

=over 5

=item *  "1" => Passed

=item * "0" => Code not checked (file error)

=item * "-1" => Failed: code expired

=item * "-2" => Failed: invalid code (not in database)

=item * "-3" => Failed: invalid code (code does not match crypt)

=back

=head2 errstr

 errstr

Text version of error message.

=head2 verify_text

Verifies the captcha code and returns the text version of the return
code instead of a return code.

=head2 image_url

Returns the URL for the captcha image.

=head2 verify_or_reset_image

 verify_or_reset_image( input-object )

Attempts to verify the code and md5sum for the most recent
image. Returns a hash containing:

=over 5

=item success

Success ("1") or failure code.

=item errstr

The error string if failure

=item your_code

The code you sent

=item your_md5sum

The md5sum you sent

=item image

Newly generated image if verification fails.

=item md5sum

The md5sum for the newly generated image.

=back

=head1 AUTHOR

Rob Lauer - <rlauer6@comcast.net>

=head1 SEE ALSO

L<Authen::Captcha>, L<Bedrock::Apache::BedrockSessionFiles>

=cut
