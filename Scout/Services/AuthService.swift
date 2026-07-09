import Foundation
import Combine
import Supabase
import AuthenticationServices
import CryptoKit

@MainActor
final class AuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = true

    private var supabase: SupabaseClient { SupabaseService.shared.client }

    init() {
        observeAuthChanges()
    }

    // Restore session from Keychain on launch
    func checkSession() async {
        defer { isLoading = false }
        do {
            let session = try await supabase.auth.session
            currentUser     = session.user
            isAuthenticated = true
        } catch {
            currentUser     = nil
            isAuthenticated = false
        }
    }

    // Called from SignInView after ASAuthorizationController succeeds
    func signInWithApple(credential: ASAuthorizationAppleIDCredential, nonce: String) async throws {
        guard let tokenData = credential.identityToken,
              let idToken   = String(data: tokenData, encoding: .utf8)
        else { throw AuthError.missingToken }

        let session = try await supabase.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )

        // Extract user name from Apple credential (only available on first sign-in)
        let fullName = credential.fullName
        let displayName = [fullName?.givenName, fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")

        let initials = initials(from: fullName) ?? "?"
        try? await SupabaseService.shared.fetchOrCreateProfile(
            userId: session.user.id,
            displayName: displayName.isEmpty ? nil : displayName,
            initials: initials
        )
    }

    func signInWithEmail(email: String, password: String) async throws {
        let session = try await supabase.auth.signIn(email: email, password: password)
        currentUser     = session.user
        isAuthenticated = true
    }

    func signUpWithEmail(email: String, password: String) async throws {
        let response = try await supabase.auth.signUp(email: email, password: password)
        guard let session = response.session else {
            currentUser     = nil
            isAuthenticated = false
            throw AuthError.emailConfirmationRequired
        }
        currentUser     = session.user
        isAuthenticated = true
    }

    func sendPasswordReset(email: String) async throws {
        try await supabase.auth.resetPasswordForEmail(
            email,
            redirectTo: URL(string: "scout://password-reset")
        )
    }

    func handlePasswordRecoveryURL(_ url: URL) async throws {
        let session = try await supabase.auth.session(from: url)
        currentUser = session.user
        isAuthenticated = true
    }

    func updatePassword(_ password: String) async throws {
        currentUser = try await supabase.auth.update(user: UserAttributes(password: password))
        isAuthenticated = true
    }

    func signOut() async throws {
        try await supabase.auth.signOut()
    }

    // MARK: - Nonce helpers

    // Generates a random nonce string (used for Sign in with Apple)
    static func randomNonce(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result  = ""
        var remaining = length
        while remaining > 0 {
            let randoms = (0..<16).map { _ in UInt8.random(in: 0...255) }
            randoms.forEach { random in
                if remaining == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remaining -= 1
                }
            }
        }
        return result
    }

    // SHA-256 hash of the nonce — sent to Apple
    static func sha256(_ input: String) -> String {
        let data   = Data(input.utf8)
        let hashed = SHA256.hash(data: data)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Private

    private func observeAuthChanges() {
        Task {
            for await (event, session) in await supabase.auth.authStateChanges {
                switch event {
                case .signedIn:
                    currentUser     = session?.user
                    isAuthenticated = true
                case .signedOut, .userDeleted:
                    currentUser     = nil
                    isAuthenticated = false
                default:
                    break
                }
            }
        }
    }

    private func initials(from name: PersonNameComponents?) -> String? {
        guard let name else { return nil }
        let parts = [name.givenName, name.familyName].compactMap { $0.flatMap { $0.first.map(String.init) } }
        return parts.isEmpty ? nil : parts.joined().uppercased()
    }

    enum AuthError: LocalizedError {
        case missingToken
        case emailConfirmationRequired

        var errorDescription: String? {
            switch self {
            case .missingToken:
                "Apple identity token was missing."
            case .emailConfirmationRequired:
                "Check your email and click the confirmation link first."
            }
        }
    }
}
