/// General Authentication functions
public protocol DescopeAuth {
    
    /// Return information on the user. The user must have an active `DescopeSession`.
    ///
    /// - Parameter refereshJwt: the `refreshJwt` from an active `DescopeSession`.
    func me(refreshJwt: String) async throws -> MeResponse
    
    /// Refresh a session. This can be called at any time as long as the
    /// `refreshJwt` is still valid. Typically called when the `sessionJwt`
    /// is expired or about to be. Returns a new `DescopeSession` with a
    /// refreshed `sessionJwt`.
    ///
    /// - Parameter refereshJwt: the `refreshJwt` from an active `DescopeSession`.
    func refreshSession(refreshJwt: String) async throws -> DescopeSession
    
    /// Logout of an active `DescopeSession`.
    ///
    /// - Parameter refereshJwt: the `refreshJwt` from an active `DescopeSession`.
    func logout(refreshJwt: String) async throws
}

/// Access Key authentication methods
public protocol DescopeAccessKey {
    /// Exchange an accessKey for a `DescopeToken`. This token can be used
    /// to perform authenticated requests.
    ///
    /// - Parameter accessKey: the access key to exchange
    func exchange(accessKey: String) async throws -> DescopeToken
}

/// Authenticate users using a One-time password (OTP), sent via a delivery
/// method of choice. That code then needs to be verified using the
/// `verify(with:loginId:code)` function. It is also possible to add
/// an email or phone to an existing user, validating it via OTP.
public protocol DescopeOTP {
    
    /// Authenticate a new user using an OTP, sent via a delivery
    /// method of choice.
    ///
    /// - Important: Make sure the delivery information corresponding with
    ///     the delivery method is given either in the `user` paramter or as
    ///     the `loginId` itself, i.e. email address, phone number, etc.
    ///
    /// - Parameter with: deliver the OTP code using this delivery method.
    /// - Parameter loginId: What identifies the user when logging in, typaclly
    ///     an email, phone, or any other unique identifier.
    /// - Parameter user: Metadata on the user signing up.
    func signUp(with method: DeliveryMethod, loginId: String, user: User) async throws
    
    /// Authenticate an existing user using an OTP, sent via a delivery
    /// method of choice.
    ///
    /// - Parameter with: deliver the OTP code using this delivery method.
    /// - Parameter loginId: What identifies the user when logging in, typaclly
    ///     an email, phone, or any other unique identifier.
    func signIn(with method: DeliveryMethod, loginId: String) async throws
    
    /// Authenticate an existing user if one exists, or create a new user
    /// using an OTP, sent via a delivery method of choice.
    ///
    /// - Important: Make sure the delivery information corresponding with
    ///     the delivery method is given either in the `loginId` itself,
    ///     i.e. email address, phone number, etc.
    ///
    /// - Parameter with: deliver the OTP code using this delivery method.
    /// - Parameter loginId: What identifies the user when logging in, typaclly
    ///     an email, phone, or any other unique identifier
    func signUpOrIn(with method: DeliveryMethod, loginId: String) async throws
    
    /// Verify an OTP code sent to the user. Upon successful authentication a
    /// `DescopeSession` is returned.
    ///
    /// - Parameter with: which delivery method was used to send the OTP code
    /// - Parameter loginId: The `loginId` used to initiate the authentication.
    /// - Parameter code: The code to validate.
    func verify(with method: DeliveryMethod, loginId: String, code: String) async throws -> DescopeSession
    
    /// Update an existing user by adding an email address. This address will be added once
    /// verified via OTP. In order to do this, the user must have an active `DescopeSession`.
    ///
    /// - Parameter email: The email address to add.
    /// - Parameter loginId: The existing user's loginId
    /// - Parameter refreshJwt: The existing user's `refreshJwt` an active `DescopeSession`.
    func updateEmail(_ email: String, loginId: String, refreshJwt: String) async throws
    
    /// Update an existing user by adding a phone number. This number will be added once
    /// verified via OTP. In order to do this, the user must have an active `DescopeSession`.
    ///
    /// - Important: Make sure the delivery information corresponding with
    ///     the phone number enabled delivery method.
    ///
    /// - Parameter phone: The phone number to add.
    /// - Parameter with: deliver the OTP code using this delivery method.
    /// - Parameter loginId: The existing user's loginId
    /// - Parameter refreshJwt: The existing user's `refreshJwt` an active `DescopeSession`.
    func updatePhone(_ phone: String, with method: DeliveryMethod, loginId: String, refreshJwt: String) async throws
}

/// Authenticate users using Timed One-time Passwords (TOTP). This authentication
/// method is geared towards using an authenticator app which can produce
/// TOTP codes.
public protocol DescopeTOTP {
    
    /// Authenticate a new user using a TOTP. This function returns the
    /// key (seed) that allows authenticator apps to generate TOTP codes.
    ///
    /// - Parameter loginId: What identifies the user when logging in, typaclly
    ///     an email, phone, or any other unique identifier.
    /// - Parameter user: Metadata on the user signing up.
    func signUp(loginId: String, user: User) async throws -> TOTPResponse
    
    /// Update an existing user by adding TOTP as an authentication method.
    /// In order to do this, the user must have an active `DescopeSession`.
    /// This function returns the key (seed) that allows authenticator
    /// apps to generate TOTP codes.
    ///
    /// - Parameter loginId: The existing user's loginId
    /// - Parameter refreshJwt: The existing user's `refreshJwt` an active `DescopeSession`.
    func update(loginId: String, refreshJwt: String) async throws -> TOTPResponse
    
    /// Verify a TOTP code sent generated by an authenticator app.
    /// Upon successful authentication a `DescopeSession` is returned.
    ///
    /// - Parameter loginId: The `loginId` of the user trying to log in.
    /// - Parameter code: The code to validate.
    func verify(loginId: String, code: String) async throws -> DescopeSession
}

/// Authenticate users using a special link that once clicked, can authenticated
/// the user. In order to correctly implement, the app must make sure the link
/// redirects back to the app. Read more on universal links (https://developer.apple.com/ios/universal-links/)
/// to learn more. Once redirected back to the app, call the `verify(token)` function
/// on the appended token URL parameter.
public protocol DescopeMagicLink {
    
    /// Authenticate a new user using a magic link, sent via a delivery
    /// method of choice.
    ///
    /// - Important: Make sure the delivery information corresponding with
    ///     the delivery method is given either in the `user` paramter or as
    ///     the `loginId` itself, i.e. email address, phone number, etc.
    ///
    ///  - Important: Make sure a default magic link URI is configured
    ///     in the descope console, or provideded by this call.
    ///
    /// - Parameter with: deliver the magic link using this delivery method.
    /// - Parameter loginId: What identifies the user when logging in, typaclly
    ///     an email, phone, or any other unique identifier.
    /// - Parameter user: Metadata on the user signing up.
    /// - Parameter uri: Optional URI that will be used to generate the magic link.
    ///     If not given, the project default will be used.
    func signUp(with method: DeliveryMethod, loginId: String, user: User, uri: String?) async throws
    
    /// Authenticate an existing user using an OTP, sent via a delivery
    /// method of choice.
    ///
    /// - Important: Make sure a default magic link URI is configured
    ///     in the descope console, or provideded by this call.
    ///
    /// - Parameter with: deliver the OTP code using this delivery method.
    /// - Parameter loginId: What identifies the user when logging in, typaclly
    ///     an email, phone, or any other unique identifier.
    /// - Parameter uri: Optional URI that will be used to generate the magic link.
    ///     If not given, the project default will be used.
    func signIn(with method: DeliveryMethod, loginId: String, uri: String?) async throws
    
    /// Authenticate an existing user if one exists, or create a new user
    /// using a magic link, sent via a delivery method of choice.
    ///
    /// - Important: Make sure the delivery information corresponding with
    ///     the delivery method is given either in the `loginId` itself,
    ///     i.e. email address, phone number, etc.
    ///
    /// - Important: Make sure a default magic link URI is configured
    ///     in the descope console, or provideded by this call.
    ///
    /// - Parameter with: deliver the OTP code using this delivery method.
    /// - Parameter loginId: What identifies the user when logging in, typaclly
    ///     an email, phone, or any other unique identifier
    /// - Parameter uri: Optional URI that will be used to generate the magic link.
    ///     If not given, the project default will be used.
    func signUpOrIn(with method: DeliveryMethod, loginId: String, uri: String?) async throws
    
    /// Update an existing user by adding an email address. This address will be added once
    /// verified via magic link. In order to do this, the user must have an active `DescopeSession`.
    ///
    /// - Parameter email: The email address to add.
    /// - Parameter loginId: The existing user's loginId
    /// - Parameter uri: Optional URI that will be used to generate the magic link.
    ///     If not given, the project default will be used.
    /// - Parameter refreshJwt: The existing user's `refreshJwt` an active `DescopeSession`.
    func updateEmail(_ email: String, loginId: String, uri: String?, refreshJwt: String) async throws
    
    /// Update an existing user by adding a phone number. This number will be added once
    /// verified via magic link. In order to do this, the user must have an active `DescopeSession`.
    ///
    /// - Important: Make sure the delivery information corresponding with
    ///     the phone number enabled delivery method.
    ///
    /// - Parameter phone: The phone number to add.
    /// - Parameter with: deliver the OTP code using this delivery method.
    /// - Parameter loginId: The existing user's loginId
    /// - Parameter uri: Optional URI that will be used to generate the magic link.
    ///     If not given, the project default will be used.
    /// - Parameter refreshJwt: The existing user's `refreshJwt` an active `DescopeSession`.
    func updatePhone(_ phone: String, with method: DeliveryMethod, loginId: String, uri: String?, refreshJwt: String) async throws
    
    /// Verify a magic link token. In order to effectively do this, the link generated
    /// should refer back to the app, then the `t` URL parameter should be extracted and
    /// sent to this function. Upon successful authentication a `DescopeSession` is returned.
    ///
    /// - Parameter token: The extracted token from the `t` URL parameter from the magic link.
    func verify(token: String) async throws -> DescopeSession
}

/// Authenticate users using one of three special links that once clicked, can authenticated
/// the user. This method is geared towards cross-device authentication. In order to correctly implement,
/// the app must make sure the link redirects to a web page which will verify the link for them.
/// The app will poll for a valid session in the meantime, and will authenticate the user as
/// soon as they are verified via said webpage. To learn more read the official descope docs
public protocol DescopeEnchantedLink {
    
    /// Authenticate a new user using an enchanted link, sent via email. This method will return
    /// a `DescopeSession` once the user successfully verfies the enchanted link,
    /// using a dedicated web page. It will throw an error if timed out during the process.
    ///
    /// - Important: Make sure an email address is provided via the `user` paramter or as
    ///     the `loginId` itself.
    ///
    ///  - Important: Make sure a default Enchanted link URI is configured
    ///     in the descope console, or provideded by this call.
    ///
    /// - Parameter loginId: What identifies the user when logging in, typaclly
    ///     an email, phone, or any other unique identifier.
    /// - Parameter user: Metadata on the user signing up.
    /// - Parameter uri: Optional URI that will be used to generate the magic link.
    ///     If not given, the project default will be used.
    func signUp(loginId: String, user: User, uri: String?) async throws -> DescopeSession
    
    /// Authenticate an existing user using an enchanted link, sent via email. This method will return
    /// a `DescopeSession` once the user successfully verfies the enchanted link,
    /// using a dedicated web page. It will throw an error if timed out during the process.
    ///
    ///  - Important: Make sure a default Enchanted link URI is configured
    ///     in the descope console, or provideded by this call.
    ///
    /// - Parameter loginId: What identifies the user when logging in, typaclly
    ///     an email, phone, or any other unique identifier.
    /// - Parameter uri: Optional URI that will be used to generate the magic link.
    ///     If not given, the project default will be used.
    func signIn(loginId: String, uri: String?) async throws -> DescopeSession
    
    /// Authenticate an existing user if one exists, or create a new user
    /// using an enchanged link, sent via email. This method will return
    /// a `DescopeSession` once the user successfully verfies the enchanted link,
    /// using a dedicated web page. It will throw an error if timed out during the process.
    ///
    ///  - Important: Make sure a default Enchanted link URI is configured
    ///     in the descope console, or provideded by this call.
    ///
    /// - Parameter loginId: What identifies the user when logging in, typaclly
    ///     an email, phone, or any other unique identifier.
    /// - Parameter uri: Optional URI that will be used to generate the magic link.
    ///     If not given, the project default will be used.
    func signUpOrIn(loginId: String, uri: String?) async throws -> DescopeSession
    
    /// Update an existing user by adding an email address. This address will be added once
    /// verified via enchanted link. In order to do this, the user must have an active `DescopeSession`.
    /// This method will return comeplete once the user successfully verfies the enchanted link,
    /// using a dedicated web page. It will throw an error if timed out during the process.
    ///
    /// - Parameter email: The email address to add.
    /// - Parameter loginId: The existing user's loginId
    /// - Parameter uri: Optional URI that will be used to generate the magic link.
    ///     If not given, the project default will be used.
    /// - Parameter refreshJwt: The existing user's `refreshJwt` an active `DescopeSession`.
    func updateEmail(_ email: String, loginId: String, uri: String?, refreshJwt: String) async throws
}

/// Authenticate a user using an OAuth provider. Use the descope console to configure
/// which authentication provider you'd like to support.
/// It's recommend to use `ASWebAuthenticationSession` to perform the authentication
/// (read more: https://developer.apple.com/documentation/authenticationservices/authenticating_a_user_through_a_web_service ).
public protocol DescopeOAuth {
    
    /// Start an OAuth redirect chain to authenticated a user. Returns a URL to redirect
    /// to, in order to authenticate the user against the chosen provider.
    /// It's recommend to use `ASWebAuthenticationSession` to perform the authentication.
    ///
    ///  - Important: Make sure a default OAuth redirect URL is configured
    ///     in the descope console, or provideded by this call.
    ///
    /// - Parameter provider: The provider the user wishes to be authenticated by.
    /// - Parameter redirectURL: An optional parameter to generate the OAuth link.
    ///     If not given, the project default will be used.
    func start(provider: OAuthProvider, redirectURL: String?) async throws -> String
    
    /// Complete an oauth redirect chain by exchanging the code received in the
    /// `code` URL parameter for a `DescopeSession`.
    ///
    /// - Parameter code: The code appended to the returning URL via the
    ///     `code` URL parameter.
    func exchange(code: String) async throws -> DescopeSession
}

/// Authenticate a user using a SSO. Use the descope console to configure
/// your SSO details in order for this method to work properly.
/// It's recommend to use `ASWebAuthenticationSession` to perform the authentication
/// (read more: https://developer.apple.com/documentation/authenticationservices/authenticating_a_user_through_a_web_service ).
public protocol DescopeSSO {
    
    /// Start an SSO redirect chain to authenticated a user. Returns a URL to redirect
    /// to, in order to authenticate the user against the chosen provider.
    /// It's recommend to use `ASWebAuthenticationSession` to perform the authentication.
    ///
    ///  - Important: Make sure a default SSO redirect URL is configured
    ///     in the descope console, or provideded by this call.
    ///
    /// - Parameter provider: The provider the user wishes to be authenticated by.
    /// - Parameter redirectURL: An optional parameter to generate the SSO link.
    ///     If not given, the project default will be used.
    func start(emailOrTenantName: String, redirectURL: String?) async throws -> String
    
    /// Complete an SSO redirect chain by exchanging the code received in the
    /// `code` URL parameter for a `DescopeSession`.
    ///
    /// - Parameter code: The code appended to the returning URL via the
    ///     `code` URL parameter.
    func exchange(code: String) async throws -> DescopeSession
}
