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

part of github_issue_mover;

/// Handles the mapping for all OAuth related endpoints.
@Controller
class OAuthController {

  /// Relative path to the Exchange code callback URL.
  static const String exchangeCodePath = "/exchange_code";

  /// Scope we need access to.
  static final List<String> SCOPES = ["repo"];

  /// OAuth flow.
  OAuth2Flow _oauthFlow;

  /// Redirects the user to the GitHub API authorization page.
  @RequestMapping(value: "/oauth_redirect")
  HttpResponse authRedirect(ForceRequest req, Model model) {
    HttpResponse response = req.request.response;
    response.redirect(Uri.parse(
        getOauthGitHubHelper(req.request.requestedUri).createAuthorizeUrl()));
    return response;
  }

  /// Serves the main page of the app.
  @RequestMapping(value: "/")
  String showPage(ForceRequest req, Model model) {
    // If an error cookie is being passed along we delete it and we inject the
    // error message in the view
    Cookie errorCookie = CookiesHelper.getErrorCookie(req.request);
    if (errorCookie != null) {
      req.request.response.cookies.add(CookiesHelper
          .createExpiredErrorCookie());
      model.addAttribute("error", errorCookie.value.replaceAll("_", " "));
    }
    return "index";
  }

  /// Logs out the user.
  @RequestMapping(value: "/logout")
  String logout(ForceRequest req, Model model,
                @RequestParam() String error_message) {
    if(error_message != "") {
      req.request.response.cookies.add(
          CookiesHelper.createErrorCookie(error_message));
    }
    req.request.response.cookies.add(
        CookiesHelper.createExpiredAccessTokenCookie());
    return "redirect:/";
  }

  /// OAuth Callback endpoint.
  @RequestMapping(value: exchangeCodePath)
  dynamic oauthCallback(ForceRequest req, Model model, @RequestParam() String
      code, @RequestParam() String error) {
    if (error != null && error == "") {
      req.request.response.cookies.add(
          CookiesHelper.createErrorCookie(error));
      req.request.response.cookies.add(
          CookiesHelper.createExpiredAccessTokenCookie());
      return "redirect:/";
    } else {
      getOauthGitHubHelper(req.request.requestedUri).exchange(code)
          .then((ExchangeResponse response) {
            req.request.response.cookies.add(
                CookiesHelper.createAccessTokenCookie(response.token));
            req.async("redirect:/");
          }).catchError((error) {
            if (error is String) {
              req.request.response.cookies.add(
                  CookiesHelper.createErrorCookie(error));
            } else {
              req.request.response.cookies.add(
                  CookiesHelper.createErrorCookie("$error"));
            }
            req.request.response.cookies.add(
                CookiesHelper.createExpiredAccessTokenCookie());
            req.async("redirect:/");
          });
      return req.asyncFuture;
    }
  }

  /// Returns true if we are running on a dev environment.
  ///
  /// We base this on the [Uri] the user requested on the server.
  static bool isDev(Uri requestedUri) {
    // We are in a dev environment if the host is local.
    return requestedUri.host == "localhost"
        || requestedUri.host == "127.0.0.1";
  }

  /// Returns an instance of the OAuth2Flow.
  ///
  /// We base this on the [Uri] the user requested on the server.
  OAuth2Flow getOauthGitHubHelper(Uri requestedUri) {
    if(_oauthFlow == null) {
      OAuthCredentials credentials =
          OAuthCredentials.loadOauthCredentials(dev: isDev(requestedUri));
      initGitHub();
      _oauthFlow = new OAuth2Flow(credentials.clientId,
          credentials.clientSecret,
          redirectUri: getRedirectUrl(requestedUri),
          scopes: SCOPES);
    }
    return _oauthFlow;
  }

  /// Returns the absolute URL to the [exchangeCodePath].
  ///
  /// We base this on the [Uri] the user requested on the server.
  static String getRedirectUrl(Uri requestedUri) {
    // Probable bug in App Engine Managed VMs.
    // The scheme returned is HTTP when it should be HTTPS.
    if(isDev(requestedUri)) {
      return "${requestedUri.origin}$exchangeCodePath";
    }
    // When in prod we force HTTPS.
    return "${requestedUri.origin}$exchangeCodePath"
        .replaceFirst("http://", "https://");
  }
}
