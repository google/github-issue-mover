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

/// Contains all the auto-suggestion widget related code.
part of githubissuemover;

/// Input the auto-completion is currently running on.
InputElement activeInput;

/// Drop-down the auto-completion is currently running on.
UListElement dropDown;

/// Define what type of GitHub element the auto-complete is used for. Can either
/// be [ISSUE_MODE], [OWNER_MODE] or [REPO_MODE].
Symbol mode = ISSUE_MODE;

/// Used to set auto-completion on Issues.
const Symbol ISSUE_MODE = #ISSUE;
/// Used to set auto-completion on Owners.
const Symbol OWNER_MODE = #OWNER;
/// Used to set auto-completion on Repositories.
const Symbol REPO_MODE = #REPO;

/// Cache of all repositories mapped by owners.
Map<String, List<Repository>> repositoriesList =
    new Map<String, List<Repository>>();
/// Cache of issues mapped by full repositories name.
Map<String, List<Issue>> issuesCache = new Map<String, List<Issue>>();

/// Initializes the Auto-completion module by fetching all repositories the user
/// has access to and caching them.
void initAutoSuggest() {

  // Disable Up and Down keys default behavior when drop-down is active to avoid
  // page or widget scrolling.
  document.onKeyDown.listen((e){
    if((e.keyCode == KeyCode.DOWN || e.keyCode == KeyCode.UP)
        && document.activeElement.parent == dropDown) {
      e.preventDefault();
      }
  });
  issueDropDown.onKeyDown.listen((e){
    if(e.keyCode == KeyCode.DOWN || e.keyCode == KeyCode.UP) {
      e.preventDefault();
    }
  });
  repoDropDown.onKeyDown.listen((e){
    if(e.keyCode == KeyCode.DOWN || e.keyCode == KeyCode.UP) {
      e.preventDefault();
    }
  });

  // Build the index of all owners and repositories the user has access to.
  gitHub.repositories.listRepositories().listen(
      (Repository repository) {
        _addRepoToCache(repository);
        refreshAutoSuggest();
      });
  // List all organizations the user is a member of and list all repositories
  // for each organizations.
  gitHub.organizations.list().listen(
      (Organization org) {
          _addOwnerToCache(org.login);
          refreshAutoSuggest();
          gitHub.repositories.listUserRepositories(org.login).toList().then(
            (List<Repository> repositories) {
              repositories.forEach((Repository repo) => _addRepoToCache(repo));
              refreshAutoSuggest();
            });
      });
}

/// Adds the given [repo] to the cache.
void _addRepoToCache(Repository repo) {
  _addOwnerToCache(repo.owner.login);
  repositoriesList[repo.owner.login].add(repo);
}

/// Adds the given [ownerName] to the cache.
void _addOwnerToCache(String ownerName) {
  if(repositoriesList[ownerName] == null) {
    repositoriesList[ownerName] = new List<Repository>();
  }
}

/// Setup the auto-completion module to be used on the Issue Input field.
void refreshIssueAutoSuggest([e]) {
  activeInput = issueInput;
  dropDown = issueDropDown;
  mode = ISSUE_MODE;
  refreshAutoSuggest(e);
}

/// Setup the auto-completion module to be used on the Repo Input field.
void refreshRepoAutoSuggest([e]) {
  activeInput = repoInput;
  dropDown = repoDropDown;
  mode = REPO_MODE;
  refreshAutoSuggest(e);
}


/// Displays the current drop-down.
displayDropDown([_]) => dropDown.style.display = "block";

/// Refreshes the list of suggestions based on the user input and what's in the
/// cache.
void refreshAutoSuggest([e]) {
  // Don't refresh if the focus is not inside the drop down or the input
  // elements.
  if (document.activeElement.parent != dropDown
      && document.activeElement != activeInput) {
    return;
  }

  // Make sure the Drop down is visible.
  displayDropDown();

  // If the key press is the down arrow (vs. typing a new letter) we move the
  // focus to the first element of the drop down and do not refresh.
  if (e != null && e is KeyboardEvent && e.keyCode == KeyCode.DOWN) {
    (dropDown.firstChild as LIElement).focus();
    // don't display errors for the issue since moving the focus out of the
    // input may trigger on onChange event.
    querySelector("#issueError").style.display = "none";
    return;
  }

  String inputValue = activeInput.value;

  // User is typing the owner name.
  if (!inputValue.contains("/")) {
    // Filter owner based on prefix.
    List<String> matchingOwner = new List<String>()
      ..addAll(repositoriesList.keys)
      ..retainWhere((String owner) => owner.startsWith(inputValue));
    _setAutoSuggestList(owners: matchingOwner..sort());

    // User is typing the repo name.
  } else if (!inputValue.contains("#")) {
    // Filter repo based on prefix and if the repo has any issues.
    String ownerInput = inputValue.split("/")[0];
    List<Repository> ownerRepositories = repositoriesList[ownerInput];
    if(ownerRepositories != null) {
      List<Repository> matchingRepositories = new List<Repository>()
        ..addAll(ownerRepositories)
        ..retainWhere((Repository repo) =>
      repo.fullName.startsWith(inputValue)
      && repo.hasIssues
      && (repo.openIssuesCount > 0 || mode == REPO_MODE));
      _setAutoSuggestList(repositories: matchingRepositories);
    } else {
      dropDown.children.clear();
      stopAutoSuggest(e);
    }

    // User is typing the issue number.
  } else {
    // Fetch Issues of the typed repo.
    GitHubUrl url = GitHubUrl.parse(inputValue);

    // Check in the cache if we already fetched the issues.
    List<Issue> issues = issuesCache["${url.ownerName}/${url.repoName}"];

    // If we don't have the issues in the cache we'll fetch them using the
    // GitHub API.
    if (issues == null) {

      // Create a new empty cache entry.
      issues  = new List<Issue>();
      issuesCache["${url.ownerName}/${url.repoName}"] = issues;

      // Fetch the repo's issues using the GitHub API.
      gitHub.issues.listByRepo(new RepositorySlug(url.ownerName, url.repoName))
          .listen((Issue issue){
            // Filter out Pull requests which are returned as issues.
            if (!issue.htmlUrl.contains("\/pull\/")) {
              issues.add(issue);
              List<Issue> matchingIssues = new List<Issue>()
                  ..addAll(issues)
                  ..retainWhere((Issue issue) =>"${issue.number}".startsWith(
                    url.issueNumber == null ? "" : url.issueNumber));
              _setAutoSuggestList(issues: matchingIssues);
            }
      });
    }
    List<Issue> matchingIssues = new List<Issue>()
        ..addAll(issues)
        ..retainWhere((Issue issue) => "${issue.number}".startsWith(
          url.issueNumber == null ? "" : url.issueNumber));
    _setAutoSuggestList(issues: matchingIssues);
  }
  return;
}

/// Display the given items in the auto-suggest widget with formatting depending
/// on whether we want to display [issues], [repositories] or [owners].
/// Only one list of item must be specified
void _setAutoSuggestList({List<String> owners, List<Repository> repositories,
                         List<Issue> issues}) {

  // Since we'll delete all children and re-create them we save what element had
  // the focus to re-apply it.
  String selectedElementText;
  if (document.activeElement.parent == dropDown) {
    selectedElementText = document.activeElement.attributes["value"];
  }

  // Naive implementation for now we just delete all existing auto-suggest
  // entries and re-create all new entries.
  dropDown.children.clear();
  if (owners != null) {
    owners.forEach((String owner) {
      String info = "... repositories";
      if (repositoriesList[owner].length != 0) {
        info = "${repositoriesList[owner].length} repositories";
      }
      LIElement elem = _createDropDownElement(
          owner + (mode == OWNER_MODE ? "" : "/"),
          info,
          isFinalValue: mode == OWNER_MODE);
      dropDown.children.add(elem);
    });
  } else if (repositories != null) {
    repositories.forEach((Repository repo) {
      LIElement elem = _createDropDownElement(
          repo.fullName + (mode == REPO_MODE ? "" : "#"),
          "${repo.openIssuesCount} open issues",
          isFinalValue: mode == REPO_MODE);
      dropDown.children.add(elem);
    });
  } else if (issues != null) {
    issues.forEach((Issue issue) {
      LIElement elem = _createDropDownElement(
          GitHubUrl.parse(issue.htmlUrl).simplifiedUrl,
          issue.title,
          isFinalValue: mode == ISSUE_MODE);
      dropDown.children.add(elem);
    });
  }

  // Re-apply focus if we currently had to refresh while the user was browsing
  // the drop-down list.
  if (selectedElementText != null) {
    displayDropDown();
    LIElement newSelected = dropDown.children.firstWhere(
            (LIElement elem) => elem.attributes["value"] == selectedElementText);
    newSelected.focus();
  }
}

/// Creates the `<li>` element for the drop-down.
LIElement _createDropDownElement(String text, String info,
                                 {bool isFinalValue: false}) {
  LIElement elem = new LIElement()
      ..tabIndex = -1
      ..attributes["finalValue"] = "$isFinalValue"
      ..onFocus.listen(displayDropDown)
      ..onBlur.listen(stopAutoSuggest)
      ..onKeyDown.listen(dropDownElemKeyPress)
      ..onClick.listen(selectDropDownItem)
      ..text = text
      ..attributes["value"] = text;
  SpanElement infoElement = new SpanElement()
      ..onClick.listen((e) {
        e.stopImmediatePropagation();
        elem.click();
      })
      ..classes.add("info")
      ..text = info;
  elem.children.add(infoElement);
  return elem;
}

/// Handles key press events when in the auto-suggest drop-down.
void dropDownElemKeyPress(KeyEvent e) {
  LIElement dropDownItem = e.target;
  if (e.keyCode == KeyCode.ENTER) {
    selectDropDownItem(e);
    e.preventDefault();
  } else if (e.keyCode == KeyCode.ESC) {
    activeInput.focus();
    e.preventDefault();
  } else if (e.keyCode == KeyCode.DOWN
      && dropDownItem.nextElementSibling != null) {
    dropDownItem.nextElementSibling.focus();
    e.preventDefault();
  } else if (e.keyCode == KeyCode.UP
      && dropDownItem.previousElementSibling == null) {
    activeInput.focus();
    e.preventDefault();
  } else if (e.keyCode == KeyCode.UP) {
    dropDownItem.previousElementSibling.focus();
    e.preventDefault();
  }
}

/// Handles selection (Click or Enter key) of an item in the suggestions.
void selectDropDownItem(e) {
  LIElement dropDownItem = e.target;
  activeInput.value = dropDownItem.attributes["value"];
  activeInput.focus();
  e.stopImmediatePropagation();

  // If this is a final/correct value for the auto-suggest we trigger the
  // onChange event of the input field.
  if (dropDownItem.attributes["finalValue"] == "true"){
    activeInput.dispatchEvent(new CustomEvent("change"));
    dropDown.style.display = "none";
  } else {
    displayDropDown();
  }
}

/// Hides the auto-suggest widget if the focus moved out.
/// You can force hiding the widget with []
void stopAutoSuggest(e) {
  UListElement originalDropDown = dropDown;
  InputElement originalActiveInput = activeInput;
  // Delaying this check by a few ms because the [document.activeElement] is not
  // set yet on Blur events in FireFox.
  var timer = new Timer(const Duration(milliseconds: 1), (){
    if (document.activeElement.parent != originalDropDown
        && document.activeElement != originalActiveInput) {
      originalDropDown.style.display = "none";
    }
  });
}

