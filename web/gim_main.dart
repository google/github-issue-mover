// Copyright 2014 Google Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License

/// Contains initialization, bindings and logic for the GitHub Issue Mover tool.
library githubissuemover;

import 'dart:html';
import 'dart:async';
import 'github_helper.dart';
import 'package:cookie/cookie.dart' as cookie;
import 'package:intl/intl.dart';
import 'package:github/browser.dart';
import 'package:markdown/markdown.dart';

part 'gim_ui.dart';
part 'gim_typeahead.dart';

/// Currently Signed in user. `null` if no users are signed-in.
CurrentUser currentGitHubUser;

/// [Issue] that the user wants to move. `null` if no issues have been selected
/// yet.
Issue issueToMove;

/// [Repository] where the user wants to move the [Issue]. `null` if no repo
/// have been selected yet.
Repository destinationRepo;

/// OAuth 2.0 access token. `null` if the user hasn't Authorized yet.
String accessToken;

/// Configured [GitHub] Client library accessor. `null` if the user hasn't
/// Authorized yet.
GitHub gitHub;

// Shortcuts to DOM Elements.
ButtonElement authButton = querySelector("#authButton");
DivElement authorizeContainer = querySelector("#authorize");

DivElement signedInUserContainer = querySelector("#user");
ImageElement signedInUserAvatar = querySelector("#photo");
AnchorElement signedInUserLogin = querySelector("#login");

DivElement moveIssueForm = querySelector("#moveIssueForm");

ButtonElement moveIssueButton = querySelector("#move");
DivElement moveResultContainer = querySelector("#moveResultContainer");
DivElement moveError = querySelector("#moveError");
AnchorElement newIssueLink = querySelector("#newIssueLink");
AnchorElement oldIssueLink = querySelector("#oldIssueLink");
ButtonElement closeMoveWidgetButton = querySelector("#close");
SpanElement numCommentsMoved = querySelector("#numComments");
ElementList<SpanElement> checkMarks = querySelectorAll("#moveResultContainer .check");
SpanElement closeIssueCheckMark = querySelector("#closeIssueCheck");
SpanElement copyCommentsCheckMark = querySelector("#copyCommentsCheck");
SpanElement referenceCommentCheckMark = querySelector("#referenceCommentCheck");
SpanElement copyIssueCheckMark = querySelector("#copyIssueCheck");

InputElement issueInput = querySelector("#issue");
UListElement issueDropDown = querySelector("#dropdownIssue");
DivElement issueOverview = querySelector("#issueOverview");
ImageElement issueOverviewUserAvatar = querySelector("#issueUserAvatar");
SpanElement issueOverviewBody = querySelector("#issueBody");
AnchorElement issueOverviewTitle = querySelector("#issueTitle");
AnchorElement issueOverviewUserName = querySelector("#issueUserName");
SpanElement issueOverviewComment = querySelector("#issueComments");
DivElement issueError = querySelector("#issueError");

InputElement repoInput = querySelector("#repo");
UListElement repoDropDown = querySelector("#dropdownRepo");
DivElement repoOverview = querySelector("#repoOverview");
ImageElement repoOverviewUserAvatar = querySelector("#repoUserAvatar");
SpanElement repoOverviewDescription = querySelector("#repoDescription");
AnchorElement repoOverviewName = querySelector("#repoName");
DivElement repoError = querySelector("#repoError");


/// App's entry point.
void main() {

  // Reading the OAuth 2.0 accessToken from the Cookies.
  accessToken = cookie.get('access_token') ==
      "" ? null : cookie.get('access_token');

  // Instantiate the GitHub Accessor if we have an AccessToken.
  gitHub = accessToken == null ? null : createGitHubClient(
      auth: new Authentication.withToken(accessToken));

  // Auto-suggest Issue event bindings.
  issueInput.onFocus.listen((e) => refreshIssueAutoSuggest(e));
  issueInput.onChange.listen((e) => stopAutoSuggest(e));
  issueInput.onKeyUp.listen((e) => refreshIssueAutoSuggest(e));
  issueInput.onBlur.listen((e) => stopAutoSuggest(e));
  // Auto-suggest Repo event bindings.
  repoInput.onFocus.listen((e) => refreshRepoAutoSuggest(e));
  repoInput.onChange.listen((e) => stopAutoSuggest(e));
  repoInput.onKeyUp.listen((e) => refreshRepoAutoSuggest(e));
  repoInput.onBlur.listen((e) => stopAutoSuggest(e));
  // Event bindings.
  issueInput.onChange.listen(onIssueChange);
  repoInput.onChange.listen(onRepoChange);
  authButton.onClick.listen(
      (Event) => window.location.href = "/oauth_redirect");
  moveIssueButton.onClick.listen((e) => copyIssue());
  closeMoveWidgetButton.onClick.listen((e) => closeMoveResultContainer());

  // If the user is authorized we Display the username and show the main panel.
  if (gitHub != null) {
    fetchAuthorizedUser();
    displayMoveIssueForm();
    initAutoSuggest();
  }
}

/// Automatically simplifies the issue input URL and loads the issue's details
/// if possible.
void onIssueChange([_]) {

  // Make sure we disable the move button while processing this.
  issueToMove = null;
  enableDisableMoveButton();

  // Simplify the URL in the input field.
  GitHubUrl issueUrl = simplifyIssueInput();

  // Check if the URL is indeed a GitHub Issue URL.
  if (issueUrl == null) {
    if (issueInput.value.isEmpty) {
      clearIssue();
    } else {
      displayIssueError("Not a valid GitHub URL");
    }
  } else if (issueUrl.ownerName != null
      && issueUrl.repoName != null
      && issueUrl.issueNumber != null) {

    // Disables the Input field temporarily.
    disableIssueInputField();

    // Gets the issue's details on GitHub.
    RepositorySlug repositorySlug = new RepositorySlug(
        issueUrl.ownerName, issueUrl.repoName);
    gitHub.issues.get(repositorySlug, int.parse(issueUrl.issueNumber)).then(
        (Issue issue) {
          enableIssueInputField();
          if(document.activeElement.parent == dropDown) {
            return;
          }
          issueToMove = issue;
          enableDisableMoveButton();
          displayIssueDetails(issue);
          // Initialize the Repo field if empty and move focus to it.
          initRepoInput(issueUrl);
    }).catchError((error) {
      displayIssueError("The issue or repo does not exist.");
      enableIssueInputField();
    });
  } else {
    displayIssueError("Not a GitHub Issue URL");
  }
}

/// Automatically simplifies the repo input URL if possible and loads the repo's
/// details.
void onRepoChange([_]) {

  // Make sure we disable the move button while processing this.
  destinationRepo = null;
  enableDisableMoveButton();

  // Simplify the Repo URL in the input field.
  GitHubUrl repoUrl = simplifyRepoInput();

  if (repoUrl == null) {
    if (repoInput.value.isEmpty) {
      clearRepo();
    } else {
      displayRepoError("Not a valid GitHub URL");
    }
    // Check if the URL is indeed a GitHub Repo URL
  } else if (repoUrl.ownerName != null
      && repoUrl.repoName != null) {
    disableRepoInputField();

    // Get the Repository details from GitHub.
    gitHub.repositories.getRepository(
        new RepositorySlug(repoUrl.ownerName, repoUrl.repoName)).then(
            (Repository repo) {
              destinationRepo = repo;
              // Display the Repo details and re-enable everything.
              enableRepoInputField();
              displayRepoDetails(repo);
              enableDisableMoveButton();
              // Move focus to the button if it's enabled.
              focusMoveButton();
            }).catchError((error) {
              displayRepoError("The repo does not exist.");
              enableRepoInputField();
            });
  }
}

/// Fetches and displays information about the currently Authorized user.
void fetchAuthorizedUser() {
  currentGitHubUser = null;
  // Request the currently signed in GitHub user.
  gitHub.users.getCurrentUser().then((CurrentUser user) {
    currentGitHubUser = user;
    displayAuthorizedUser();
  }).catchError((_) {
    // A probable issue is that the auth token has expired or has been revoked.
    // So we direct the user to /logout.
    window.location.replace("/logout?error_message=Token%20expired.");
    hideAuthorizedUser();
  });
}

/// Starts the copy of the issue.
void copyIssue() {
  // Display the move details container.
  initMoveContainer();

  // Create the Copy of the Issue as an IssueRequest.
  IssueRequest copy = getIssueRequest(issueToMove);

  // Mention then Original Author and post time.
  GitHubUrl originalIssueUrl = GitHubUrl.parse(issueToMove.htmlUrl);
  DateFormat dateFormat = new DateFormat('MMMM d, y H:m');
  copy.body = "_From @${issueToMove.user.login} on "
      + "${dateFormat.format(issueToMove.createdAt)}_\n\n${copy.body}\n\n_"
      + "Copied from original issue: ${originalIssueUrl.simplifiedUrl}_";

  gitHub.issues.create(destinationRepo.slug(), copy).then((Issue newIssue) {
    markCopiedIssueCreationCompleted();

    // Display the link to the new issue.
    displayNewIssueLink(newIssue);

    // Fetch all Comments from the original issue.
    Stream<IssueComment> stream = gitHub.issues.listCommentsByIssue(
        new RepositorySlug(originalIssueUrl.ownerName,
            originalIssueUrl.repoName), issueToMove.number);
    stream.toList().then((List<IssueComment> comments) {
      initCommentsCounter(comments.length);

      // For each comments we add a mention of the original commenter.
      comments.forEach((IssueComment comment) {
        // If the comment is from a different user we add attribution to the
        // original user.
        if (comment.user.login != currentGitHubUser.login) {
          comment.body = "_From @${comment.user.login} on "
              + "${dateFormat.format(comment.createdAt)}_\n\n${comment.body}";
        }
      });

      // Add all comments to the new issue.
      addCommentsToIssue(gitHub, comments, newIssue, destinationRepo,
          updateNumCommentsCopied).then((_) {
            markCommentsCopyCompleted();

            // Adding closing comment to the original issue.
            GitHubUrl newIssueUrl = GitHubUrl.parse(newIssue.htmlUrl);
            String commentBody =
                "This issue was moved to ${newIssueUrl.simplifiedUrl}";
            RepositorySlug originalRepoSlug = new RepositorySlug(
                originalIssueUrl.ownerName, originalIssueUrl.repoName);
            gitHub.issues.createComment(originalRepoSlug,
                issueToMove.number, commentBody).then((_) {
                    markClosingCommentCreationCompleted();
                    IssueRequest request = new IssueRequest();
                    request.state = "closed";
                    gitHub.issues.edit(originalRepoSlug, issueToMove.number,
                        request).then((_) {
                          markOriginalIssueClosedCompleted();
                          moveFocusToCloseButton();
                    }).catchError((error) => displayMoveError(
                        "Error closing original issue: $error"));
            }).catchError((error) => displayMoveError(
                "Error adding closing comment to original issue: $error"));
      }).catchError((error) => displayMoveError(
          "Error copying comments to copied issue: $error"));
    }).catchError((error) => displayMoveError(
        "Error reading comments of original issue: $error"));
  }).catchError((error) => displayMoveError(
      "Error creating new issue: $error"));
}

