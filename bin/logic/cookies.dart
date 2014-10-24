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

/// Helper methods to create Access Token and Error cookies.
///
/// Cookies allow us not to use server-side Sessions. It's tricky to use
/// Server-side sessions on App Engine because the user might not hit the same
/// backend instance during a session so we would need to use data-store backed
/// sessions which is not yet implemented.
class CookiesHelper {

  /// Name of the Access Token cookie.
  static const String ACCESS_TOKEN_COOKIE_NAME = "access_token";

  /// Name of the Error cookie.
  static const String ERROR_COOKIE_NAME = "error";

  /// Returns a [Cookie] containing the [accessToken].
  static Cookie createAccessTokenCookie(String accessToken) {
    return new Cookie(ACCESS_TOKEN_COOKIE_NAME,
        accessToken != null ? accessToken : "")
        ..httpOnly = false;
  }

  /// Returns a [Cookie] that can be used to delete the Access Token [Cookie].
  static Cookie createExpiredAccessTokenCookie() {
    return createAccessTokenCookie("")
        ..maxAge = 0;
  }

  /// Returns a [Cookie] containing an [error].
  static Cookie createErrorCookie(String error) {
    return new Cookie(ERROR_COOKIE_NAME,
        error != null ? error.replaceAll(" ", "_") : "")
        ..httpOnly = false;
  }

  /// Returns a [Cookie] that can be used to delete the Error [Cookie].
  static Cookie createExpiredErrorCookie() {
    return createErrorCookie("")
        ..maxAge = 0;
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

/// Manages reading and writing of Cookies to the HTTP response.
class CookieManager {

  /// Adds the given [accessToken] to the [request]'s response as a [Cookie].
  static void addAccessTokenCookie(HttpRequest request, String accessToken) {
    request.response.cookies.add(
        CookiesHelper.createAccessTokenCookie(accessToken));
  }

  /// Adds the given [error] to the [request]'s response as a [Cookie].
  static void addErrorCookie(HttpRequest request, String error) {
    request.response.cookies.add(
        CookiesHelper.createErrorCookie("$error"));
  }

  /// Removes the [Cookie] containing the Access Token from the [request]'s
  /// response.
  static void removeAccessTokenCookie(HttpRequest request) {
    request.response.cookies.add(
        CookiesHelper.createExpiredAccessTokenCookie());
  }

  /// Removes the [Cookie] containing the Error from the [request]'s response.
  static void removeErrorCookie(HttpRequest request) {
    request.response.cookies.add(
        CookiesHelper.createExpiredErrorCookie());
  }

  /// Returns the value of the error contained in the error [Cookie] that's in
  /// the [request].
  static String getErrorFromCookie(HttpRequest request) {
    Cookie errorCookie = CookiesHelper.getErrorCookie(request);
    if (errorCookie == null) {
      return null;
    }
    return errorCookie.value.replaceAll("_", " ");
  }
}
