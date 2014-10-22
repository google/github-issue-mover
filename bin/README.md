# bin/ Directory

This directory contains the server side-code of the Issue Mover for GitHub app.
The server side code of Issue Mover for GitHub takes care of the OAuth 2.0
authorization flow for the app and then passes the OAuth access token to the
client using a Cookie.

The file [server.dart](server.dart) is the entry point of the program and starts
a [Force MVC](https://github.com/ForceUniverse/dart-forcemvc) HTTP Server.
That's where you specify which folders contain client-side (static) resources.
Just like for most Dart apps we serve the compiled client side resources that
are located in **../build/web**.

All the request handling and routing is defined in the Controller
[controllers/oauth_controller.dart](controllers/oauth_controller.dart). Force
MVC allows to easily map a path to a method using annotations.

The controller methods takes care of either redirecting users to another URL or
displaying a "view" which are basically web pages (templates) into which values
of the Model can be injected. For example in some cases we inject an error
message into the [views/index.html](views/index.html) view and sometimes serve
it directly.

[logic/oauth_credentials.dart](logic/oauth_credentials.dart) is a utility that
loads the OAuth 2.0 application credentials from 2 different files depending on
the environment:

 - [credentials.yaml](credentials.yaml) that's used in production (with **github-issue-mover.appspot.com** as the redirect URI)
 - [credentials_dev.yaml](credentials_dev.yaml) that's used during development (with **localhost** as the redirect URI)

The [logic/cookies.dart](logic/cookies.dart) provides utilities to easily pass
the access token and error messages as cookies in the request.
