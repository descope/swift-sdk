# DescopeKit

DescopeKit is the Descope SDK for Swift. It provides convenient access to the Descope user management and authentication APIs
for applications written in Swift. You can read more on the [Descope Website](https://descope.com).

## Requirements

The SDK supports iOS 13 and above, and macOS 12 and above.

## Installing the SDK

Install the package using the [swift package manager](https://www.swift.org/package-manager/).

## Setup

A Descope `Project ID` is required to initialize the SDK. Find it on the
[project page in the Descope Console](https://app.descope.com/settings/project).

```swift
import DescopeKit

// ...

Descope.projectId = "<Your-Project-ID>"

```

## Usage

Here are some examples how to manage and authenticate users:

### OTP Authentication

Send a user a one-time password (OTP) using your preferred delivery method (_email / SMS_). An email address or phone number must be provided accordingly.

The user can either `sign up`, `sign in` or `sign up or in`

```swift
// Every user must have a loginID. All other user information is optional
try await Descope.otp.signUp(with: .email, loginId: "desmond_c@mail.com", user: User(
    name: "Desmond Copeland"
))
```

The user will receive a code using the selected delivery method. Verify that code using:

```swift
let descopeSession = try await Descope.otp.verify(with: .email, loginId: "desmond_c@mail.com", code: "123456")
```

The session and refresh JWTs should be passed with every request in the session. Read more on [session validation](#session-validation)

### Magic Link

Send a user a Magic Link using your preferred delivery method (_email / SMS_).
The Magic Link will redirect the user to page where the its token needs to be verified.
This redirection can be configured in code, or globally in the [Descope Console](https://app.descope.com/settings/authentication/magiclink)

The user can either `sign up`, `sign in` or `sign up or in`

```swift
// If configured globally, the redirect URI is optional. If provided however, it will be used
// instead of any global configuration
try await Descope.magiclink.signUp(with: .email, loginId: "desmond_c@mail.com", user: User(
    name: "Desmond Copeland"
))
```

To verify a magic link, your redirect page must call the validation function on the token (`t`) parameter (`https://your-redirect-address.com/verify?t=<token>`):

```swift
let descopeSession = try await Descope.magiclink.verify(token: "<token>")
```


The session and refresh JWTs should be passed with every request in the session. Read more on [session validation](#session-validation)

### OAuth

Users can authenticate using their social logins, using the OAuth protocol. Configure your OAuth settings on the [Descope console](https://app.descope.com/settings/authentication/social). To start a flow call:

```swift
// Choose an oauth provider out of the supported providers
// If configured globally, the redirect URL is optional. If provided however, it will be used
// instead of any global configuration.
// Redirect the user to the returned URL to start the OAuth redirect chain
let authURL = try await Descope.oauth.start(provider: .github, redirectURL: "exampleauthschema://my-app.com/handle-oauth")
guard let authURL = URL(string: url) else { return }
```

Take the generated URL and authenticate the user using `ASWebAuthenticationSession` (read more [here](https://developer.apple.com/documentation/authenticationservices/authenticating_a_user_through_a_web_service)).
The user will authenticate with the authentication provider, and will be redirected back to the redirect URL, with an appended `code` HTTP URL parameter. Exchange it to validate the user:

```swift
// Start the authentication session
let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: "exampleauthschema") { callbackURL, error in

    // Extract the returned code
    guard let url = callbackURL else {return}
    let component = URLComponents(url: url, resolvingAgainstBaseURL: false)
    guard let code = component?.queryItems?.first(where: {$0.name == "code"})?.value else { return }

    // ... Trigger asynchronously

    // Exchange code for session
    let descopeSession = try await Descope.oauth.exchange(code: code)
}
```

The session and refresh JWTs should be passed with every request in the session. Read more on [session validation](#session-validation)

### SSO/SAML

Users can authenticate to a specific tenant using SAML or Single Sign On. Configure your SSO/SAML settings on the [Descope console](https://app.descope.com/settings/authentication/sso). To start a flow call:

```swift
// Choose which tenant to log into
// If configured globally, the return URL is optional. If provided however, it will be used
// instead of any global configuration.
// Redirect the user to the returned URL to start the SSO/SAML redirect chain
let authURL = try await Descope.sso.start(emailOrTenantName: "my-tenant-ID", redirectURL: "exampleauthschema://my-app.com/handle-saml")
guard let authURL = URL(string: url) else { return }
```

Take the generated URL and authenticate the user using `ASWebAuthenticationSession` (read more [here](https://developer.apple.com/documentation/authenticationservices/authenticating_a_user_through_a_web_service)).
The user will authenticate with the authentication provider, and will be redirected back to the redirect URL, with an appended `code` HTTP URL parameter. Exchange it to validate the user:

```swift
// Start the authentication session
let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: "exampleauthschema")
{ callbackURL, error in

    // Extract the returned code
    guard let url = callbackURL else {return}
    let component = URLComponents(url: url, resolvingAgainstBaseURL: false)
    guard let code = component?.queryItems?.first(where: {$0.name == "code"})?.value else { return }

    // ... Trigger asynchronously

    // Exchange code for session
    let descopeSession = try await Descope.sso.exchange(code: code)

}
```

The session and refresh JWTs should be passed with every request in the session. Read more on [session validation](#session-validation)

### TOTP Authentication

The user can authenticate using an authenticator app, such as Google Authenticator.
Sign up like you would using any other authentication method. The sign up response
will then contain a QR code `image` that can be displayed to the user to scan using
their mobile device camera app, or the user can enter the `key` manually or click
on the link provided by the `provisioningURL`.

Existing users can add TOTP using the `update` function.

```swift
// Every user must have a loginID. All other user information is optional
let totpResponse = try await Descope.totp.signUp(loginId: "desmond@descope.com", user: User(
    name: "Desmond Copeland"
))

// Use one of the provided options to have the user add their credentials to the authenticator
// totpResponse.provisioningURL
// totpResponse.key
```

There are 3 different ways to allow the user to save their credentials in
their authenticator app - either by clicking the provisioning URL, scanning the QR
image or inserting the key manually. After that, signing in is done using the code
the app produces.

```swift
let descopeSession = try await Descope.totp.verify(loginId: "desmond@descope.com", code: "123456")
```

The session and refresh JWTs should be passed with every request in the session. Read more on [session validation](#session-validation)

### Session Validation

Every secure request performed between your client and server needs to be validated. The client sends
the session and refresh tokens with every request, to validated by the server.

On the server side, it will validate the session and also refresh it in the event it has expired.
Every request should receive the given session token if it's still valid, or a new one if it was refreshed.
Make sure to save the returned session as it might have been refreshed.

The `refreshToken` is optional here to validate a session, but is required to refresh the session in the event it has expired.

Usually, the tokens can be passed in and out via HTTP headers or via a cookie.
The implementation can defer according to your server implementation.
