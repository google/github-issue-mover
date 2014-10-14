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

/// Contains all the UI related actions.
part of githubissuemover;

/// Displays the details of the given Issue in the "IssueOverview" div.
displayIssueDetails(Issue issue) {
  AnchorElement issueTitle = querySelector("#issueOverview #issueTitle");
  issueTitle.text = "${issue.title} #${issue.number}";
  issueTitle.href = issue.htmlUrl;
  AnchorElement issueUserName = querySelector("#issueOverview #issueUserName");
  issueUserName.text = issue.user.login;
  issueUserName.href = issue.user.htmlUrl;
  (querySelector("#issueOverview #issueUserAvatar") as ImageElement).src =
      issue.user.avatarUrl;
  querySelector("#issueOverview #issueBody").innerHtml =
      issue.body != "" ? markdownToHtml(issue.body) : "No description provided.";
  querySelector("#issueOverview #issueComments").text =
      "${issue.commentsCount} Comment(s)";
  querySelector("#issueError").style.display = "none";
  querySelector("#issueOverview").style.display = "block";
}

/// Displays the details of the given Issue in the "IssueOverview" div.
displayRepoDetails(Repository repo) {
  AnchorElement repoName = querySelector("#repoOverview #repoName");
  repoName.text = repo.fullName;
  repoName.href = repo.htmlUrl;
  querySelector("#repoOverview #repoDescription").text =
      repo.description != "" ? repo.description : "No description provided.";
  querySelector("#repoError").style.display = "none";
  querySelector("#repoOverview").style.display = "block";
}

/// Displays an error about the issue input.
displayIssueError(String errorMessage) {
  querySelector("#issueError").style.display = "block";
  querySelector("#issueError").text = errorMessage;
  querySelector("#issueOverview").style.display = "none";
}

/// Clears the Issue details section.
clearIssue() {
  querySelector("#issueError").style.display = "none";
  querySelector("#issueOverview").style.display = "none";
}

/// Displays an Error about the Repo Input.
displayRepoError(String errorMessage) {
  querySelector("#repoError").style.display = "block";
  querySelector("#repoError").text = errorMessage;
  querySelector("#repoOverview").style.display = "none";
}

/// Displays an error that happened during the copy issue.
displayMoveError(String errorMessage) {
  querySelector("#moveError").style.display = "block";
  querySelector("#moveError").text = errorMessage;
  querySelector("#close").attributes.remove("disabled");
  querySelector("#close").focus();
}

/// Clears the Repo details section.
clearRepo() {
  querySelector("#repoError").style.display = "none";
  querySelector("#repoOverview").style.display = "none";
}

/// Hide the "Authorize" button block and show the move issues form.
displayMoveIssueForm() {
  querySelector("#authorize").style.display = "none";
  querySelector("#form").style.display = "table";
  querySelector("#issue").focus();
}

/// Enables or Disables the "Move" button depending on wether or not we have both
/// an issue to move and a destination repo.
enableDisableMoveButton() {
  // We disable the "Move" button if we don't have a destinationRepo or Issue.
  if (destinationRepo == null || issueToMove == null) {
    querySelector("#move").attributes["disabled"] = "disabled";
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
    querySelector("#move").attributes["disabled"] = "disabled";
  } else {
    querySelector("#move").attributes.remove("disabled");
    if (destinationRepo != null) {
      displayRepoDetails(destinationRepo);
    }
  }
}

/// Displays information about the currently authorized GitHub [User].
displayAuthorizedUser() {
  AnchorElement login = querySelector("#login");
  login.text = currentGitHubUser.login;
  login.href = currentGitHubUser.htmlUrl;
  (querySelector("#photo") as ImageElement).src = currentGitHubUser.avatarUrl;
  querySelector("#user").style.display = "block";
}

/// Hides information about the currently authorized GitHub [User].
hideAuthorizedUser() {
  querySelector("#user").style.display = "none";
}

/// Close the move details container and re-initilizes it for next use.
closeMoveResultContainer() {

  // Re-initializes all the elements in the move widget.
  querySelectorAll("#moveResultContainer #content .check").forEach(
      (element) => element.style.visibility = "hidden");
  querySelectorAll("#moveResultContainer #content .loading").forEach(
      (element) => element.style.visibility = "hidden");
  AnchorElement newIssueLink =
      querySelector("#moveResultContainer #content #newIssueLink");
  newIssueLink.href = "";
  newIssueLink.text = "";
  AnchorElement oldIssueLink =
      querySelector("#moveResultContainer #content #oldIssueLink");
  oldIssueLink.href = "";
  oldIssueLink.text = "";
  querySelector("#numComments").text = "";
  querySelector("#close").attributes["disabled"] = "disabled";

  // Re-enables all elements in the main form section.
  querySelector("#move").attributes.remove("disabled");
  querySelector("#repo").attributes.remove("disabled");
  querySelector("#issue").attributes.remove("disabled");

  // Hide potential Error.
  querySelector("#moveError").style.display = "none";

  // Hides the move widget.
  querySelector("#moveResultContainer").style.display = "none";
}

/// Displays and initalizes the move details container.
initMoveContainer() {

  // Disable all elements in the main form section.
  querySelector("#move").attributes["disabled"] = "disabled";
  querySelector("#repo").attributes["disabled"] = "disabled";
  querySelector("#issue").attributes["disabled"] = "disabled";

  // Populate Old Issue Link part of the move widget.
  AnchorElement oldIssueLink = querySelector("#oldIssueLink");
  GitHubUrl issueToMoveUrl = GitHubUrl.parse(issueToMove.htmlUrl);
  oldIssueLink.href = issueToMoveUrl.fullUrl;
  oldIssueLink.text = issueToMoveUrl.simplifiedUrl;

  // Display the move details container.
  querySelector("#moveResultContainer").style.display = "block";
}

/// Marks the task as done, enables the "Close" button and moves the focus on it.
markOriginalIssueClosedCompleted() {
  querySelector("#closeIssueCheck").style.visibility = "visible";
}

/// Moves the focus to the Close Move Widget button.
moveFocusToCloseButton() {
  querySelector("#close").attributes.remove("disabled");
  querySelector("#close").focus();
}

/// Marks the Comments copy as completed.
markCommentsCopyCompleted() {
  querySelector("#copyCommentsCheck").style.visibility = "visible";
}

/// Marks the closing comment creation task as completed.
markClosingCommentCreationCompleted() {
  querySelector("#referenceCommentCheck").style.visibility = "visible";
}

/// Updates the number of Comments that have been copied.
updateNumCommentsCopied(int num, int total){
  querySelector("#numComments").text = "$num/$total";
}

/// Initializes the Comments copy counter.
initCommentsCounter(int commentsListLength){
  querySelector("#numComments").text = "0/${commentsListLength}";
}

/// Marks the Creation of the copied Issue completed.
markCopiedIssueCreationCompleted(){
  querySelector("#copyIssueCheck").style.visibility = "visible";
}

/// Display the link to the new issue.
displayNewIssueLink(Issue newIssue) {
  AnchorElement newIssueLink = querySelector("#newIssueLink");
  GitHubUrl newIssueUrl = GitHubUrl.parse(newIssue.htmlUrl);
  newIssueLink.href = newIssueUrl.fullUrl;
  newIssueLink.text = newIssueUrl.simplifiedUrl;
}

/// Simplifies the URL entered in the Issue Input field.
GitHubUrl simplifyIssueInput() {
  InputElement issueInput = querySelector("#issue");
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
  InputElement repoInput = querySelector("#repo");
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
  InputElement repo = querySelector("#repo");
  if (repo.value.isEmpty) {
    repo.value = "${issueUrl.ownerName}/";
  }
  querySelector("#repo").focus();
}

/// Disable the Issue Input Field.
disableIssueInputField() {
  querySelector("#issue").attributes["disabled"] = "disabled";
}

/// Enables the Issue Input Field.
enableIssueInputField() {
  querySelector("#issue").attributes.remove("disabled");
}

/// Disable the Repo Input Field.
disableRepoInputField() {
  querySelector("#repo").attributes["disabled"] = "disabled";
}

/// Enables the Repo Input Field.
enableRepoInputField() {
  querySelector("#repo").attributes.remove("disabled");
}

/// Move focus to the Move button.
focusMoveButton() {
  querySelector("#move").focus();
}
