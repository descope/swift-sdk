# DescopeKit

This Swift SDK integrates the easy, powerful and flexible authentication provided by [Descope](https://descope.com). This README will go through the quickest way you can get up and running with just a few lines of code.

## Initialization

`DescopeKit` needs to be initialized before we can start authenticating users. Somewhere in your app's initialization flow, add the following line:

```swift
import DescopeKit

// ...

Descope.projectId = "<Your-Project-ID>"

```

That's it really. You can get into the details and configure the SDK to your specific needs, but generally all you need is to set your project ID and you're good to go.

> _To find your project ID go into the descope console, into the `project` section._

## Usage

`DescopeKit` has a very consistent and intuitive usage pattern. It mostly varies according to the authentication method selected, which vary in their flow and functions.

The general usage pattern looks like this:

```swift
// Descope.<auth-method>.<auth-function>()
```

Let's look at some specific examples:

### OTP Example

To register a user using via one-time passcode sent to their email you would call:

```swift
try await Descope.otp.signUp(with: .email, identifier: "desmond_c@mail.com", user: User(
    name: "Desmond Copeland"
))
```

You can use a different authentication method according to user needs, such as `signUpOrIn` or `updateUser`, or any of the other supported methods.

Once the user enters their code call:

```swift
let tokens = try await Descope.otp.verify(with: .email, identifier: "desmond_c@mail.com", code: "123456")
```

After this call, `tokens` contain the session and refresh tokens that can be used to communicate with your backend securely.
