# UNFORTUNATELY THIS TOOL IS NOW DEPRECATED

Reasons for deprecation:
 - The deprecation of AppEngine Custom VM
 - GitHub releasing a similar built-in feature
 - Now low(er) usage (Since Github launched their "move issues feature within the same organization)
 
 If you are interrested in updating the tool, port it to a supported AppEngine VM and update the Dart code so that it compiles let the owner know.

# Issue Mover for GitHub

This tool make it easy to migrate issues between repos:
 - Copy the issue in the destination repo
 - Add references between the issues
 - Close the original issue
 
Issue Mover for GitHub has been written entirely in [Dart](http://www.dartlang.org)
(both client side and server side code) and is hosted on [Google App Engine Managed VM](https://cloud.google.com/appengine/docs/managed-vms/).
For a walk through of the code and backend deployment options please read [CODE_WALKTHROUGH](CODE_WALKTHROUGH.md)

## Usage

The tool is hosted online at [github-issue-mover.appspot.com](https://github-issue-mover.appspot.com/)

It looks like this:

<img width="600px" src="https://github.com/google/github-issue-mover/raw/master/README_assets/app.png">


## How to use

You can copy paste full GitHub URLs. For instance you can copy paste

`https://github.com/google/github-issue-mover/issues/1`

into the "Issue to Move" text field. It will get automatically transformed to the _short_ GitHub URL:

`google/github-issue-mover#1`

The tool will extract some information about the issue if it's accessible to your user:

<img width="300px" src="https://github.com/google/github-issue-mover/raw/master/README_assets/issue.png">

You can do the same for the "Destination Repo" text field and copy paste:

`https://github.com/nicolasgarnier/drive-music-player`

It will get automatically transformed to the _short_ GitHub URL for repos:

`nicolasgarnier/drive-music-player`

and some information will get extracted as well:

<img width="300px" src="https://github.com/google/github-issue-mover/raw/master/README_assets/repo.png">

Once existing issue and repo have been set you can start the move process:

<img width="300px" src="https://github.com/google/github-issue-mover/raw/master/README_assets/move.png">

This will create a new issue which is a copy of the original one, with mentions of every users who commented on the bug. The two issues will also references themselves:

<img width="600px" src="https://github.com/google/github-issue-mover/raw/master/README_assets/result.png">

## Disclaimer

Even though a lot of contributors are working for Google this is not an official Google Product.
This is an open-source sample application written in Dart and runable on Google App Engine and Google Compute Engine with a running test instance hosted on App Engine.

## License

[Apache 2.0](LICENSE)

Copyright 2014 Google Inc
