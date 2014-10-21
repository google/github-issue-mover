/// Copyright 2014 Google Inc. All rights reserved.
///
/// Licensed under the Apache License, Version 2.0 (the "License");
/// you may not use this file except in compliance with the License.
/// You may obtain a copy of the License at
///
///     http://www.apache.org/licenses/LICENSE-2.0
///
/// Unless required by applicable law or agreed to in writing, software
/// distributed under the License is distributed on an "AS IS" BASIS,
/// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/// See the License for the specific language governing permissions and
/// limitations under the License

/// Provides convenience GitHub tools.
library githubhelper;

import 'package:github/common.dart';
import 'dart:async';

/// Creates a copy of the [issue] as an [IssueRequest].
IssueRequest getIssueRequest(Issue issue) {
  IssueRequest copiedIssue = new IssueRequest();

  copiedIssue.title = issue.title;
  copiedIssue.body = issue.body;
  List<String> labels = new List<String>();
  issue.labels.forEach((IssueLabel label) => labels.add(label.name));
  copiedIssue.labels = labels;
  copiedIssue.assignee = issue.assignee != null ? issue.assignee.login : null;
  copiedIssue.state = issue.state;

  return copiedIssue;
}

/// Adds the list of given [comments] to the [issue] using an instance of a
/// [gitHub] client library.
///
/// You can pass a [tracker] callback [Function] that will be called after each
/// [IssueComment] creation. It the following arguments:
/// `tracker(number of comments created, total number of comments)`
Future<List<IssueComment>> addCommentsToIssue(GitHub gitHub,
    List<IssueComment> comments,
    Issue issue,
    Repository repo,
    [tracker(int numCommentsCreated, int numTotalComments) = null,
    Completer<List<IssueComment>> _completer = null,
    List<IssueComment> _commentsAdded]) {

  if (_completer == null) {
    _completer = new Completer<List<IssueComment>>();
    _commentsAdded = new List<IssueComment>();
  }

  if (comments.length == 0) {
    _completer.complete(new List<IssueComment>());
  } else {
    IssueComment nextCommentToAdd = comments.removeAt(0);
    gitHub.issues.createComment(repo.slug(), issue.number,
        nextCommentToAdd.body).then((IssueComment comment) {
          _commentsAdded.add(comment);
          // Calls the Tracker callback function if it exists.
          if (tracker != null) {
            tracker(_commentsAdded.length,
                comments.length + _commentsAdded.length);
          }
          // Stopping the loop if no more comments to add.
          if(comments.isEmpty) {
            _completer.complete(_commentsAdded);
          } else {
            // The GitHub API will often create Comments in the wrong order if
            // they are created too fast. Wait 1 sec between issue creations
            // to workaround this bug.
            var timer = new Timer(new Duration(milliseconds: 1000), (){
                addCommentsToIssue(gitHub, comments, issue, repo, tracker,
                    _completer, _commentsAdded);
            });
        }
    }).catchError((error) => _completer.completeError(error));;
  }
  return _completer.future;
}

/// Represents a www.github.com URL.
///
/// This class offers helpers to parse and simplify the URL.
/// Only implemented support for Issue and Repo URLs at this point.
class GitHubUrl {

  /// Owner of the repositories. Can be a user or an organization.
  String ownerName;

  /// Name of the repo.
  String repoName;

  /// Number of the issue.
  String issueNumber;

  /// The full HTTPS URL.
  String fullUrl;

  /// The URL simplified in GitHub short URL format.
  String simplifiedUrl;

  /// Parses a full GitHub [url] and returns a [GitHubUrl].
  static GitHubUrl parse(String url) {
    url = url.trim();
    GitHubUrl gitHubUrl = new GitHubUrl();
    gitHubUrl.fullUrl = url;
    gitHubUrl.simplifiedUrl = simplifyUrl(url);

    RegExp exp = new RegExp(r"([\w-_\.]+)\/([\w-_\.]+)(\#(\d+))?");
    Match match = exp.firstMatch(gitHubUrl.simplifiedUrl);
    if (match == null) {
      throw new FormatException("Wrong format of GitHub URL");
    }
    gitHubUrl.ownerName = match.group(1);
    gitHubUrl.repoName = match.group(2);
    gitHubUrl.issueNumber = match.group(4);
    if (gitHubUrl.ownerName == "") gitHubUrl.ownerName = null;
    if (gitHubUrl.repoName == "") gitHubUrl.repoName = null;
    if (gitHubUrl.issueNumber == "") gitHubUrl.issueNumber = null;

    return gitHubUrl;
  }

  /// Takes a [fullGitHubUrl] URL e.g.
  /// `https://github.com/ForceUniverse/dart-forcemvc/issues/13`
  /// and returns the simplified form e.g. `ForceUniverse/dart-forcemvc#13`.
  static String simplifyUrl(String fullGitHubUrl) {
    String simplifiedUrl = fullGitHubUrl;
    if (simplifiedUrl.startsWith("https://github.com/")) {
      simplifiedUrl = simplifiedUrl.substring("https://github.com/".length);
    }
    simplifiedUrl = simplifiedUrl.replaceFirst("/issues/", "#");
    simplifiedUrl = simplifiedUrl.replaceFirst("/issues", "");
    return simplifiedUrl;
  }
}
