<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-15">
    <title>Captcha Test</title>
    <style>
      .container {
      display: flex;
      align-items: center; /* Aligns the image vertically center with the div */
      }
      
      .image {
      max-width: 100px; /* Adjust image size as needed */
      height: auto;
      }
      
      .text {
      margin-left: 20px; /* Space between image and div */
      }

    </style>
  </head>
  
  <body>
    <h1>Captcha Test</h1>
    <if $input.code>
      <try>
        <if $captcha.verify($input.code, $input.md5sum) --ne "1">
          <raise "try again">
        <else>
          Success!
        </if>
      <catch>
        Too bad - <var $@>
      </try>
    <else>
      <form action="/captcha.roc" method="post">
        <div id="captcha">
          <div class="container">
            <img src="<var $captcha.image_url()>" class="image">
            <div class="text">
            <input type="hidden" name="md5sum" value="<var $captcha.get_md5sum()>">
            <input type="text" name="code" value="" size="10">
            <button>Submit</button>
            </div>
          </div>

        </div>
      </form>
    </if>
    <hr>
    <address></address>
    <!-- hhmts start -->Last modified: Fri Feb 21 13:23:18 EST 2025 <!-- hhmts end -->
  </body>
</html>
