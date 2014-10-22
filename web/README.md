# web/ Directory

This directory contains the client side-code of the Issue Mover for GitHub app.
The client side code of Issue Mover for GitHub handles all the requests to the
GitHub API and all the User Interface widgets like the auto-suggest input field.
All the purely static assets like [css](css) files and [images](images) are
also part of this directory.

In Dart the entry point is a `main()` method which is located in the
[gim_main.dart](gim_main.dart) file in our case. It takes care of binding all
event listener to the appropriate functions and initializes the UI.

The code that handles User Interface modification is mostly located into
[gim_ui.dart](gim_ui.dart). The code for the GitHub URL auto-suggest input field
is located in [gim_typeahead.dart](gim_typeahead.dart).

GitHub API requests are done using the
[github.dart](https://github.com/DirectMyFile/github.dart) package. Some GitHub
helper methods that were missing (like parsing the GitHub style short URLs) are
in [githubhelper.dart](githubhelper.dart).
