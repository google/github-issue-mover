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

/// Contains all the auto-suggestion widget related code.
part of githubissuemover;

/// Input the autcompletion is currently running on.
InputElement activeInput;

/// Dropdown the autcompletion is currently running on.
UListElement dropdown;

/// Define what type of GitHub element the autocomplete is used for. Can either
/// be [ISSUE_MODE], [OWNER_MODE] or [REPO_MODE].
Symbol mode = ISSUE_MODE;

/// Used to set autocompletion on Issues.
const Symbol ISSUE_MODE = #ISSUE;
/// Used to set autocompletion on Owners.
const Symbol OWNER_MODE = #OWNER;
/// Used to set autocompletion on Repos.
const Symbol REPO_MODE = #REPO;

/// Cache of all owners (username, orgs) the user has repos in.
List<String> ownersList = new List<String>();
/// Cache of all repos mapped by owners.
Map<String, List<Repository>> reposList = new Map<String, List<Repository>>();
/// Cache of issues mapped by full repos name.
Map<String, List<Issue>> issuesCache = new Map<String, List<Issue>>();

/// Initializes the Autocompletion module by fetching all repos the user has
/// access to and caching them.
initAutoSuggest() {

  // Disable Up and Down keys default behavior when dropdown is active
  document.onKeyDown.listen((e){
    if((e.keyCode == KeyCode.DOWN || e.keyCode == KeyCode.UP)
        && document.activeElement.parent == dropdown) {
      e.preventDefault();
      }
  });
  issueDropdown.onKeyDown.listen((e){
    if(e.keyCode == KeyCode.DOWN || e.keyCode == KeyCode.UP) {
      e.preventDefault();
    }
  });
  repoDropdown.onKeyDown.listen((e){
    if(e.keyCode == KeyCode.DOWN || e.keyCode == KeyCode.UP) {
      e.preventDefault();
    }
  });

  // Build the index of all Owners and repos the user has access to.
  github.repositories.listRepositories().toList().then(
      (List<Repository> repos) {
        Map<String, bool> uniqueOwnersList = new Map<String, bool>();
        repos.forEach((Repository repo) {
          uniqueOwnersList[repo.owner.login] = true;
          _addRepoToCache(repo);
        });
        ownersList.addAll(uniqueOwnersList.keys);
        refreshAutoSuggest();
      });
  github.organizations.list().toList().then((List<Organization> orgs) {
    orgs.forEach((Organization org) {
      ownersList.add(org.login);
      refreshAutoSuggest();
      github.repositories.listUserRepositories(org.login).toList().then(
          (List<Repository> repos) {
            repos.forEach((Repository repo) => _addRepoToCache(repo));
            refreshAutoSuggest();
          });
    });
  });
}

/// Adds the given [repo] to the cache.
_addRepoToCache(Repository repo) {
  if(reposList[repo.owner.login] == null) {
    reposList[repo.owner.login] = new List<Repository>();
  }
  reposList[repo.owner.login].add(repo);
}

/// Setup the Autocompletion module to be used on the Issue Input field.
refreshIssueAutoSuggest([e]) {
  activeInput = issueInput;
  dropdown = issueDropdown;
  mode = ISSUE_MODE;
  refreshAutoSuggest(e);
}

/// Setup the Autocompletion module to be used on the Repo Input field.
refreshRepoAutoSuggest([e]) {
  activeInput = repoInput;
  dropdown = repoDropdown;
  mode = REPO_MODE;
  refreshAutoSuggest(e);
}


/// Displays the current dropdown.
displayDropDown([_]) => dropdown.style.display = "block";

/// Refreshes the list of suggestions based on the user input and what's in the
/// cache.
refreshAutoSuggest([e]) {
  if(document.activeElement.parent != dropdown
      && document.activeElement != activeInput) {
    return false;
  }
  displayDropDown();
  if(e != null && e is KeyboardEvent && e.keyCode == KeyCode.DOWN) {
    (dropdown.firstChild as LIElement).focus();
    // don't display errors for the issue.
    querySelector("#issueError").style.display = "none";
    return false;
  }
  String input = activeInput.value;

  // User is typing the owner name.
  if(!input.contains("/")) {
    // Filter owner based on prefix.
    List<String> matchingOwner = new List<String>()
        ..addAll(ownersList)
        ..retainWhere((String owner) => owner.startsWith(input));
    _setAutoSuggestList(owners: matchingOwner..sort());

  // User is typing the repo name.
  } else if(!input.contains("#")) {
    // Filter repo based on prefix and if the repo has any issues.
    List<Repository> ownerRepos = reposList[input.split("/")[0]];
    if(ownerRepos != null) {
      List<Repository> matchingRepos = new List<Repository>()
          ..addAll(ownerRepos)
          ..retainWhere((Repository repo) => repo.fullName.startsWith(input)
              && repo.hasIssues
              && (repo.openIssuesCount > 0 || mode == REPO_MODE));
      _setAutoSuggestList(repos: matchingRepos);
    } else {
      dropdown.children.clear();
      stopAutoSuggest();
    }

  // User is typing the issue number.
  } else {
    // Fetch Issues of the typed repo.
    GitHubUrl url = GitHubUrl.parse(input);
    List<Issue> issues = issuesCache["${url.ownerName}/${url.repoName}"];
    if (issues == null) {
      issues  = new List<Issue>();
      issuesCache["${url.ownerName}/${url.repoName}"] = issues;
        Stream<Issue> issuesStream = github.issues.listByRepo(
            new RepositorySlug(url.ownerName, url.repoName));
        issuesStream.listen((Issue issue){
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
  return false;
}

/// Display the given items in the autosuggest widget with formatting depending
/// on wether we want to display [issues], [repos] or [owners].
/// Only one list of item must be specified
_setAutoSuggestList({List<String> owners, List<Repository> repos,
    List<Issue> issues}) {
  String selectedElementText;
  if (document.activeElement.parent == dropdown) {
    selectedElementText = document.activeElement.attributes["value"];
  }
  dropdown.children.clear();
  if(owners != null) {
    owners.forEach((String owner) {
      String info = "... repositories";
      if (reposList[owner] != null) {
        info = "${reposList[owner].length} repositories";
      }
      LIElement elem = _createDropDownElement("$owner/", info,
          isFinalValue: mode == OWNER_MODE);
      dropdown.children.add(elem);
    });
  } else if (repos != null) {
    repos.forEach((Repository repo) {
      LIElement elem = _createDropDownElement(
          repo.fullName + (mode == REPO_MODE ? "" : "#"),
          "${repo.openIssuesCount} open issues",
          isFinalValue: mode == REPO_MODE);
      dropdown.children.add(elem);
    });
  } else if (issues != null) {
    issues.forEach((Issue issue) {
      LIElement elem = _createDropDownElement(
          GitHubUrl.parse(issue.htmlUrl).simplifiedUrl,
          issue.title,
          isFinalValue: mode == ISSUE_MODE);
      dropdown.children.add(elem);
    });
  }
  // Re-apply focus if we currenrly had to refresh while the user was browsing
  // the dropdown list.
  if(selectedElementText != null) {
    displayDropDown();
    LIElement newSelected = dropdown.children.firstWhere(
        (LIElement elem) => elem.attributes["value"] == selectedElementText);
    newSelected.focus();
  }
}

/// Creates the `<li>` element for the dropdown.
LIElement _createDropDownElement(String text, String info,
                                 {bool isFinalValue: false}) {
  LIElement elem = new LIElement();
  elem.tabIndex = activeInput.tabIndex;
  elem.attributes["finalValue"] = "$isFinalValue";
  elem.onFocus.listen(displayDropDown);
  elem.onBlur.listen(stopAutoSuggest);
  elem.onKeyDown.listen(dropdownElemKeyPress);
  elem.onClick.listen(selectDropDownItem);
  elem.onFocus.listen(displayDropDown);
  elem.text = text;
  elem.attributes["value"] = text;
  SpanElement infoElement = new SpanElement();
  infoElement.onClick.listen((e) {
    e.stopImmediatePropagation();
    elem.click();
  });
  infoElement.classes.add("info");
  infoElement.text = info;
  elem.children.add(infoElement);
  return elem;
}

/// Handles keypress events when in the autosuggest dropdown.
dropdownElemKeyPress(KeyEvent e) {
  LIElement dropdownItem = e.target;
  if (e.keyCode == KeyCode.ENTER) {
    selectDropDownItem(e);
    e.preventDefault();
  } else if (e.keyCode == KeyCode.ESC) {
    activeInput.focus();
    stopAutoSuggest();
    e.preventDefault();
  } else  if (e.keyCode == KeyCode.DOWN
      && dropdownItem.nextElementSibling != null) {
    dropdownItem.nextElementSibling.focus();
    e.preventDefault();
  } else  if (e.keyCode == KeyCode.UP
      && dropdownItem.previousElementSibling == null) {
    activeInput.focus();
    e.preventDefault();
  } else  if (e.keyCode == KeyCode.UP) {
    dropdownItem.previousElementSibling.focus();
    e.preventDefault();
  }
  return false;
}

/// Handles selection (Click or Enter key) of an item in the suggestions.
selectDropDownItem(e) {
  LIElement dropdownItem = e.target;
  activeInput.value = dropdownItem.attributes["value"];
  activeInput.focus();
  e.stopImmediatePropagation();
  if (dropdownItem.attributes["finalValue"] == "true"){
    activeInput.dispatchEvent(new CustomEvent("change"));
  }
  return false;
}

/// Hides the autosuggest widget.
stopAutoSuggest([_]) {
  if (document.activeElement.parent != dropdown) {
    dropdown.style.display = "none";
  }
}

