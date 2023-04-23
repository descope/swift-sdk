// Generated using Sourcery 2.0.1 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// Regenerate by running:
//     brew install sourcery
//     sourcery --parseDocumentation --sources src/sdk/Routes.swift --templates src/sdk/Callbacks.stencil --output src/sdk/Callbacks.swift

// Convenience functions for working with completion handlers.

import Foundation

public extension DescopeAccessKey {
    /// Exchanges an access key for a `DescopeToken` that can be used to perform
    /// authenticated requests.
    /// 
    /// - Parameter accessKey: the access key's clear text
    /// 
    /// - Returns: Upon successful exchange a `DescopeToken` is returned.
    func exchange(accessKey: String, completion: @escaping (Result<DescopeToken, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await exchange(accessKey: accessKey)))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

public extension DescopeAuth {
    /// Returns details about the user. The user must have an active `DescopeSession`.
    /// 
    /// - Parameter refreshJwt: the `refreshJwt` from an active `DescopeSession`.
    /// 
    /// - Returns: A `MeResponse` object with the user details.
    func me(refreshJwt: String, completion: @escaping (Result<MeResponse, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await me(refreshJwt: refreshJwt)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Refreshes a session.
    /// 
    /// This can be called at any time as long as the `refreshJwt` is still valid.
    /// Typically called when the `sessionJwt` is expired or about to be.
    /// 
    /// - Parameter refreshJwt: the `refreshJwt` from an active `DescopeSession`.
    /// 
    /// - Returns: A new `DescopeSession` with a refreshed `sessionJwt`.
    func refreshSession(refreshJwt: String, completion: @escaping (Result<DescopeSession, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await refreshSession(refreshJwt: refreshJwt)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Logs out from an active `DescopeSession`.
    /// 
    /// - Parameter refreshJwt: the `refreshJwt` from an active `DescopeSession`.
    func logout(refreshJwt: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await logout(refreshJwt: refreshJwt)))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

public extension DescopeEnchantedLink {
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
    func signUp(loginId: String, user: User, uri: String?, completion: @escaping (Result<EnchantedLinkResponse, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await signUp(loginId: loginId, user: user, uri: uri)))
            } catch {
                completion(.failure(error))
            }
        }
    }

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
    func signIn(loginId: String, uri: String?, completion: @escaping (Result<EnchantedLinkResponse, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await signIn(loginId: loginId, uri: uri)))
            } catch {
                completion(.failure(error))
            }
        }
    }

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
    func signUpOrIn(loginId: String, uri: String?, completion: @escaping (Result<EnchantedLinkResponse, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await signUpOrIn(loginId: loginId, uri: uri)))
            } catch {
                completion(.failure(error))
            }
        }
    }

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
    ///   - refreshJwt: The existing user's `refreshJwt` an active `DescopeSession`.
    /// 
    /// - Returns: An `EnchantedLinkResponse` object with the `linkId` to show the
    ///     user and `pendingRef` for polling for the session.
    func updateEmail(_ email: String, loginId: String, uri: String?, refreshJwt: String, completion: @escaping (Result<EnchantedLinkResponse, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await updateEmail(email, loginId: loginId, uri: uri, refreshJwt: refreshJwt)))
            } catch {
                completion(.failure(error))
            }
        }
    }

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
    func checkForSession(pendingRef: String, completion: @escaping (Result<DescopeSession, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await checkForSession(pendingRef: pendingRef)))
            } catch {
                completion(.failure(error))
            }
        }
    }

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
    func pollForSession(pendingRef: String, timeout: TimeInterval?, completion: @escaping (Result<DescopeSession, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await pollForSession(pendingRef: pendingRef, timeout: timeout)))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

public extension DescopeMagicLink {
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
    func signUp(with method: DeliveryMethod, loginId: String, user: User, uri: String?, completion: @escaping (Result<String, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await signUp(with: method, loginId: loginId, user: user, uri: uri)))
            } catch {
                completion(.failure(error))
            }
        }
    }

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
    func signIn(with method: DeliveryMethod, loginId: String, uri: String?, completion: @escaping (Result<String, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await signIn(with: method, loginId: loginId, uri: uri)))
            } catch {
                completion(.failure(error))
            }
        }
    }

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
    func signUpOrIn(with method: DeliveryMethod, loginId: String, uri: String?, completion: @escaping (Result<String, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await signUpOrIn(with: method, loginId: loginId, uri: uri)))
            } catch {
                completion(.failure(error))
            }
        }
    }

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
    func updateEmail(_ email: String, loginId: String, uri: String?, refreshJwt: String, completion: @escaping (Result<String, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await updateEmail(email, loginId: loginId, uri: uri, refreshJwt: refreshJwt)))
            } catch {
                completion(.failure(error))
            }
        }
    }

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
    func updatePhone(_ phone: String, with method: DeliveryMethod, loginId: String, uri: String?, refreshJwt: String, completion: @escaping (Result<String, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await updatePhone(phone, with: method, loginId: loginId, uri: uri, refreshJwt: refreshJwt)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Verifies a magic link token.
    /// 
    /// In order to effectively do this, the link generated should refer back to
    /// the app, then the `t` URL parameter should be extracted and sent to this
    /// function. Upon successful authentication a `DescopeSession` is returned.
    /// 
    /// - Parameter token: The extracted token from the `t` URL parameter from the magic link.
    /// 
    /// - Returns: Upon successful authentication a `DescopeSession` is returned.
    func verify(token: String, completion: @escaping (Result<DescopeSession, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await verify(token: token)))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

public extension DescopeOAuth {
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
    func start(provider: OAuthProvider, redirectURL: String?, completion: @escaping (Result<String, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await start(provider: provider, redirectURL: redirectURL)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Completes an OAuth redirect chain by exchanging the code received in
    /// the `code` URL parameter for a `DescopeSession`.
    /// 
    /// - Parameter code: The code appended to the returning URL via the
    ///     `code` URL parameter.
    /// 
    /// - Returns: Upon successful exchange a `DescopeSession` is returned.
    func exchange(code: String, completion: @escaping (Result<DescopeSession, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await exchange(code: code)))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

public extension DescopeOTP {
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
    func signUp(with method: DeliveryMethod, loginId: String, user: User, completion: @escaping (Result<String, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await signUp(with: method, loginId: loginId, user: user)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Authenticates an existing user using an OTP, sent via a delivery
    /// method of choice.
    /// 
    /// - Parameters:
    ///   - method: Deliver the OTP code using this delivery method.
    ///   - loginId: What identifies the user when logging in,
    ///     typically an email, phone, or any other unique identifier.
    func signIn(with method: DeliveryMethod, loginId: String, completion: @escaping (Result<String, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await signIn(with: method, loginId: loginId)))
            } catch {
                completion(.failure(error))
            }
        }
    }

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
    func signUpOrIn(with method: DeliveryMethod, loginId: String, completion: @escaping (Result<String, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await signUpOrIn(with: method, loginId: loginId)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Verifies an OTP code sent to the user.
    /// 
    /// - Parameters:
    ///   - method: Which delivery method was used to send the OTP code
    ///   - loginId: The loginId value used to initiate the authentication.
    ///   - code: The code to validate.
    /// 
    /// - Returns: Upon successful authentication a `DescopeSession` is returned.
    func verify(with method: DeliveryMethod, loginId: String, code: String, completion: @escaping (Result<DescopeSession, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await verify(with: method, loginId: loginId, code: code)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Updates an existing user by adding an email address.
    /// 
    /// The email will be updated after it is verified via OTP. In order to do this,
    /// the user must have an active `DescopeSession` whose `refreshJwt` should
    /// be passed as a parameter to this function.
    /// 
    /// - Parameters:
    ///   - email: The email address to add.
    ///   - loginId: The existing user's loginId
    ///   - refreshJwt: The existing user's `refreshJwt` an active `DescopeSession`.
    func updateEmail(_ email: String, loginId: String, refreshJwt: String, completion: @escaping (Result<String, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await updateEmail(email, loginId: loginId, refreshJwt: refreshJwt)))
            } catch {
                completion(.failure(error))
            }
        }
    }

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
    ///   - refreshJwt: The existing user's `refreshJwt` an active `DescopeSession`.
    func updatePhone(_ phone: String, with method: DeliveryMethod, loginId: String, refreshJwt: String, completion: @escaping (Result<String, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await updatePhone(phone, with: method, loginId: loginId, refreshJwt: refreshJwt)))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

public extension DescopePassword {
    /// Creates a new user that can later sign in with a password.
    /// 
    /// - Parameters:
    ///   - loginId: What identifies the user when logging in, typically
    ///     an email, phone, or any other unique identifier.
    ///   - user: Details about the user signing up.
    ///   - password: The user's password.
    /// 
    /// - Returns: Upon successful authentication a `DescopeSession` is returned.
    func signUp(loginId: String, user: User, password: String, completion: @escaping (Result<DescopeSession, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await signUp(loginId: loginId, user: user, password: password)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Authenticates an existing user using a password.
    /// 
    /// - Parameters:
    ///   - loginId: What identifies the user when logging in,
    ///     typically an email, phone, or any other unique identifier.
    ///   - password: The user's password.
    /// 
    /// - Returns: Upon successful authentication a `DescopeSession` is returned.
    func signIn(loginId: String, password: String, completion: @escaping (Result<DescopeSession, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await signIn(loginId: loginId, password: password)))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

public extension DescopeSSO {
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
    func start(emailOrTenantName: String, redirectURL: String?, completion: @escaping (Result<String, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await start(emailOrTenantName: emailOrTenantName, redirectURL: redirectURL)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Completes an SSO redirect chain by exchanging the code received in
    /// the `code` URL parameter for a `DescopeSession`.
    /// 
    /// - Parameter code: The code appended to the returning URL via the
    ///     `code` URL parameter.
    /// 
    /// - Returns: Upon successful exchange a `DescopeSession` is returned.
    func exchange(code: String, completion: @escaping (Result<DescopeSession, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await exchange(code: code)))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

public extension DescopeTOTP {
    /// Authenticates a new user using a TOTP. This function returns the
    /// key (seed) that allows authenticator apps to generate TOTP codes.
    /// 
    /// - Parameters:
    ///   - loginId: What identifies the user when logging in, typically
    ///     an email, phone, or any other unique identifier.
    ///   - user: Details about the user signing up.
    /// 
    /// - Returns: A `TOTPResponse` object with the key (seed) in multiple formats.
    func signUp(loginId: String, user: User, completion: @escaping (Result<TOTPResponse, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await signUp(loginId: loginId, user: user)))
            } catch {
                completion(.failure(error))
            }
        }
    }

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
    ///   - refreshJwt: The existing user's `refreshJwt` an active `DescopeSession`.
    /// 
    /// - Returns: A `TOTPResponse` object with the key (seed) in multiple formats.
    func update(loginId: String, refreshJwt: String, completion: @escaping (Result<TOTPResponse, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await update(loginId: loginId, refreshJwt: refreshJwt)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Verifies a TOTP code that was generated by an authenticator app.
    /// 
    /// - Parameters:
    ///   - loginId: The `loginId` of the user trying to log in.
    ///   - code: The code to validate.
    /// 
    /// - Returns: Upon successful authentication a `DescopeSession` is returned.
    func verify(loginId: String, code: String, completion: @escaping (Result<DescopeSession, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await verify(loginId: loginId, code: code)))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
