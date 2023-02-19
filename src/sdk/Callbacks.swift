// Generated using Sourcery 2.0.1 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// Regenerate by running:
//     brew install sourcery
//     sourcery --sources src/sdk/Routes.swift --templates src/sdk/Callbacks.stencil --output src/sdk/Callbacks.swift

// Convenience functions for working with completion handlers.

public extension DescopeAccessKey {
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
    func me(refreshJwt: String, completion: @escaping (Result<MeResponse, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await me(refreshJwt: refreshJwt)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func refreshSession(refreshJwt: String, completion: @escaping (Result<DescopeSession, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await refreshSession(refreshJwt: refreshJwt)))
            } catch {
                completion(.failure(error))
            }
        }
    }

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
    func signUp(loginId: String, user: User, uri: String?, completion: @escaping (Result<DescopeSession, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await signUp(loginId: loginId, user: user, uri: uri)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func signIn(loginId: String, uri: String?, completion: @escaping (Result<DescopeSession, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await signIn(loginId: loginId, uri: uri)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func signUpOrIn(loginId: String, uri: String?, completion: @escaping (Result<DescopeSession, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await signUpOrIn(loginId: loginId, uri: uri)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func updateEmail(_ email: String, loginId: String, uri: String?, refreshJwt: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await updateEmail(email, loginId: loginId, uri: uri, refreshJwt: refreshJwt)))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

public extension DescopeMagicLink {
    func signUp(with method: DeliveryMethod, loginId: String, user: User, uri: String?, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await signUp(with: method, loginId: loginId, user: user, uri: uri)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func signIn(with method: DeliveryMethod, loginId: String, uri: String?, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await signIn(with: method, loginId: loginId, uri: uri)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func signUpOrIn(with method: DeliveryMethod, loginId: String, uri: String?, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await signUpOrIn(with: method, loginId: loginId, uri: uri)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func updateEmail(_ email: String, loginId: String, uri: String?, refreshJwt: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await updateEmail(email, loginId: loginId, uri: uri, refreshJwt: refreshJwt)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func updatePhone(_ phone: String, with method: DeliveryMethod, loginId: String, uri: String?, refreshJwt: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await updatePhone(phone, with: method, loginId: loginId, uri: uri, refreshJwt: refreshJwt)))
            } catch {
                completion(.failure(error))
            }
        }
    }

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
    func start(provider: OAuthProvider, redirectURL: String?, completion: @escaping (Result<String, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await start(provider: provider, redirectURL: redirectURL)))
            } catch {
                completion(.failure(error))
            }
        }
    }

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
    func signUp(with method: DeliveryMethod, loginId: String, user: User, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await signUp(with: method, loginId: loginId, user: user)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func signIn(with method: DeliveryMethod, loginId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await signIn(with: method, loginId: loginId)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func signUpOrIn(with method: DeliveryMethod, loginId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await signUpOrIn(with: method, loginId: loginId)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func verify(with method: DeliveryMethod, loginId: String, code: String, completion: @escaping (Result<DescopeSession, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await verify(with: method, loginId: loginId, code: code)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func updateEmail(_ email: String, loginId: String, refreshJwt: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await updateEmail(email, loginId: loginId, refreshJwt: refreshJwt)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func updatePhone(_ phone: String, with method: DeliveryMethod, loginId: String, refreshJwt: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await updatePhone(phone, with: method, loginId: loginId, refreshJwt: refreshJwt)))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

public extension DescopeSSO {
    func start(emailOrTenantName: String, redirectURL: String?, completion: @escaping (Result<String, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await start(emailOrTenantName: emailOrTenantName, redirectURL: redirectURL)))
            } catch {
                completion(.failure(error))
            }
        }
    }

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
    func signUp(loginId: String, user: User, completion: @escaping (Result<TOTPResponse, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await signUp(loginId: loginId, user: user)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func update(loginId: String, refreshJwt: String, completion: @escaping (Result<TOTPResponse, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await update(loginId: loginId, refreshJwt: refreshJwt)))
            } catch {
                completion(.failure(error))
            }
        }
    }

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
