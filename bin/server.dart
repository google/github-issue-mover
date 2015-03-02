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

library github_issue_mover;

import 'dart:io';
import 'package:logging/logging.dart';
import 'package:forcemvc/force_mvc.dart';
import 'package:yaml/yaml.dart';
import 'package:github/server.dart';
import 'package:appengine/appengine.dart';


part 'logic/cookies.dart';
part 'logic/oauth_credentials.dart';
part 'controllers/oauth_controller.dart';

/// This will start the Issue Mover for GitHub app by starting a DartForce HTTP
/// server.
///
/// The server will run on port 8080.
void main() {

  // Create a force HTTP server.
  WebApplication app = new WebApplication(clientFiles: '../build/web/',
                                          views: './views/');

  // Handles 404 gracefully.
  app.notFound((ForceRequest req, Model model) {
    return "redirect:/";
  });

  // Set up logging.
  app.setupConsoleLog(Level.FINEST);

  // Start serving.
  runAppEngine(app.requestHandler);
}

