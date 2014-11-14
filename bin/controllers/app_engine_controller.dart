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

/// Handles the mapping for all App Engine related endpoints.
@Controller
class AppEngineController {

  /// This URL is pinged regularly by App Engine to make sure the instance is
  /// up and running.
  @RequestMapping(value: "/_ah/health")
  HttpResponse healthChecks(ForceRequest req, Model model) {
    HttpResponse response = req.request.response
      ..statusCode = 200
      ..write("ok")
      ..close();
    return response;
  }

  /// This URL is called by App Engine when the virtual machine is ready.
  @RequestMapping(value: "/_ah/start")
  HttpResponse start(ForceRequest req, Model model) {
    HttpResponse response = req.request.response
      ..statusCode = 200
      ..write("ok")
      ..close();
    // We don't do anything special.
    return response;
  }
}
