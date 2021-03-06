![Cat with Remote](http://farm4.staticflickr.com/3052/2432148351_1ba6ae6f5b.jpg)

NAME
====

tom - Control tomcat from the command line with simplicity

SYNOPSIS
========

    > tom available
    > tom install 5.5.35
    > tom list
    > tom up 5.5.35
    > tom down
    > tom restart
    > tom ping
    > tom version 6.0.35
    > tom uninstall 5.5.35

COMMANDS
========

up
--

    tom up [VERSION]

Starts up the version of tomcat specified or the default version if the
version is omitted.

down
----

    tom down

Shutsdown the currently running tomcat instance


restart
-------

    tom restart [VERSION] [OPTIONS]

Restarts a currently running instance of tomcat if one is running
otherwise it just starts a new instance. Can specify the host, port and
timeout (in seconds) for testing if a tomcat instance is currently
running.


list
----

    tom list

List all installed versions of Tomcat


ping
----

    tom ping [OPTIONS]

Test if a HTTP server is running at a given host and port combination,
can also specify a timeout in seconds. The default host is "localhost",
the default port is 8080, and the default timeout is 2 seconds.


version
-------

    tom version VERSION

Set a default version


available
---------

    tom available

List all versions of Tomcat that are available for install


uninstall
---------

    tom uninstall VERSION

Uninstalls a version of Tomcat


install
-------

    tom install VERSION

Installs a version of Tomcat


deploy
------

    tom deploy [VERSION] WARFILE|DIRECTORY

Deploy a web application to a given version of Tomcat via a warfile or
directory.


help
----

    tom help

Displays a help message


REQUIREMENTS
============

General
-------

perl 5.10 or greater

HTTP::Tiny

Mojo::DOM 3.38

File::Tail

Windows
-------
    
7za (the command line version of 7zip) installed in `C:\Users\[USERNAME]\bin`
for install comand

Unix
----

GNU tar (on PATH) for install command

AUTHOR
======
    
Delon Newman &lt;delon.newman@gmail.com&gt;

