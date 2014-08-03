tweetylicious
=============

a Twitter-like microblogging app in just one file

Tweetylicious - a Twitter-like microblogging app in just one file!
http://onionstand.blogspot.com/2010/06/tweetylicious-twitter-like.html

What is Tweetylicious?

Tweetylicious is a microblogging web application in a single file! It was built from scratch using state of the art technology, and is meant to demonstrate how easy and fun it is to create your own Web applications in modern Perl 5!

What are its features?
Multi-user, with homepages, search and list of followers/following
Nice, clean, pretty interface (at least I think so :P)
User avatar images provided by gravatar
Unicode support
Well structured, commented code, easy to expand and customize
Encrypted online sessions
Uses an actual database (SQLite) and stores encrypted user password
Free and Open Source Software, released under the same terms as Perl itself.
How can you fit all that in a 'single file'?! It's gotta be huge and clobbered then!

Not at all! Tweetylicious is built on top of Mojolicious::Lite and ORLite, two very simple modules that have absolutely no dependency other than Perl 5 itself. Mojolicious::Lite allows you to create powerful web applications in a very simple and clean fashion, while also letting you integrate your templates on the bottom of the file. ORLite is an extremely lightweight ORM for SQLite databases that lets you specify your schema on the fly.

Removing just blank lines and comments, the Model has ~80 lines, the Controller ~110 lines, templates ~170 lines, plus ~90 lines of static css and ~60 of static javascript. And that's the whole app.

But don't take my word for it, just browse through it :)

What do I need to make it work on my own system?

Perl 5 (if you're running Linux or Mac, you already have it! Windows users can get it here)
SQLite 3
Mojolicious
ORLite
Tweetylicious also relies on the powerful jQuery JavaScript library, but that's downloaded and processed by the clients browser, so don't worry about it. Each user's avatar image is also provided externally, via gravatar.

Have fun!
