# PUBLIC

BLM::Startup::Captcha

# SYNOPSIS

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

# DESCRIPTION

Implements a Bedrock Application Plugin that uses [Authen::Captcha](https://metacpan.org/pod/Authen%3A%3ACaptcha)
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
values (`md5sum`). Th Captcha Plugin makes an image and the digest
value available to you. So...

- 1. Create and display the image that is available via the `image_url()` method
- 2. Ask the user to enter the digits
- 3. Submit the digits the user guesses along with the digest
value you got from the `$captcha.get_md5sum()` method to the 
`$capcha.verify()` method.

The `$captcha` object recalculates the digest value based on the
digits sent and compares that to the digest value originally sent to
you.  If they match, then presumably the user entered the correct
digits since the digest calculation is sufficiently unique that any
variation in the digits would have resulted in digests that don't
match.

# NOTES

When installed, the `BLM::Startup::Captcha` installs a configuration
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

- binding

    The binding name. default: captcha

- data\_folder

    The location for [Authen::Captcha](https://metacpan.org/pod/Authen%3A%3ACaptcha) to store its database of
    information.

- output\_folder

    The directory where images will be stored (`output_folder`).  

- image\_path

    The path relative to your web server's root where users can access the
    captcha image. This path should be path translated by your web server
    to the output folder.

- verify\_folders

    Boolean that indicates whether or not to verify the existence of the
    folders. You can set the folders after instantiation of the class
    using the `output_folder()` and `data_folder()` methods.

Configure these values based on your needs.  Since the
`output_folder` will serve up your graphic, it will require
appropriate permissions.

## Using a Session Directory as the `output_folder`

Set the configuration variable `use_session` to use a session
directory as the output for image creation.  Using Bedrock's
[Bedrock::Apache::BedrockSessionFiles](https://metacpan.org/pod/Bedrock%3A%3AApache%3A%3ABedrockSessionFiles) handler will allow your
webserver to serve files from a user's session directory.

Using session directories has a couple of advantages:

- restricts access of the captcha image to a specific user
- session directories can be cleaned up automatically up after a session expires
- using a session directory that is accessible by multiple
webserver nodes (an NFS or EFS mount e.g) will help create a stateless
webnode

See [Bedrock::Apache::BedrockSessionFiles](https://metacpan.org/pod/Bedrock%3A%3AApache%3A%3ABedrockSessionFiles) for details on setting up
session directories.

# METHODS AND SUBROUTINES

## image

image( \[num-digits\] )

Creates and returns the name of an image composed of `num-digits`
characters and sets the `md5sum` element of the object. **This method is not designed to be used directly.**

_Use `image_url()` to return the URL of the image._

&lt;img src="&lt;var $captcha.image\_url(5)>">&amp;nbsp;&lt;input type="text" name="code" size="5">
&lt;input type="hidden" name="md5sum" value="&lt;var $captcha.md5sum>">

## verify

verify( digits, md4sum )

Returns an integer value that indicates whether the digits sent match
the captcha.

- "1" => Passed
- "0" => Code not checked (file error)
- "-1" => Failed: code expired
- "-2" => Failed: invalid code (not in database)
- "-3" => Failed: invalid code (code does not match crypt)

## errstr

    errstr

Text version of error message.

## verify\_text

Verifies the captcha code and returns the text version of the return
code instead of a return code.

## image\_url

Returns the URL for the captcha image.

## verify\_or\_reset\_image

    verify_or_reset_image( input-object )

Attempts to verify the code and md5sum for the most recent
image. Returns a hash containing:

- success

    Success ("1") or failure code.

- errstr

    The error string if failure

- your\_code

    The code you sent

- your\_md5sum

    The md5sum you sent

- image

    Newly generated image if verification fails.

- md5sum

    The md5sum for the newly generated image.

# AUTHOR

Rob Lauer - <rlauer6@comcast.net>

# SEE ALSO

[Authen::Captcha](https://metacpan.org/pod/Authen%3A%3ACaptcha), [Bedrock::Apache::BedrockSessionFiles](https://metacpan.org/pod/Bedrock%3A%3AApache%3A%3ABedrockSessionFiles)
