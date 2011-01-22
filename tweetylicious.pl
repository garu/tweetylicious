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
    $dbh->do('CREATE TABLE post (id INTEGER NOT NULL PRIMARY KEY
                                    ASC AUTOINCREMENT,
                                 username TEXT NOT NULL
                                          CONSTRAINT fk_user_username
                                          REFERENCES user(username)
                                          ON DELETE CASCADE,
                                 content TEXT NOT NULL,
                                 date INTEGER NOT NULL);'
            );
    $dbh->do('CREATE TABLE follow (id INTEGER NOT NULL PRIMARY KEY
                                      ASC AUTOINCREMENT,
                                   source TEXT NOT NULL
                                          CONSTRAINT fk_user_username
                                          REFERENCES user(username)
                                          ON DELETE CASCADE,
                                   destination TEXT NOT NULL);'
            );
  },
};


# this returns who follows our user.
# Each element is a hash of usernames and gravatars
sub get_followers_for {
    return Model->selectall_hashref(
              'SELECT username, gravatar FROM user, follow
                    WHERE user.username = follow.source
                      AND follow.destination = ?',
              'username', {} , $_[0],
            );
}


# this returns who our user follows
sub get_followed_by {
    return Model->selectall_hashref(
              'select username, gravatar from user, follow
                    where user.username = follow.destination
                      and follow.source = ?',
              'username', {}, $_[0],
        );
}


# this returns our search results
sub search_posts {
    my @items_to_search = @_;
    my $query = 'OR post.content LIKE ? ' x (@items_to_search - 1);
    return Model->selectall_arrayref(
            "SELECT user.username, post.id, gravatar, content,
                    datetime(date, 'unixepoch', 'localtime') as date
               FROM user
               LEFT JOIN post ON user.username = post.username
               WHERE post.content LIKE ? $query
               ORDER BY date DESC",
               { Slice => {} }, map { "%$_%" } @items_to_search
    );
}


# this returns sorted posts from all users in @users
sub fetch_posts_by {
    my @users = @_;
    my $query = 'OR post.username = ? ' x (@users - 1);
    return Model->selectall_arrayref(
            "SELECT user.username, post.id, gravatar, content,
                    datetime(date, 'unixepoch', 'localtime') as date
               FROM user
               LEFT JOIN post ON user.username = post.username
               WHERE post.username = ? $query
               ORDER BY date DESC",
               { Slice => {} }, @users
    );
}


# this validates registration data before we commit to the database
sub validate {
    my ($user, $pass, $pass2, $routes) = @_;
    return 'username field must not be blank' unless $user and length $user;
    return 'password field must not be blank' unless $pass and length $pass;
    return 'please re-type your password'     unless $pass2 and length $pass2;
    return "passwords don't match"            unless $pass eq $pass2;
    return 'sorry, this user already exists'
        if Model::User->count( 'WHERE username = ?', $user) > 0;

    # let's not allow usernames that are part of a valid route
    return 'sorry, invalid username'
       if grep { length $_->name and index($user, $_->name) == 0 } @$routes;

    return;
}


#-------------------------#
# now the web application #
#-------------------------#
package main;

use Mojolicious::Lite;
use Mojo::ByteStream 'b'; # for unicode and md5
use POSIX qw(strftime);

# this is a fake static route for our static data (static.js, static.css)
get '/static' => 'static';


# this controls the main index page
get '/' => 'index';


# search!
get '/search' => sub {
    my $self = shift;
    my @items = split ' ', $self->param('query');

    $self->stash( post_results => Model::search_posts(@items) );
} => 'search';


# these two control a user registering
get  '/join' => 'join';
post '/join' => sub {
    my $self  = shift;
    my $user  = $self->param('username');
    my $error = Model::validate( $user, $self->param('pwd'), $self->param('re-pwd'), app->routes->children);
    $self->stash( error => $error );
    return if $error;

    Model::User->create(
            username => $user,
            password => b(app->secret . $self->param('pwd'))->md5_sum,
            email    => $self->param('email'),
            gravatar => b($self->param('email'))->md5_sum,
            bio      => $self->param('bio'),
    );

    # auto-login the user after he joins, and show his/her homepage
    $self->session( name => $user );
    $self->redirect_to("/$user");
} => 'join';


# user login
get  '/login' => 'login';
post '/login' => sub {
    my $self = shift;
    my $user = $self->param('username') || '';

    if ( Model::User->count( 'WHERE username=? AND password=?',
           $user, b(app->secret . $self->param('password'))->md5_sum) == 1
    ) {
        $self->session( name => $user );
        return $self->redirect_to("/$user");
    }
    $self->stash( error => 1 );
} => 'login';


# user logout is just a matter of expiring the session
get '/logout' => sub {
    my $self = shift;
    $self->session( expires => 1);
    $self->redirect_to('/');
};


# this controls a user's page
get '/(.user)' => sub {
    my $self = shift;
    my $user = $self->param('user');

    # renders our error page unless the user exists
    return $self->render('not_found')
        unless Model::User->count('WHERE username = ?', $user);

    # who this user is following?
    my $following = Model::get_followed_by($user);

    # fetch posts by user and, if the user is looking at its own page,
    # show posts from people he/she is following too!
    my @targets = ( $user );
    if ($self->session('name') and $self->session('name') eq $user) {
        push @targets, keys %$following;
    }
    my $posts = Model::fetch_posts_by(@targets);

    # check if this user is already followed by our visitor,
    # so we display the appropriate "follow/unfollow" link
    if ( $self->session('name')
         and Model::Follow->count('WHERE source = ? AND destination = ?',
                                  $self->session('name'), $user)
       ) { $self->stash(followed => 1) }

    # fill our stash with information for the template
    $self->stash(
        user        => Model::User->load( $user ),
        posts       => $posts || [],
        followers   => Model::get_followers_for($user),
        following   => $following,
        total_posts => Model::Post->count('WHERE username = ?', $user),
    );
} => 'homepage';


# The rest of the routes are specific to logged in users, so we
# add a ladder to make sure (instead of making sure inside each route)
ladder sub {
    my $self = shift;
    return 1 if $self->session('name');
    $self->redirect_to('/login') and return;
};


# user wants to follow another
get '/(.user)/follow'   => sub {
    my $self = shift;
    my ($source, $target) = ($self->session('name'), $self->param('user'));

    Model::Follow->create(source => $source, destination => $target);
    $self->redirect_to("/$target");
};


# user doesn't want to follow anymore
get '/(.user)/unfollow' => sub {
    my $self = shift;
    my ($source, $target) = ($self->session('name'), $self->param('user'));
    Model::Follow->delete('WHERE source = ? AND destination = ?', $source, $target);
    $self->redirect_to("/$target");
};


# next comes actions that can only be performed if the user is
# looking at its own posts (creating and deleting posts),
# so we do another ladder
ladder sub {
    my $self = shift;
    $self->redirect_to('/')    
        unless $self->session('name') eq $self->param('user');
};


# this one handles users creating new posts ('message')
post '/(.user)/post' => sub {
    my $self = shift;
    my $user = $self->session('name');

    if( $self->param('message') ) {
        my $post = Model::Post->create(
            username => $user,
            content  => $self->param('message'),
            date     => time,
        );

        # if it's an Ajax request, return a JSON object of post and gravatar
        my $header = $self->req->headers->header('X-Requested-With') || '';
        if ($header eq 'XMLHttpRequest') {
 	    $post->{date} = strftime "%Y-%m-%d %H:%M:%S", localtime($post->{date});
            my $gravatar = Model::User->load($user)->gravatar;
            return $self->render_json({ %$post, gravatar => $gravatar });
        }
    }

    # otherwise, just render the user page again
    $self->redirect_to("/$user");
};


get '/(.user)/post/:id/delete' => sub {
    my $self = shift;

    my $post = Model::Post->select('WHERE id = ?', $self->param('id'));
    $post->[0]->delete if $post->[0];

    # if it was an Ajax request, we return a JSON object in confirmation
    my $header = $self->req->headers->header('X-Requested-With') || '';
    if ($header eq 'XMLHttpRequest') {
        return $self->render_json( {answer => 1} );
    }

    # otherwise, just render the user page again
    $self->redirect_to('/' . $self->session('name'));
};


# let's rock and roll!
app->start;


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
% if (session 'name') {
    <a href="/<%= session 'name' %>">Home</a><a href="/logout">Sign-Out</a>
% } else {
    <a href="/login">Sign-In</a><a href="/join">Join us!</a>
% }
   </div>
   <div class="search ui-widget">
    <form action="/search" method="GET">
    <input id="search" name="query" type="text" value="" /><input type="submit" value=">" />
    </form>
   </div>
  </div>

  <%= content %>

  <div id="footer" class="ui-corner-all">Tweetylicious is Powered by <a href="http://perl.org">Perl 5</a>, <a href="http://mojolicious.org">Mojolicious</a>, <a href="http://search.cpan.org/perldoc?ORLite">ORLite</a> and <a href="http://jquery.org">jQuery</a>! Released under <a href="http://dev.perl.org/licenses/">the same terms as Perl itself</a>. </div>
 </body>
</html>

@@ homepage.html.ep
% layout 'main';
% use Mojo::ByteStream 'b';
<div id="content" class="half ui-corner-left">
% if (session('name') and session('name') eq $user->{username}) {
    <h2>Hi, <%= session 'name' %>!</h2>
   <form id="post" action="<%= url_for %>/post" method="POST">
    <textarea class="ui-corner-all" cols="50" rows="3" id="message" name="message" tabindex="1"></textarea>
    <span id="charsleft"></span>
    <input id="submit" tabindex="2" type="submit" value="Tell the World!" />
   </form>
% } else {
%   if ( stash 'followed' ) {
     <a class="fineprint" href="<%= url_for %>/unfollow">[-] unfollow</a>
%   } else {
     <a class="fineprint" href="<%= url_for %>/follow">[+] follow!</a>
%   }
<h2 id="title"><%= $user->{username} %>'s posts</h2>
% }
<ul class="messages">
%# now we render all the posts in the page
% foreach my $post ( @$posts ) {
    <li class="ui-corner-all">
%# the author of the post can delete it
% if ($post->{username} eq session('name') ) {
        <a href="/<%= $post->{username} %>/post/<%= $post->{id} %>/delete" class="ui-icon ui-icon-trash" title="delete this post"></a>
% }
        <a class="who" href="/<%= $post->{username} %>"><img src="http://www.gravatar.com/avatar/<%= $post->{gravatar} %>?s=60.jpg" /><%= $post->{username} %></a><span class="what"><%= b($post->{content})->decode('UTF-8')->to_string %></span><span class="when"><%= $post->{date} %></span></li>
% }
</ul>
</div>
<div id="sub-section" class="ui-corner-right">
   <ul id="bio">
    <li><span>Name</span><%= $user->{username} %></li>
    <li><span>Bio</span><%= $user->{bio} %></li>
   </ul>
   <ul id="followers">
    <li><span><%= scalar keys %$followers %></span> Followers</li>
% foreach my $face ( keys %$followers ) {
    <li><a href="/<%= $face %>"><img src="http://www.gravatar.com/avatar/<%= $followers->{$face}->{gravatar} %>?s=20.jpg" /></a></li>
% }
   </ul>
   <ul id="following">
    <li><span><%= scalar keys %$following %></span> Following</li>
% foreach my $face ( keys %$following ) {
    <li><a href="/<%= $face %>"><img src="http://www.gravatar.com/avatar/<%= $following->{$face}->{gravatar} %>?s=20.jpg" /></a></li>
% }
   </ul>
   <div id="totalposts"><span><%= $total_posts %></span> Posts</div>
</div>

@@ login.html.ep
% layout 'main';
<div id="content" class="full ui-corner-all">
<h1>Sign-in</h1>
% if ( stash 'error' ) {
 <div class="ui-state-error ui-corner-all" style="width:466px">
     <span class="ui-icon ui-icon-alert" style="float: left; margin-right: .3em"></span><strong>Sorry, invalid username/password combination.</strong>
 </div>
 <p>Not a user yet? <a href="/join">Join now! It's free!</a></p>
 <hr />
% }
<form name="login" method="POST" action="/login">
 <table>
  <tr><td>User name:</td><td><input type="text" tabindex="1" name="username" value="<%= param 'username' %>" /></td></tr>
  <tr><td>Password:</td><td><input type="password" tabindex="2" name="password" value="<%= param 'password'%>" /></td></tr>
 </table>
<input tabindex="3" type="submit" value="Login!"/>
</form>
</div>

@@ join.html.ep
% layout 'main';
<div id="content" class="full ui-corner-all">
<h1>Join us, it's free!</h1>
% if (my $error = stash 'error') {
 <div class="ui-state-error ui-corner-all" style="width:450px">
     <span class="ui-icon ui-icon-alert" style="float: left; margin-right: .3em"></span><strong>Sorry:</strong> <%= $error %>
 </div>
 <hr />
% }
<form name="join" method="POST">
 <table>
  <tr><td>Username</td><td><input name="username" type="text" tabindex="1" value="<%= param 'username' %>" /></td></tr>
  <tr><td>Password</td><td><input name="pwd" type="password" tabindex="2" value="<%= param 'pwd' %>" /></td></tr>
  <tr><td>Password (again)</td><td><input name="re-pwd" type="password" tabindex="3" value="<%= param 're-pwd' %>" /></td></tr>
  <tr><td>Email</td><td><input name="email" type="text" tabindex="4" value="<%= param 'email' %>" /></td></tr>
  </table>
  <span class="fineprint">Email is optional, and doesn't show in your page. It's used only to fetch your <a href="http://gravatar.com">gravatar</a></span>
 <p>Tell us a bit about yourself - everyone will see it on your page</p>
 <textarea class="ui-corner-all" tabindex="5" cols="50" rows="3" id="message" name="bio"><%= param 'bio' %></textarea>
 <input type="submit" tabindex="6" value="Create!" />
</form>
</div>

@@ search.html.ep
% layout 'main';
% use Mojo::ByteStream 'b';
<div id="content" class="full ui-corner-all" style="text-align:left">
<h1>Results for '<%= param 'query' %>'</h1>

 <ul class="messages">
% foreach my $post (@$post_results) {
    <li class="ui-corner-all">
%# the author of the post can delete it
% if ($post->{username} eq session('name') ) {
        <a href="/<%= $post->{username} %>/post/<%= $post->{id} %>/delete" class="ui-icon ui-icon-trash" title="delete this post"></a>
% }
        <a class="who" href="/<%= $post->{username} %>"><img src="http://www.gravatar.com/avatar/<%= $post->{gravatar} %>?s=60.jpg" /><%= $post->{username} %></a><span class="what"><%= b($post->{content})->decode('UTF-8')->to_string %></span><span class="when"><%= $post->{date} %></span></li>
% }
 </ul>
</div>

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

@@ not_found.html.ep
% layout 'main';
<div id="content" class="full ui-corner-all">
<h3>Sorry, we couldn't find the page you were looking for :-(</h3>
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
    $("#submit").button();

    // search bar effects
    var searchDefault = "Search Tweetylicious...";
    $("#search").val(searchDefault);
    $("#search").focus( function() {
        if($(this).val() == searchDefault) $(this).val("");
    });
    $("#search").blur(function(){
        if($(this).val() == "") $(this).val(searchDefault);
    });

    // showing how many characters are left
    $("#charsleft").text("140 characters left");
    $("#message").keyup(function() {
       var left = 140 - $("#message").val().length;
       if (left < 0 ) {
         $("#charsleft").removeClass("orange").addClass("red");
         $("#submit").button("option", "disabled", true);
       } else {
         $("#submit").button("option", "disabled", false);
         if (left < 40) {
           $("#charsleft").removeClass("red").addClass("orange");
         } else {
           $("#charsleft").removeClass("red").removeClass("orange");
         }
       }
       $("#charsleft").text( left + ' characters left' );
    });

    // highlighting selection
    $("#content ul.messages li").hover(
        function() { $(this).animate( {backgroundColor:'#ded'}, 400 ); },
        function() { $(this).animate( {backgroundColor:'#efe'}, 400 ); }
    );

    /* if user has javascript enabled, we turn
       'delete post' and 'tell the world' buttons into Ajax
       (well, actually Ajaj, since we use JSON ;) */
    function send_to_trash(event) {
        event.preventDefault();
        var item = this;
        var href = $(item).attr("href");
        $.getJSON(href, function(json) {
          if (json.answer) {
            $(item).parent("li").hide("explode", {}, 1000);
          }
        });
    }
    $("a.ui-icon").click(send_to_trash);

    $("#submit").click(function(event) {
        event.preventDefault();
        var href = $("#post").attr("action");
        $.post(href, $("#post").serialize(), function(data) {
            $("#message").text("");
            $("#content ul").prepend('<li style="display:none" class="ui-corner-all"><a href="/' + data.username + '/post/' + data.id + '/delete" class="ui-icon ui-icon-trash" title="delete this post"></a><a class="who" href="/' + data.username + '"><img src="http://www.gravatar.com/avatar/' + data.gravatar + '?s=60.jpg" />' + data.username + '</a><span class="what">' + data.content + '</span><span class="when">' + data.date + '</span></li>');
            $("#content li:first").show("drop", {}, 1000);
            $("#content li:first").find("a.ui-icon").click(send_to_trash);
        }, "json");
    });

    // formatting our content
    $(".what").each(function() {
        var message = $(this).html()
                  .replace(/@(\w+)/g, "@<a href=\"/$1\">$1</a>")
                  .replace(/#(\w+)/g, "<a href=\"/search?query=%23$1\">#$1</a>");
        $(this).html(message);
    });
});

