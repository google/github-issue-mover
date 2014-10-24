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

/// Contains all the UI related actions.
part of githubissuemover;

/// Displays the details of the given [issue] in the "IssueOverview" div.
displayIssueDetails(Issue issue) {
  issueOverviewTitle.text = "${issue.title} #${issue.number}";
  issueOverviewTitle.href = issue.htmlUrl;
  issueOverviewUserName.text = issue.user.login;
  issueOverviewUserName.href = issue.user.htmlUrl;
  issueOverviewUserAvatar.src = issue.user.avatarUrl;
  issueOverviewBody.innerHtml = issue.body != ""
      ? markdownToHtml(issue.body) : "No description provided.";
  issueOverviewComment.text = "${issue.commentsCount} Comment(s)";
  issueError.style.display = "none";
  issueOverview.style.display = "block";
}

/// Displays the details of the given [repo] in the "RepoOverview" div.
displayRepoDetails(Repository repo) {
  repoOverviewName.text = repo.fullName;
  repoOverviewName.href = repo.htmlUrl;
  repoOverviewDescription.text =
      repo.description != "" ? repo.description : "No description provided.";
  repoError.style.display = "none";
  repoOverview.style.display = "block";
}

/// Displays an error about the issue input.
displayIssueError(String errorMessage) {
  issueError.style.display = "block";
  issueError.text = errorMessage;
  issueOverview.style.display = "none";
}

/// Clears the Issue details section.
clearIssue() {
  issueError.style.display = "none";
  issueOverview.style.display = "none";
}

/// Displays an Error about the Repo Input.
displayRepoError(String errorMessage) {
  repoError.style.display = "block";
  repoError.text = errorMessage;
  repoOverview.style.display = "none";
}

/// Displays an error that happened during the issue moving process.
displayMoveError(String errorMessage) {
  moveError.style.display = "block";
  moveError.text = errorMessage;
  closeMoveWidgetButton.attributes.remove("disabled");
  closeMoveWidgetButton.focus();
}

/// Clears the Repo details section.
clearRepo() {
  repoError.style.display = "none";
  repoOverview.style.display = "none";
}

/// Hide the "Authorize" button block and show the move issues form.
displayMoveIssueForm() {
  authorizeContainer.style.display = "none";
  moveIssueForm.style.display = "table";
  issueInput.focus();
}

/// Enables or Disables the "Move" button depending on whether or not we have
/// both an issue to move and a destination repo.
enableDisableMoveButton() {
  // We disable the "Move" button if we don't have a destinationRepo or Issue.
  if (destinationRepo == null || issueToMove == null) {
    moveIssueButton.attributes["disabled"] = "disabled";
    if (destinationRepo != null) {
      displayRepoDetails(destinationRepo);
    }
    return;
  }

  GitHubUrl destinationRepoUrl = GitHubUrl.parse(destinationRepo.htmlUrl);
  GitHubUrl issueToMoveUrl = GitHubUrl.parse(issueToMove.htmlUrl);

  if (destinationRepoUrl.ownerName == issueToMoveUrl.ownerName
      && destinationRepoUrl.repoName == issueToMoveUrl.repoName) {
    displayRepoError("You can't move an issue to its current repo.");
    moveIssueButton.attributes["disabled"] = "disabled";
  } else {
    moveIssueButton.attributes.remove("disabled");
    if (destinationRepo != null) {
      displayRepoDetails(destinationRepo);
    }
  }
}

/// Displays information about the currently authorized GitHub [User].
displayAuthorizedUser() {
  signedInUserLogin.text = currentGitHubUser.login;
  signedInUserLogin.href = currentGitHubUser.htmlUrl;
  signedInUserAvatar.src = currentGitHubUser.avatarUrl;
  signedInUserContainer.style.display = "block";
}

/// Hides information about the currently authorized GitHub [User].
hideAuthorizedUser() => signedInUserContainer.style.display = "none";

/// Close the move details container and re-initializes it for next use.
closeMoveResultContainer() {

  // Re-initializes all the elements in the move widget.
  checkMarks.forEach((element) => element.style.visibility = "hidden");
  newIssueLink.href = "";
  newIssueLink.text = "";
  oldIssueLink.href = "";
  oldIssueLink.text = "";
  numCommentsMoved.text = "";
  closeMoveWidgetButton.attributes["disabled"] = "disabled";

  // Re-enables all elements in the main form section.
  moveIssueButton.attributes.remove("disabled");
  repoInput.attributes.remove("disabled");
  issueInput.attributes.remove("disabled");

  // Hide potential Error.
  moveError.style.display = "none";

  // Hides the move widget.
  moveResultContainer.style.display = "none";
}

/// Displays and initializes the move details container.
initMoveContainer() {

  // Disable all elements in the main form section.
  moveIssueButton.attributes["disabled"] = "disabled";
  repoInput.attributes["disabled"] = "disabled";
  issueInput.attributes["disabled"] = "disabled";

  // Populate Old Issue Link part of the move widget.
  GitHubUrl issueToMoveUrl = GitHubUrl.parse(issueToMove.htmlUrl);
  oldIssueLink.href = issueToMoveUrl.fullUrl;
  oldIssueLink.text = issueToMoveUrl.simplifiedUrl;

  // Display the move details container.
  moveResultContainer.style.display = "block";
}

/// Marks the Original Issue closing task as completed.
markOriginalIssueClosedCompleted() =>
    closeIssueCheckMark.style.visibility = "visible";

/// Enables and moves the focus to the Close Move Widget button.
moveFocusToCloseButton() {
  closeMoveWidgetButton.attributes.remove("disabled");
  closeMoveWidgetButton.focus();
}

/// Marks the Comments copy task as completed.
markCommentsCopyCompleted() =>
    copyCommentsCheckMark.style.visibility = "visible";

/// Marks the closing comment creation task as completed.
markClosingCommentCreationCompleted() =>
    referenceCommentCheckMark.style.visibility = "visible";

/// Updates the number of Comments that have been copied.
updateNumCommentsCopied(int num, int total) =>
    numCommentsMoved.text = "$num/$total";

/// Initializes the Comments copy counter.
initCommentsCounter(int commentsListLength) =>
    numCommentsMoved.text = "0/${commentsListLength}";

/// Marks the Creation of the copied Issue completed.
markCopiedIssueCreationCompleted() =>
    copyIssueCheckMark.style.visibility = "visible";

/// Display the link to the new issue.
displayNewIssueLink(Issue newIssue) {
  GitHubUrl newIssueUrl = GitHubUrl.parse(newIssue.htmlUrl);
  newIssueLink.href = newIssueUrl.fullUrl;
  newIssueLink.text = newIssueUrl.simplifiedUrl;
}

/// Simplifies the URL entered in the Issue Input field.
GitHubUrl simplifyIssueInput() {
  GitHubUrl issueUrl;
  try {
    issueUrl = GitHubUrl.parse(issueInput.value);
  } catch (exception) {
    return null;
  }
  issueInput.value = issueUrl.simplifiedUrl;
  return issueUrl;
}

/// Simplifies the URL entered in the Repo Input field.
GitHubUrl simplifyRepoInput() {
  GitHubUrl repoUrl;
  try {
    repoUrl = GitHubUrl.parse(repoInput.value);
  } catch (exception) {
    return null;
  }
  repoInput.value = "${repoUrl.ownerName}/${repoUrl.repoName}";
  return repoUrl;
}

/// Initialize the Repo field if empty and move focus to it.
initRepoInput(GitHubUrl issueUrl) {
  InputElement repo = repoInput;
  if (repo.value.isEmpty) {
    repo.value = "${issueUrl.ownerName}/";
  }
  repoInput.focus();
}

/// Disable the Issue Input Field.
disableIssueInputField() => issueInput.attributes["disabled"] = "disabled";

/// Enables the Issue Input Field.
enableIssueInputField() => issueInput.attributes.remove("disabled");

/// Disable the Repo Input Field.
disableRepoInputField() => repoInput.attributes["disabled"] = "disabled";

/// Enables the Repo Input Field.
enableRepoInputField() => repoInput.attributes.remove("disabled");

/// Move focus to the Move button.
focusMoveButton() => moveIssueButton.focus();
