
import Foundation

/// General authentication functions
public protocol DescopeAuth {
    
    /// Returns details about the user. The user must have an active `DescopeSession`.
    ///
    /// - Parameter refreshJwt: the `refreshJwt` from an active `DescopeSession`.
    ///
    /// - Returns: A `MeResponse` object with the user details.
    func me(refreshJwt: String) async throws -> MeResponse
    
    /// Refreshes a session.
    ///
    /// This can be called at any time as long as the `refreshJwt` is still valid.
    /// Typically called when the `sessionJwt` is expired or about to be.
    ///
    /// - Parameter refreshJwt: the `refreshJwt` from an active `DescopeSession`.
    ///
    /// - Returns: A new `DescopeSession` with a refreshed `sessionJwt`.
    func refreshSession(refreshJwt: String) async throws -> DescopeSession
    
    /// Logs out from an active `DescopeSession`.
    ///
    /// - Parameter refreshJwt: the `refreshJwt` from an active `DescopeSession`.
    func logout(refreshJwt: String) async throws
}


/// Access key authentication methods
public protocol DescopeAccessKey {
    
    /// Exchanges an access key for a `DescopeToken` that can be used to perform
    /// authenticated requests.
    ///
    /// - Parameter accessKey: the access key's clear text
    ///
    /// - Returns: Upon successful exchange a `DescopeToken` is returned.
    func exchange(accessKey: String) async throws -> DescopeToken
}


/// Authenticate users using a one time password (OTP) code, sent via
/// a delivery method of choice. The code then needs to be verified using
/// the `verify(with:loginId:code)` function. It is also possible to add
/// an email or phone to an existing user after validating it via OTP.
public protocol DescopeOTP {
    
    /// Authenticates a new user using an OTP, sent via a delivery
    /// method of choice.
    ///
    /// - Important: Make sure the delivery information corresponding with
    ///     the delivery method is given either in the `user` parameter or as
    ///     the `loginId` itself, i.e., the email address, phone number, etc.
    ///
    /// - Parameters:
    ///   - method: Deliver the OTP code using this delivery method.
    ///   - loginId: What identifies the user when logging in,
    ///     typically an email, phone, or any other unique identifier.
    ///   - user: Details about the user signing up.
    func signUp(with method: DeliveryMethod, loginId: String, user: User) async throws -> String
    
    /// Authenticates an existing user using an OTP, sent via a delivery
    /// method of choice.
    ///
    /// - Parameters:
    ///   - method: Deliver the OTP code using this delivery method.
    ///   - loginId: What identifies the user when logging in,
    ///     typically an email, phone, or any other unique identifier.
    func signIn(with method: DeliveryMethod, loginId: String) async throws -> String
    
    /// Authenticates an existing user if one exists, or creates a new user
    /// using an OTP, sent via a delivery method of choice.
    ///
    /// - Important: Make sure the delivery information corresponding with
    ///     the delivery method is given in the `loginId` parameter, i.e., the
    ///     email address, phone number, etc.
    ///
    /// - Parameters:
    ///   - method: Deliver the OTP code using this delivery method.
    ///   - loginId: What identifies the user when logging in,
    ///     typically an email, phone, or any other unique identifier
    func signUpOrIn(with method: DeliveryMethod, loginId: String) async throws -> String
    
    /// Verifies an OTP code sent to the user.
    ///
    /// - Parameters:
    ///   - method: Which delivery method was used to send the OTP code
    ///   - loginId: The loginId value used to initiate the authentication.
    ///   - code: The code to validate.
    ///
    /// - Returns: Upon successful authentication a `DescopeSession` is returned.
    func verify(with method: DeliveryMethod, loginId: String, code: String) async throws -> DescopeSession
    
    /// Updates an existing user by adding an email address.
    ///
    /// The email will be updated after it is verified via OTP. In order to do this,
    /// the user must have an active `DescopeSession` whose `refreshJwt` should
    /// be passed as a parameter to this function.
    ///
    /// - Parameters:
    ///   - email: The email address to add.
    ///   - loginId: The existing user's loginId
    ///   - refreshJwt: The existing user's `refreshJwt` from an active `DescopeSession`.
    ///   - updateOptions - Decide whether to add this email as a login id, and in that case, how to handle conflicts with other user that has this email as ID
    func updateEmail(_ email: String, loginId: String, refreshJwt: String, updateOptions: UpdateOptions?) async throws -> String
    
    /// Updates an existing user by adding a phone number.
    ///
    /// The phone number will be updated after it is verified via OTP. In order to do
    /// this, the user must have an active `DescopeSession` whose `refreshJwt` should
    /// be passed as a parameter to this function.
    ///
    /// - Important: Make sure delivery method is appropriate for using a phone number.
    ///
    /// - Parameters:
    ///   - phone: The phone number to add.
    ///   - method: Deliver the OTP code using this delivery method.
    ///   - loginId: The existing user's loginId
    ///   - refreshJwt: The existing user's `refreshJwt` from an active `DescopeSession`.
    ///   - updateOptions - Decide whether to add this email as a login id, and in that case, how to handle conflicts with other user that has this email as ID
    func updatePhone(_ phone: String, with method: DeliveryMethod, loginId: String, refreshJwt: String, updateOptions: UpdateOptions?) async throws -> String
}


/// Authenticate users using Timed One-time Passwords (TOTP) codes.
///
/// This authentication method is geared towards using an authenticator app which
/// can produce TOTP codes.
public protocol DescopeTOTP {
    
    /// Authenticates a new user using a TOTP. This function returns the
    /// key (seed) that allows authenticator apps to generate TOTP codes.
    ///
    /// - Parameters:
    ///   - loginId: What identifies the user when logging in, typically
    ///     an email, phone, or any other unique identifier.
    ///   - user: Details about the user signing up.
    ///
    /// - Returns: A `TOTPResponse` object with the key (seed) in multiple formats.
    func signUp(loginId: String, user: User) async throws -> TOTPResponse
    
    /// Updates an existing user by adding TOTP as an authentication method.
    ///
    /// In order to do this, the user must have an active `DescopeSession` whose
    /// `refreshJwt` should be passed as a parameter to this function.
    ///
    /// The function returns the key (seed) that allows authenticator
    /// apps to generate TOTP codes.
    ///
    /// - Parameters:
    ///   - loginId: The existing user's loginId
    ///   - refreshJwt: The existing user's `refreshJwt` from an active `DescopeSession`.
    ///
    /// - Returns: A `TOTPResponse` object with the key (seed) in multiple formats.
    func update(loginId: String, refreshJwt: String) async throws -> TOTPResponse
    
    /// Verifies a TOTP code that was generated by an authenticator app.
    ///
    /// - Parameters:
    ///   - loginId: The `loginId` of the user trying to log in.
    ///   - code: The code to validate.
    ///
    /// - Returns: Upon successful authentication a `DescopeSession` is returned.
    func verify(loginId: String, code: String) async throws -> DescopeSession
}


/// Authenticate users using a password.
public protocol DescopePassword {
    
    /// Creates a new user that can later sign in with a password.
    ///
    /// - Parameters:
    ///   - loginId: What identifies the user when logging in, typically
    ///     an email, phone, or any other unique identifier.
    ///   - user: Details about the user signing up.
    ///   - password: The user's password.
    ///
    /// - Returns: Upon successful authentication a `DescopeSession` is returned.
    func signUp(loginId: String, user: User, password: String) async throws -> DescopeSession
    
    /// Authenticates an existing user using a password.
    ///
    /// - Parameters:
    ///   - loginId: What identifies the user when logging in,
    ///     typically an email, phone, or any other unique identifier.
    ///   - password: The user's password.
    ///
    /// - Returns: Upon successful authentication a `DescopeSession` is returned.
    func signIn(loginId: String, password: String) async throws -> DescopeSession

    /// Updates a user's password.
    ///
    /// In order to do this, the user must have an active `DescopeSession` whose
    /// `refreshJwt` should be passed as a parameter to this function.
    ///
    /// The value for `newPassword` must conform to the password policy defined in the
    /// password settings in the Descope console
    ///
    /// - Parameters:
    ///   - loginId: The existing user's loginId.
    ///   - newPassword: The new password to set for the user.
    ///   - refreshJwt: The existing user's `refreshJwt` from an active `DescopeSession`.
    func update(loginId: String, newPassword: String, refreshJwt: String) async throws
    
    /// Replaces a user's password by providing their current password.
    ///
    /// The value for `newPassword` must conform to the password policy defined in the
    /// password settings in the Descope console
    ///
    /// - Parameters:
    ///   - loginId: The existing user's loginId.
    ///   - oldPassword: The user's current password.
    ///   - newPassword: The new password to set for the user.
    func replace(loginId: String, oldPassword: String, newPassword: String) async throws
    
    /// Sends a password reset email to the user.
    ///
    /// This operation starts a Magic Link or Enchanted Link flow depending on the
    /// configuration in the Descope console. After the authentication flow is finished
    /// use the `refreshJwt` to call `update` and change the user's password.
    ///
    /// - Important: The user must be verified according to the configured
    /// password reset method.
    ///
    /// - Parameters:
    ///   - loginId: The existing user's loginId.
    ///   - redirectURL: Optional URL that is used by Magic Link or Enchanted Link
    ///     if those are the chosen reset methods.
    func sendReset(loginId: String, redirectURL: String?) async throws

    /// Fetches the rules for valid passwords.
    ///
    /// The policy is configured in the password settings in the Descope console, and
    /// these values can be used to implement client-side validation of new user passwords
    /// for a better user experience.
    ///
    /// In any case, all password rules are enforced by Descope on the server side as well.
    func getPolicy() async throws -> PasswordPolicy
}


/// Authenticate users using a special link that once clicked, can authenticate
/// the user.
///
/// In order to correctly implement, the app must make sure the link redirects back
/// to the app. Read more on [universal links](https://developer.apple.com/ios/universal-links/)
/// to learn more. Once redirected back to the app, call the `verify(token)` function
/// on the appended token URL parameter.
public protocol DescopeMagicLink {
    
    /// Authenticates a new user using a magic link, sent via a delivery
    /// method of choice.
    ///
    /// - Important: Make sure the delivery information corresponding with
    ///     the delivery method is given either in the `user` parameter or as
    ///     the `loginId` itself, i.e., the email address, phone number, etc.
    ///
    /// - Important: Make sure a default magic link URI is configured
    ///     in the Descope console, or provided by this call.
    ///
    /// - Parameters:
    ///   - method: Deliver the magic link using this delivery method.
    ///   - loginId: What identifies the user when logging in, typically
    ///     an email, phone, or any other unique identifier.
    ///   - user: Details about the user signing up.
    ///   - uri: Optional URI that will be used to generate the magic link.
    ///     If not given, the project default will be used.
    func signUp(with method: DeliveryMethod, loginId: String, user: User, uri: String?) async throws -> String
    
    /// Authenticates an existing user using a magic link, sent via a delivery
    /// method of choice.
    ///
    /// - Important: Make sure a default magic link URI is configured
    ///     in the Descope console, or provided by this call.
    ///
    /// - Parameters:
    ///   - method: Deliver the magic link using this delivery method.
    ///   - loginId: What identifies the user when logging in, typically
    ///     an email, phone, or any other unique identifier.
    ///   - uri: Optional URI that will be used to generate the magic link.
    ///     If not given, the project default will be used.
    func signIn(with method: DeliveryMethod, loginId: String, uri: String?) async throws -> String
    
    /// Authenticates an existing user if one exists, or creates a new user
    /// using a magic link, sent via a delivery method of choice.
    ///
    /// - Important: Make sure the delivery information corresponding with
    ///     the delivery method is given either in the `loginId` itself,
    ///     i.e., the email address, phone number, etc.
    ///
    /// - Important: Make sure a default magic link URI is configured
    ///     in the Descope console, or provided by this call.
    ///
    /// - Parameters:
    ///   - method: Deliver the magic link using this delivery method.
    ///   - loginId: What identifies the user when logging in, typically
    ///     an email, phone, or any other unique identifier
    ///   - uri: Optional URI that will be used to generate the magic link.
    ///     If not given, the project default will be used.
    func signUpOrIn(with method: DeliveryMethod, loginId: String, uri: String?) async throws -> String
    
    /// Updates an existing user by adding an email address.
    ///
    /// The email will be updated after it is verified via magic link. In order to do
    /// this, the user must have an active `DescopeSession` whose `refreshJwt` should
    /// be passed as a parameter to this function.
    ///
    /// - Parameters:
    ///   - email: The email address to add.
    ///   - loginId: The existing user's loginId
    ///   - uri: Optional URI that will be used to generate the magic link.
    ///     If not given, the project default will be used.
    ///   - refreshJwt: The existing user's `refreshJwt` from an active `DescopeSession`.
    ///   - updateOptions - Decide whether to add this email as a login id, and in that case, how to handle conflicts with other user that has this email as ID
    func updateEmail(_ email: String, loginId: String, uri: String?, refreshJwt: String, updateOptions: UpdateOptions?) async throws -> String
    
    /// Updates an existing user by adding a phone number.
    ///
    /// The phone number will be updated after it is verified via magic link. In order
    /// to do this, the user must have an active `DescopeSession` whose `refreshJwt` should
    /// be passed as a parameter to this function.
    ///
    /// - Important: Make sure the delivery information corresponding with
    ///     the phone number enabled delivery method.
    ///
    /// - Parameters:
    ///   - phone: The phone number to add.
    ///   - method: Deliver the OTP code using this delivery method.
    ///   - loginId: The existing user's loginId
    ///   - uri: Optional URI that will be used to generate the magic link.
    ///     If not given, the project default will be used.
    ///   - refreshJwt: The existing user's `refreshJwt` from an active `DescopeSession`.
    ///   - updateOptions - Decide whether to add this email as a login id, and in that case, how to handle conflicts with other user that has this email as ID
    func updatePhone(_ phone: String, with method: DeliveryMethod, loginId: String, uri: String?, refreshJwt: String, updateOptions: UpdateOptions?) async throws -> String
    
    /// Verifies a magic link token.
    ///
    /// In order to effectively do this, the link generated should refer back to
    /// the app, then the `t` URL parameter should be extracted and sent to this
    /// function. Upon successful authentication a `DescopeSession` is returned.
    ///
    /// - Parameter token: The extracted token from the `t` URL parameter from the magic link.
    ///
    /// - Returns: Upon successful authentication a `DescopeSession` is returned.
    func verify(token: String) async throws -> DescopeSession
}


/// Authenticate users using one of three special links that once clicked,
/// can authenticate the user.
///
/// This method is geared towards cross-device authentication. In order to
/// correctly implement, the app must make sure the uri redirects to a webpage
/// which will verify the link for them. The app will poll for a valid session
/// in the meantime, and will authenticate the user as soon as they are
/// verified via said webpage. To learn more consult the
/// official Descope docs.
public protocol DescopeEnchantedLink {
    
    /// Authenticates a new user using an enchanted link, sent via email.
    ///
    /// The caller should use the returned `EnchantedLinkResponse` object to show the
    /// user which link they need to press in the enchanted link email, and then use
    /// the `pendingRef` value to poll until the authentication is verified.
    ///
    /// - Important: Make sure an email address is provided via
    ///     the `user` parameter or as the `loginId` itself.
    ///
    /// - Important: Make sure a default Enchanted link URI is configured
    ///     in the Descope console, or provided by this call.
    ///
    /// - Parameters:
    ///   - loginId: What identifies the user when logging in, typically
    ///     an email, phone, or any other unique identifier.
    ///   - user: Details about the user signing up.
    ///   - uri: Optional URI that will be used to generate the magic link.
    ///     If not given, the project default will be used.
    ///
    /// - Returns: An `EnchantedLinkResponse` object with the `linkId` to show the
    ///     user and `pendingRef` for polling for the session.
    func signUp(loginId: String, user: User, uri: String?) async throws -> EnchantedLinkResponse
    
    /// Authenticates an existing user using an enchanted link, sent via email.
    ///
    /// The caller should use the returned `EnchantedLinkResponse` object to show the
    /// user which link they need to press in the enchanted link email, and then use
    /// the `pendingRef` value to poll until the authentication is verified.
    ///
    /// - Important: Make sure a default Enchanted link URI is configured
    ///     in the Descope console, or provided by this call.
    ///
    /// - Parameters:
    ///   - loginId: What identifies the user when logging in, typically
    ///     an email, phone, or any other unique identifier.
    ///   - uri: Optional URI that will be used to generate the magic link.
    ///     If not given, the project default will be used.
    ///
    /// - Returns: An `EnchantedLinkResponse` object with the `linkId` to show the
    ///     user and `pendingRef` for polling for the session.
    func signIn(loginId: String, uri: String?) async throws -> EnchantedLinkResponse
    
    /// Authenticates an existing user if one exists, or create a new user using an
    /// enchanted link, sent via email.
    ///
    /// The caller should use the returned `EnchantedLinkResponse` object to show the
    /// user which link they need to press in the enchanted link email, and then use
    /// the `pendingRef` value to poll until the authentication is verified.
    ///
    /// - Important: Make sure a default Enchanted link URI is configured
    ///     in the Descope console, or provided by this call.
    ///
    /// - Parameters:
    ///   - loginId: What identifies the user when logging in, typically
    ///     an email, phone, or any other unique identifier.
    ///   - uri: Optional URI that will be used to generate the magic link.
    ///     If not given, the project default will be used.
    ///
    /// - Returns: An `EnchantedLinkResponse` object with the `linkId` to show the
    ///     user and `pendingRef` for polling for the session.
    func signUpOrIn(loginId: String, uri: String?) async throws -> EnchantedLinkResponse
    
    /// Updates an existing user by adding an email address.
    ///
    /// The email will be updated after it is verified via enchanted link. In order to
    /// do this, the user must have an active `DescopeSession` whose `refreshJwt` should
    /// be passed as a parameter to this function.
    ///
    /// The caller should use the returned `EnchantedLinkResponse` object to show the
    /// user which link they need to press in the enchanted link email, and then use
    /// the `pendingRef` value to poll until the authentication is verified.
    ///
    /// - Parameters:
    ///   - email: The email address to add.
    ///   - loginId: The existing user's loginId
    ///   - uri: Optional URI that will be used to generate the magic link.
    ///     If not given, the project default will be used.
    ///   - refreshJwt: The existing user's `refreshJwt` from an active `DescopeSession`.
    ///   - updateOptions - Decide whether to add this email as a login id, and in that case, how to handle conflicts with other user that has this email as ID
    ///
    /// - Returns: An `EnchantedLinkResponse` object with the `linkId` to show the
    ///     user and `pendingRef` for polling for the session.
    func updateEmail(_ email: String, loginId: String, uri: String?, refreshJwt: String, updateOptions: UpdateOptions?) async throws -> EnchantedLinkResponse
    
    /// Checks if an enchanted link authentication has been verified by the user.
    ///
    /// This function will only return a `DescopeSession` successfully after the user
    /// presses the enchanted link in the authentication email.
    ///
    /// - Important: This function doesn't perform any polling or waiting, so calling code
    ///     should expect to catch any thrown `DescopeError.enchantedLinkPending` errors and
    ///     handle them appropriately. For most use cases it might be more convenient to
    ///     use `pollForSession` instead.
    ///
    /// - Parameter pendingRef: The pendingRef value from an `EnchantedLinkResponse` object.
    ///
    /// - Returns: Upon successful authentication a `DescopeSession` is returned.
    func checkForSession(pendingRef: String) async throws -> DescopeSession
    
    /// Waits until an enchanted link authentication has been verified by the user.
    ///
    /// This function will only return a `DescopeSession` successfully after the user
    /// presses the enchanted link in the authentication email.
    ///
    /// This function calls `checkForSession` periodically until the authentication
    /// is verified. It will keep polling even if it encounters network errors, but
    /// any other unexpected errors will be rethrown. If the timeout expires a
    /// `DescopeError.enchantedLinkExpired` error is thrown.
    ///
    /// If the current task is cancelled, this function will stop polling and
    /// throw a `CancellationError` as expected.
    ///
    /// - Parameters:
    ///   - pendingRef: The pendingRef value from an `EnchantedLinkResponse` object.
    ///   - timeout: An optional number of seconds to poll for until giving up. If not
    ///     given a default value of 2 minutes is used.
    ///
    /// - Returns: Upon successful authentication a `DescopeSession` is returned.
    func pollForSession(pendingRef: String, timeout: TimeInterval?) async throws -> DescopeSession
}


/// Authenticate a user using an OAuth provider.
///
/// Use the Descope console to configure which authentication provider you'd like to support.
/// It's recommended to use `ASWebAuthenticationSession` to perform the authentication
///
/// For further reference see: [Authenticating a User Through a Web Service](https://developer.apple.com/documentation/authenticationservices/authenticating_a_user_through_a_web_service)
public protocol DescopeOAuth {
    
    /// Starts an OAuth redirect chain to authenticate a user.
    ///
    /// It's recommended to use `ASWebAuthenticationSession` to perform the authentication.
    ///
    /// - Important: Make sure a default OAuth redirect URL is configured
    ///     in the Descope console, or provided by this call.
    ///
    /// - Parameters:
    ///   - provider: The provider the user wishes to be authenticated by.
    ///   - redirectURL: An optional parameter to generate the OAuth link.
    ///     If not given, the project default will be used.
    ///
    /// - Returns: A URL to redirect to in order to authenticate the user against
    ///     the chosen provider.
    func start(provider: OAuthProvider, redirectURL: String?) async throws -> String
    
    /// Completes an OAuth redirect chain by exchanging the code received in
    /// the `code` URL parameter for a `DescopeSession`.
    ///
    /// - Parameter code: The code appended to the returning URL via the
    ///     `code` URL parameter.
    ///
    /// - Returns: Upon successful exchange a `DescopeSession` is returned.
    func exchange(code: String) async throws -> DescopeSession
}


/// Authenticate a user using a SSO.
///
/// Use the Descope console to configure your SSO details in order for this method to work properly.
/// It's recommended to use `ASWebAuthenticationSession` to perform the authentication
///
/// For further reference see: [Authenticating a User Through a Web Service](https://developer.apple.com/documentation/authenticationservices/authenticating_a_user_through_a_web_service)
public protocol DescopeSSO {
    
    /// Starts an SSO redirect chain to authenticate a user.
    ///
    /// It's recommended to use `ASWebAuthenticationSession` to perform the authentication.
    ///
    /// - Important: Make sure a default SSO redirect URL is configured
    ///     in the Descope console, or provided by this call.
    ///
    /// - Parameters:
    ///   - provider: The provider the user wishes to be authenticated by.
    ///   - redirectURL: An optional parameter to generate the SSO link.
    ///     If not given, the project default will be used.
    ///
    /// - Returns: A URL to redirect to in order to authenticate the user against
    ///     the chosen provider.
    func start(emailOrTenantName: String, redirectURL: String?) async throws -> String
    
    /// Completes an SSO redirect chain by exchanging the code received in
    /// the `code` URL parameter for a `DescopeSession`.
    ///
    /// - Parameter code: The code appended to the returning URL via the
    ///     `code` URL parameter.
    ///
    /// - Returns: Upon successful exchange a `DescopeSession` is returned.
    func exchange(code: String) async throws -> DescopeSession
}
