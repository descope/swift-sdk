# DescopeKit

DescopeKit is the Descope SDK for Swift. It provides convenient access
to the Descope user management and authentication APIs for applications
written in Swift. You can read more on the [Descope Website](https://descope.com).

## Setup

Add the `DescopeKit` package using the [Swift package manager](https://www.swift.org/package-manager/).

The SDK supports iOS 13 and above, and macOS 12 and above.

## Quickstart 

A Descope `Project ID` is required to initialize the SDK. Find it
on the [project page](https://app.descope.com/settings/project) in
the Descope Console.

```swift
import DescopeKit

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    Descope.projectId = "<Your-Project-Id>"
    return true
}
```

Authenticate the user in your application by starting one of the
authentication methods. For example, let's use OTP via email: 

```swift
// sends an OTP code to the given email address
try await Descope.otp.signUp(with: .email, loginId: "andy@example.com", details: nil)
...
```

Finish the authentication by verifying the OTP code the user entered: 

```swift
// if the user entered the right code the authentication is successful  
let authResponse = try await Descope.otp.verify(with: .email, loginId: "andy@example.com", code: code)

// we create a DescopeSession object that represents an authenticated user session
let session = DescopeSession(from: authResponse)

// the session manager automatically takes care of persisting the session
// and refreshing it as needed
Descope.sessionManager.manageSession(session)
```

On the next application launch check if there's a logged in user to
decide which screen to show:

```swift
func initialViewController() -> UIViewController {
    // check if we have a valid session from a previous launch and that it hasn't expired yet 
    if let session = Descope.sessionManager.session, !session.refreshToken.isExpired {
        print("Authenticated user found: \(session.user)")
        return MainViewController()
    }
    return LoginViewController()
}
```

Use the active session to authenticate outgoing API requests to the
application's backend:

```swift
var request = URLRequest(url: url)
try await request.setAuthorizationHTTPHeaderField(from: Descope.sessionManager)
let (data, response) = try await URLSession.shared.data(for: request)
```

## Session Management

The `DescopeSessionManager` class is used to manage an authenticated
user session for an application.

The session manager takes care of loading and saving the session as well
as ensuring that it's refreshed when needed. For the default instances of
the `DescopeSessionManager` class this means using the keychain for secure
storage of the session and refreshing it a short while before it expires.

Once the user completes a sign in flow successfully you should set the
`DescopeSession` object as the active session of the session manager.

```swift
let authResponse = try await Descope.otp.verify(with: .email, loginId: "andy@example.com", code: "123456")
let session = DescopeSession(from: authResponse)
Descope.sessionManager.manageSession(session)
```

The session manager can then be used at any time to ensure the session
is valid and to authenticate outgoing requests to your backend with a
bearer token authorization header.

```swift
var request = URLRequest(url: url)
try await request.setAuthorizationHTTPHeaderField(from: Descope.sessionManager)
let (data, response) = try await URLSession.shared.data(for: request)
```

If your backend uses a different authorization mechanism you can of course
use the session JWT directly instead of the extension function. You can either
add another extension function on `URLRequest` such as the one above, or you
can do the following.

```swift
try await Descope.sessionManager.refreshSessionIfNeeded()
guard let sessionJwt = Descope.sessionManager.session?.sessionJwt else { throw ServerError.unauthorized }
request.setValue(sessionJwt, forHTTPHeaderField: "X-Auth-Token")
```

When the application is relaunched the `DescopeSessionManager` loads any
existing session automatically, so you can check straight away if there's
an authenticated user.

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    Descope.projectId = "..."
    if let session = Descope.sessionManager.session {
        print("User is logged in: \(session)")
    }
    return true
}
```

When the user wants to sign out of the application we revoke the
active session and clear it from the session manager:

```swift
guard let refreshJwt = Descope.sessionManager.session?.refreshJwt else { return }
try await Descope.auth.logout(refreshJwt: refreshJwt)
Descope.sessionManager.clearSession()
```

You can customize how the `DescopeSessionManager` behaves by using
your own `storage` and `lifecycle` objects. See the documentation
for more details.

## Authentication Methods

Here are some examples for how to authenticate users:

### OTP Authentication

Send a user a one-time password (OTP) using your preferred delivery
method (_email / SMS_). An email address or phone number must be
provided accordingly.

The user can either `sign up`, `sign in` or `sign up or in`

```swift
// Every user must have a loginId. All other user details are optional:
try await Descope.otp.signUp(with: .email, loginId: "andy@example.com", details: SignUpDetails(
    name: "Andy Rhoads"
))
```

The user will receive a code using the selected delivery method. Verify
that code using:

```swift
let descopeSession = try await Descope.otp.verify(with: .email, loginId: "andy@example.com", code: "123456")
```

### Magic Link

Send a user a Magic Link using your preferred delivery method (_email / SMS_).
The Magic Link will redirect the user to page where the its token needs
to be verified. This redirection can be configured in code, or globally
in the [Descope Console](https://app.descope.com/settings/authentication/magiclink)

The user can either `sign up`, `sign in` or `sign up or in`

```swift
// If configured globally, the redirect URI is optional. If provided however, it will be used
// instead of any global configuration
try await Descope.magiclink.signUp(with: .email, loginId: "andy@example.com", details: nil)
```

To verify a magic link, your redirect page must call the validation function
on the token (`t`) parameter (`https://your-redirect-address.com/verify?t=<token>`):

```swift
let descopeSession = try await Descope.magiclink.verify(token: "<token>")
```

### OAuth

Users can authenticate using their social logins, using the OAuth protocol.
Configure your OAuth settings on the [Descope console](https://app.descope.com/settings/authentication/social).
To start a flow call:

```swift
// Choose an oauth provider out of the supported providers
// If configured globally, the redirect URL is optional. If provided however, it will be used
// instead of any global configuration.
// Redirect the user to the returned URL to start the OAuth redirect chain
let authURL = try await Descope.oauth.start(provider: .github, redirectURL: "exampleauthschema://my-app.com/handle-oauth")
guard let authURL = URL(string: url) else { return }
```

Take the generated URL and authenticate the user using `ASWebAuthenticationSession`
(read more [here](https://developer.apple.com/documentation/authenticationservices/authenticating_a_user_through_a_web_service)).
The user will authenticate with the authentication provider, and will be
redirected back to the redirect URL, with an appended `code` HTTP URL parameter.
Exchange it to validate the user:

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

### SSO/SAML

Users can authenticate to a specific tenant using SAML or Single Sign On.
Configure your SSO/SAML settings on the [Descope console](https://app.descope.com/settings/authentication/sso).
To start a flow call:

```swift
// Choose which tenant to log into
// If configured globally, the return URL is optional. If provided however, it will be used
// instead of any global configuration.
// Redirect the user to the returned URL to start the SSO/SAML redirect chain
let authURL = try await Descope.sso.start(emailOrTenantName: "my-tenant-ID", redirectURL: "exampleauthschema://my-app.com/handle-saml")
guard let authURL = URL(string: url) else { return }
```

Take the generated URL and authenticate the user using `ASWebAuthenticationSession`
(read more [here](https://developer.apple.com/documentation/authenticationservices/authenticating_a_user_through_a_web_service)).
The user will authenticate with the authentication provider, and will be redirected
back to the redirect URL, with an appended `code` HTTP URL parameter. Exchange it
to validate the user:

```swift
// Start the authentication session
let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: "exampleauthschema") { callbackURL, error in

    // Extract the returned code
    guard let url = callbackURL else {return}
    let component = URLComponents(url: url, resolvingAgainstBaseURL: false)
    guard let code = component?.queryItems?.first(where: {$0.name == "code"})?.value else { return }

    // ... Trigger asynchronously

    // Exchange code for session
    let descopeSession = try await Descope.sso.exchange(code: code)
}
```

### TOTP Authentication

The user can authenticate using an authenticator app, such as Google Authenticator.
Sign up like you would using any other authentication method. The sign up response
will then contain a QR code `image` that can be displayed to the user to scan using
their mobile device camera app, or the user can enter the `key` manually or click
on the link provided by the `provisioningURL`.

Existing users can add TOTP using the `update` function.

```swift
// Every user must have a loginID. All other user information is optional
let totpResponse = try await Descope.totp.signUp(loginId: "andy@example.com", details: nil)

// Use one of the provided options to have the user add their credentials to the authenticator
// totpResponse.provisioningURL
// totpResponse.key
```

There are 3 different ways to allow the user to save their credentials in their
authenticator app - either by clicking the provisioning URL, scanning the QR
image or inserting the key manually. After that, signing in is done using the
code the app produces.

```swift
let descopeSession = try await Descope.totp.verify(loginId: "andy@example.com", code: "987654")
```
