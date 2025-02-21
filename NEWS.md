This is the `NEWS` file for the `libbedrock-captcha-perl`
project. This file contains information on changes since the last
release of the package, as well as a running list of changes from
previous versions.  If critical bugs are found in any of the software,
notice of such bugs and the versions in which they were fixed will be
noted here, as well.

-----------------------------------------------------------------------

libbedrock-captcha-perl 1.1.0 (2018-05-16)

    Enhancements:

    - Use session directory. Set the `use_session` configuration
      variable in the `captcha.xml` BLM config file to 1 to use the
      Bedrock session directory for serving up captcha images.  Note:
      You must install Bedrock's Bedrock::Apache::BedrockSessionFiles
      handler.

   Breaking Changes:

   - md5sum is no longer an attribute of the $captcha object. Use the
     $captcha.get_md5sum() method.

    Fixes:

    (None)

-----------------------------------------------------------------------

libbedrock-captcha-perl 1.0.1 (2012-10-23)

    Enhancements:

    (None)

    Fixes:

    - use BEDROCK_CONFIG m4 macro

    - verify_text() method did not return the text from the message hash
      correctly. Now does.

-----------------------------------------------------------------------

libbedrock-captcha-perl 1.0.0 (2012-10-07)

    Enhancements:

    - First release of `libbedrock-captcha-perl'

    Fixes:

    (None)
