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

/// Contains initialization, bindings and logic for the GitHub Issue Mover tool.
library githubissuemover;

import 'dart:html';
import 'dart:async';
import 'githubhelper.dart';
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
GitHub github;

// Shortcuts to DOM Elements.
InputElement issueInput = querySelector("#issue");
InputElement repoInput = querySelector("#repo");
UListElement issueDropdown = querySelector("#dropdownIssue");
UListElement repoDropdown = querySelector("#dropdownRepo");
ButtonElement moveButton = querySelector("#move");
ButtonElement closeButton = querySelector("#close");
ButtonElement authButton = querySelector("#auth_button");

/// App's entry point
main() {

  // Reading the OAuth 2.0 accessToken from the Cookies.
  accessToken = cookie.get('access_token') ==
      "" ? null : cookie.get('access_token');

  // Instantiate the GitHub Accessor if we have an AccessToken.
  github = accessToken == null ? null : createGitHubClient(
      auth: new Authentication.withToken(accessToken));

  // Autosuggest Issue event bindings.
  issueInput.onFocus.listen((e) => refreshIssueAutoSuggest(e));
  issueInput.onChange.listen((e) => stopAutoSuggest(e));
  issueInput.onKeyUp.listen((e) => refreshIssueAutoSuggest(e));
  issueInput.onBlur.listen((e) => stopAutoSuggest(e));
  // Autosuggest Repo event bindings.
  repoInput.onFocus.listen((e) => refreshRepoAutoSuggest(e));
  repoInput.onChange.listen((e) => stopAutoSuggest(e));
  repoInput.onKeyUp.listen((e) => refreshRepoAutoSuggest(e));
  repoInput.onBlur.listen((e) => stopAutoSuggest(e));
  // Event bindings.
  issueInput.onChange.listen(onIssueChange);
  repoInput.onChange.listen(onRepoChange);
  authButton.onClick.listen(
      (Event) => window.location.href = "/oauth_redirect");
  moveButton.onClick.listen((e) => copyIssue());
  closeButton.onClick.listen((e) => closeMoveResultContainer());

  // If the user is authorized we Display the username and show the main panel.
  if (github != null) {
    fetchAuthorizedUser();
    displayMoveIssueForm();
    initAutoSuggest();
  }
}

/// Automatically simplifies the issue input URL and loads the issue's details
/// if possible.
onIssueChange([_]) {

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
    github.issues.get(repositorySlug, int.parse(issueUrl.issueNumber)).then(
        (Issue issue) {
          enableIssueInputField();
          if(document.activeElement.parent == dropdown) {
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

/// Automatically simplifies the repo input URL if possible and loads the Repo's
/// details.
onRepoChange([_]) {

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
    github.repositories.getRepository(
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
fetchAuthorizedUser() {
  currentGitHubUser = null;
  // Request the currently signed in GitHub user.
  github.users.getCurrentUser().then((CurrentUser user) {
    currentGitHubUser = user;
    displayAuthorizedUser();
  }).catchError((_) => hideAuthorizedUser());
}

/// Starts the copy of the issue.
copyIssue() {
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

  github.issues.create(destinationRepo.slug(), copy).then((Issue newIssue) {
    markCopiedIssueCreationCompleted();

    // Display the link to the new issue.
    displayNewIssueLink(newIssue);

    // Fetch all Comments from the original issue.
    Stream<IssueComment> stream = github.issues.listCommentsByIssue(
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
      addCommentsToIssue(github, comments, newIssue, destinationRepo,
          updateNumCommentsCopied).then((_) {
            markCommentsCopyCompleted();

            // Adding closing comment to the original issue.
            GitHubUrl newIssueUrl = GitHubUrl.parse(newIssue.htmlUrl);
            String commentBody =
                "This issue was moved to ${newIssueUrl.simplifiedUrl}";
            RepositorySlug originalRepoSlug = new RepositorySlug(
                originalIssueUrl.ownerName, originalIssueUrl.repoName);
            github.issues.createComment(originalRepoSlug,
                issueToMove.number, commentBody).then((_) {
                    markClosingCommentCreationCompleted();
                    IssueRequest request = new IssueRequest();
                    request.state = "closed";
                    github.issues.edit(originalRepoSlug, issueToMove.number,
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

