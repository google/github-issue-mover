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

/// Helper methods to create Access Token and Error cookies.
///
/// Cookies allow us not to use server-side Sessions. It's tricky to use
/// Server-side sessions on App Engine because the user might not hit the same
/// backend instance during a session so we would need to use datastore backed
/// sessions which is not yet implemented.
class CookiesHelper {

  /// Name of the Access Token cookie.
  static final String ACCESS_TOKEN_COOKIE_NAME = "access_token";

  /// Name of the Error cookie.
  static final String ERROR_COOKIE_NAME = "error";

  /// Returns a [Cookie] containing the [accessToken].
  static Cookie createAccessTokenCookie(String accessToken) {
    Cookie accessTokenCookie = new Cookie(ACCESS_TOKEN_COOKIE_NAME,
        accessToken != null ? accessToken : "");
    accessTokenCookie.httpOnly = false;
    return accessTokenCookie;
  }

  /// Returns a [Cookie] that can be used to delete the Access Token [Cookie].
  static Cookie createExpiredAccessTokenCookie() {
    Cookie accessTokenCookie = createAccessTokenCookie("");
    accessTokenCookie.maxAge = 0;
    return accessTokenCookie;
  }

  /// Returns a [Cookie] containing an [error].
  static Cookie createErrorCookie(String error) {
    Cookie errorCookie = new Cookie(ERROR_COOKIE_NAME,
        error != null ? error.replaceAll(" ", "_") : "");
    errorCookie.httpOnly = false;
    return errorCookie;
  }

  /// Returns a [Cookie] that can be used to delete the Error [Cookie].
  static Cookie createExpiredErrorCookie() {
    Cookie errorCookie = createErrorCookie("");
    errorCookie.maxAge = 0;
    return errorCookie;
  }

  /// Returns the Error [Cookie] in the [HttpRequest].
  static Cookie getErrorCookie(HttpRequest req) {
    try {
      return req.cookies.singleWhere(
          (Cookie cookie) => cookie.name == ERROR_COOKIE_NAME);
    } on StateError catch (e) {
      return null;
    }
  }
}
