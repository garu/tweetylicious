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

use ORLite {
  file    => 'tweetylicious.db',
  cleanup => 'VACUUM',
  create  => sub {
    my $dbh = shift;
    $dbh->do('CREATE TABLE user (username TEXT NOT NULL UNIQUE PRIMARY KEY,
                                 password TEXT NOT NULL,
                                 email    TEXT,
                                 gravatar TEXT,
                                 bio      TEXT
                                );'
            );
  },
};


#-------------------------#
# now the web application #
#-------------------------#
package main;

use Mojolicious::Lite;

# this is a fake static route for our static data (static.js, static.css)
get '/static' => 'static';


# this controls the main index page
get '/' => 'index';


# let's rock and roll!
shagadelic;


#------------------------#
# finally, the templates #
#------------------------#
__DATA__
@@ layouts/main.html.ep
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
 <head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <title>Tweetylicious</title>
  <link type="text/css" href="http://ajax.googleapis.com/ajax/libs/jqueryui/1.8/themes/dark-hive/jquery-ui.css" rel="Stylesheet" />
  <link type="text/css" rel="stylesheet" media="screen" href="/static.css" rel="Stylesheet" />
  <script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js"></script>
  <script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jqueryui/1.8/jquery-ui.min.js"></script>
  <script type="text/javascript" src="/static.js"></script>
 </head>
 <body>
  <div id="header"><a href="/"><div id="logo">Tweetylicious!</div></a>
   <div class="options">
    <a href="/login">Sign-In</a><a href="/join">Join us!</a>
   </div>
  </div>

  <%= content %>

  <div id="footer" class="ui-corner-all">Tweetylicious is Powered by <a href="http://perl.org">Perl 5</a>, <a href="http://mojolicious.org">Mojolicious</a>, <a href="http://search.cpan.org/perldoc?ORLite">ORLite</a> and <a href="http://jquery.org">jQuery</a>! Released under <a href="http://dev.perl.org/licenses/">the same terms as Perl itself</a>. </div>
 </body>
</html>


@@ index.html.ep
% layout 'main';
<div id="content" class="info full ui-corner-all">

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

@@ static.css.ep
  body {
    width:720px;
    margin:0 auto;
    text-align:center;
    background: #0f1923; /* #333; */
    border:0;
  }
  a { text-decoration: none }

  #header,#content,#sub-section,#footer {
    overflow:hidden;
    display:inline-block;
    text-align:left
  }
  #header li { display: inline }
  #logo {
    float: left;
    background: #0972a5;
    height: 60px;
    font-family: "Georgia", "Times New Roman", serif;
    font-size: 26px;
    color: #eee;
    padding: 50px 10px 10px 10px;
  }
  .options { text-align: right; margin-left: 450px; margin-top: -5px }
  .search { float: right; margin-top: 50px }
  #search { background-color: #bbb; color: #444; width: 200px; font-size: 16px; }
  #content {
    background: #efe;
    font-family: "Verdana", sans-serif;
    min-height: 100px;
    padding-left: 10px;
  }
  h1 { font-size: 1.2em }
  #title { margin-left: 30px; }
  .half { width: 78.7% }
  .full { width: 100% }
  .fineprint { font-size: 0.6em }
  ul { margin: 0; padding: 0; list-style: none; list-style-position: outside; }
  .info { padding-bottom: 10px }
  .info ul { list-style-type: square}
  .info ul li{ margin-bottom:10px }
  #content ul {
    display: block;
    width: 90%;
    margin: 10px auto;
  }
  #content ul.messages li {
    border-top: 1px solid #ddd;
    padding-top: 16px;
    height: 70px;
    margin-top: 10px;
  }
  .when { display: block; font-size: 10px; color: #aaa; }
  img { float: left; margin: 1px; border: 0 }
  #content .ui-icon { float: right; position: relative; top: -10px; right: 10px }
  #content a:hover.ui-icon { border: 1px #ff0 dashed }
  #content a { text-decoration: none }
  .who { margin-right: 8px; font-weight: bold }
  #sub-section {
    width: 20%;
    background: #ccc;
    font: 0.8em "Verdana", sans-serif;
  }
  #message {
    border: 1px solid #aaa;
    padding: 4px 2px;
    resize: none;
    font-size: 1.15em;
    font-family: sans-serif;
    color: #333;
  }
  #post {
    margin: 10px 50px 30px 50px;
  }
  #post input { margin-right: 54px; float: right; font-size: 0.6em; }
  #charsleft {
    display: block;
    float: left;
    font-weight: bold;
  }
  .orange { color: #ff6300 }
  .red    { color: #d11 }
  #bio li { margin: 6px; line-height: 1em; }
  #bio span, #followers span, #following span, #totalposts span {
      font-weight: bold;
      margin-right: 4px;
  }
  #followers li, #following li { margin: 1px }
  #followers, #following, #totalposts { clear: both; margin-left: 5px; padding-top: 10px }
  /* safari and opera need this */
  #header,#footer {width:100%}

  #content,#sub-section {float:left; margin-top: 20px; min-height: 360px; }
  #footer {clear:left; margin: 20px auto; padding-top: 10px;height: 26px; background: #555; color: #ccc; font-size:12px; text-align: center; }
  #footer a { text-decoration: none; color: #eee }

@@ static.js.ep
$(function() {
    // creating our buttons
    $(".options").find("a").button();
});

