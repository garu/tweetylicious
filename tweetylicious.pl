#!/usr/bin/perl
#==================================================#
# Tweetylicious! A one-file microblog application  #
#--------------------------------------------------#
# this file is meant as an example of how easy it  #
# is to create cool web applications using cutting #
# edge technology, with Perl 5, JavaScript and     #
# just a few lines of code!                        #
#                                                  #
# Tweetylicious is meant as a hommage to Twitter,  #
# a very cool micro-blogging site, but is in no    #
# way affiliated with it. We hope this work, which #
# is released for free as open source software     #
# (see LICENSE in the bottom), will stimulate      #
# all the young minds out there to create even     #
# more amazing stuff. Viva la revolution! :)       #
#==================================================#

#--------------------------------------#
# first we create our database (model) #
#--------------------------------------#
package Model;


#-------------------------#
# now the web application #
#-------------------------#
package main;

use Mojolicious::Lite;


# this controls the main index page
get '/' => 'index';


# let's rock and roll!
shagadelic;


#------------------------#
# finally, the templates #
#------------------------#
__DATA__
@@ index.html.ep
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
 <head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <title>Tweetylicious</title>
 </head>
 <body>
  <div id="header"><a href="/"><div id="logo">Tweetylicious!</div></a>
  </div>

   <div id="content">

   <h1>What is Tweetylicious?</h1>
   <p>Tweetylicious is a <a href="http://en.wikipedia.org/wiki/Micro-blogging">microblogging</a> web application in a single file! It was built from scratch using state of the art technology, and is meant to demonstrate how easy and fun it is to create your own Web applications in modern Perl 5!</p>

   <h1>What are its features?</h1>
   <ul>
    <li>Multi-user, with homepages, search and list of followers/following</li>
    <li>Nice, clean, pretty interface (at least I think so :P)</li>
    <li>User avatar images provided by <a href="http://gravatar.com">gravatar</a></li>
    <li>Unicode support</li>
    <li>Well structured, commented code, easy to expand and customize</li>
    <li>Encrypted online sessions</li>
    <li>Uses an actual database (SQLite) and stores encrypted user password</li>
    <li>Free and Open Source Software, released under the same terms as Perl itself.</li>
   </ul>

   <h1>How can you fit all that in a 'single file'?! It's gotta be huge and clobbered then!</h1>
   <p>Not at all! Tweetylicious is built on top of Mojolicious::Lite and ORLite, two very simple modules that have absolutely no dependency other than Perl 5 itself. Mojolicious::Lite allows you to create powerful web applications in a very simple and clean fashion, while also letting you integrate your templates on the bottom of the file. ORLite is an extremely lightweight ORM for <a href="http://sqlite.org">SQLite</a> databases that lets you specify your schema on the fly.</p>
   <p>Removing just blank lines and comments, the Model has ~80 lines, the Controller ~110 lines, templates ~170 lines, plus ~90 lines of static css and ~60 of static javascript. And that's the <strong>whole</strong> app.</p>
   <p>But don't take my word for it, just browse through it :)</p>

   <h1>What do I need to make it work on my own system?</h1>

   <ul>
    <li>Perl 5 <span class="fineprint">(if you're running Linux or Mac, you already have it! Windows users can get it <a href="http://strawberryperl.com">here</a>)<span></li>
    <li>SQLite 3</li>
    <li>Mojolicious</li>
    <li>ORLite</li>
   </ul>

   <p>Tweetylicious also relies on the powerful jQuery JavaScript library, but that's downloaded and processed by the clients browser, so don't worry about it. Each user's avatar image is also provided externally, via gravatar.</p>

   <p>Have fun!</p>
   </div>

  <div id="footer">Tweetylicious is Powered by <a href="http://perl.org">Perl 5</a>, <a href="http://mojolicious.org">Mojolicious</a>, <a href="http://search.cpan.org/perldoc?ORLite">ORLite</a> and <a href="http://jquery.org">jQuery</a>! Released under <a href="http://dev.perl.org/licenses/">the same terms as Perl itself</a>. </div>
 </body>
</html>


