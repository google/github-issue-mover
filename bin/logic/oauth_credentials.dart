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

part of github_issue_mover;

/// Loads the OAuth credentials.
class OAuthCredentials {

  /// Name fo the file containing the prod OAuth 2.0 application's credentials.
  static const String PROD_CREDENTIALS_FILE_NAME = "credentials.yaml";

  /// Name fo the file containing the dev OAuth 2.0 application's credentials.
  static const String DEV_CREDENTIALS_FILE_NAME = "credentials_dev.yaml";

  /// Loaded Client ID.
  final String clientId;

  /// Loaded Client Secret.
  final String clientSecret;

  /// Default constructor.
  OAuthCredentials._(this.clientId, this.clientSecret);

  /// Reads the [OAuthCredentials] available on file.
  ///
  /// Set [dev]: `true` if you want to use the OAuth dev credentials instead of
  /// the prod ones.
  static OAuthCredentials loadOauthCredentials({bool dev: false}) {
    // Load credentials from YAML files.
    String fileName = PROD_CREDENTIALS_FILE_NAME;
    if(dev) {
      fileName = DEV_CREDENTIALS_FILE_NAME;
    }
    File file = new File(Platform.script.resolve(fileName).toFilePath());
    String content = file.readAsStringSync();
    var yaml = loadYaml(content);
    return new OAuthCredentials._(
        yaml["client_id"],
        yaml["client_secret"]);
  }
}
