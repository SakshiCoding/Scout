import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @Environment(AppState.self) private var appState
    @State private var error: String?
    @State private var confirmationMessage: String?
    @State private var isLoading = false
    @State private var currentNonce: String = ""

    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ZStack {
            Atlas.paper.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 80)

                    // Compass mark
                    ZStack {
                        Circle()
                            .stroke(Atlas.burnt.opacity(0.15), lineWidth: 1.5)
                            .frame(width: 72, height: 72)
                        Circle()
                            .stroke(Atlas.burnt.opacity(0.08), lineWidth: 1)
                            .frame(width: 90, height: 90)
                        Text("S")
                            .font(Atlas.Font.serif(44))
                            .foregroundColor(Atlas.burnt)
                    }

                    Spacer().frame(height: 32)

                    Text("Scout")
                        .font(Atlas.Font.serif(44))
                        .foregroundColor(Atlas.ink)

                    Text("Your shared restaurant atlas")
                        .font(Atlas.Font.sans(15))
                        .foregroundColor(Atlas.ink2)
                        .padding(.top, 8)

                    Spacer().frame(height: 56)

                    VStack(spacing: 12) {
                        // Sign in with Apple
                        SignInWithAppleButton(.signIn) { request in
                            let nonce    = AuthService.randomNonce()
                            currentNonce = nonce
                            request.requestedScopes = [.fullName, .email]
                            request.nonce           = AuthService.sha256(nonce)
                        } onCompletion: { result in
                            handleAppleResult(result)
                        }
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 52)
                        .clipShape(Capsule())
                        .disabled(isLoading)
                        .opacity(isLoading ? 0.5 : 1)

                        // Divider
                        HStack(spacing: 12) {
                            Rectangle()
                                .fill(Atlas.rule)
                                .frame(height: 1)
                            Text("or")
                                .font(Atlas.Font.sans(12))
                                .foregroundColor(Atlas.ink3)
                            Rectangle()
                                .fill(Atlas.rule)
                                .frame(height: 1)
                        }
                        .padding(.vertical, 4)

                        // Email field
                        AtlasTextField(placeholder: "Email", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        // Password field
                        AtlasSecureField(placeholder: "Password", text: $password)

                        // Error
                        if let error {
                            Text(error)
                                .font(Atlas.Font.sans(13))
                                .foregroundColor(Atlas.burnt)
                                .multilineTextAlignment(.center)
                                .padding(.top, 4)
                        }
                        if let confirmationMessage {
                            Text(confirmationMessage)
                                .font(Atlas.Font.sans(13))
                                .foregroundColor(Atlas.statusOpen)
                                .multilineTextAlignment(.center)
                                .padding(.top, 4)
                        }

                        // Primary action button
                        Button {
                            handleEmailAuth()
                        } label: {
                            ZStack {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text(isSignUp ? "Create Account" : "Sign In")
                                        .font(Atlas.Font.sans(15, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Atlas.burnt)
                            .clipShape(Capsule())
                        }
                        .disabled(isLoading || email.isEmpty || password.isEmpty)
                        .opacity((email.isEmpty || password.isEmpty) ? 0.5 : 1)

                        if !isSignUp {
                            Button("Forgot password?") {
                                requestPasswordReset()
                            }
                            .font(Atlas.Font.sans(13, weight: .semibold))
                            .foregroundColor(Atlas.burnt)
                            .disabled(isLoading)
                        }

                        // Toggle sign in / sign up
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isSignUp.toggle()
                                error = nil
                                confirmationMessage = nil
                            }
                        } label: {
                            Text(isSignUp ? "Already have an account? **Sign in**" : "No account? **Create one**")
                                .font(Atlas.Font.sans(13))
                                .foregroundColor(Atlas.ink2)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, Atlas.screenHPad)

                    Spacer().frame(height: 48)
                }
            }
        }
    }

    // MARK: - Email auth

    private func handleEmailAuth() {
        guard !email.isEmpty, !password.isEmpty else { return }
        isLoading = true
        error = nil
        confirmationMessage = nil
        Task {
            do {
                if isSignUp {
                    try await appState.auth.signUpWithEmail(email: email, password: password)
                } else {
                    try await appState.auth.signInWithEmail(email: email, password: password)
                }
                await finishAuth()
            } catch {
                self.error = authErrorMessage(error, isSignUp: isSignUp)
            }
            isLoading = false
        }
    }

    private func requestPasswordReset() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            error = "Enter your email address first."
            confirmationMessage = nil
            return
        }

        isLoading = true
        error = nil
        confirmationMessage = nil
        Task {
            do {
                try await appState.auth.sendPasswordReset(email: trimmedEmail)
                confirmationMessage = "Check your email for a password reset link."
            } catch {
                self.error = "Could not send the reset email. Check the address and try again."
            }
            isLoading = false
        }
    }

    // MARK: - Apple auth

    private func handleAppleResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else { return }
            isLoading = true
            error = nil
            Task {
                do {
                    try await appState.auth.signInWithApple(credential: credential, nonce: currentNonce)
                    await finishAuth()
                } catch {
                    self.error = "Sign in failed. Please try again."
                }
                isLoading = false
            }
        case .failure(let err):
            let nsErr = err as NSError
            if nsErr.domain == ASAuthorizationError.errorDomain,
               nsErr.code   == ASAuthorizationError.canceled.rawValue { return }
            error = "Sign in failed. Please try again."
        }
    }

    private func authErrorMessage(_ error: Error, isSignUp: Bool) -> String {
        let msg = error.localizedDescription.lowercased()
        if msg.contains("password") { return "Password must be at least 6 characters." }
        if msg.contains("already registered") || msg.contains("already exists") || msg.contains("unique") {
            return "An account with this email already exists. Try signing in."
        }
        if msg.contains("invalid email") || msg.contains("valid email") {
            return "Please enter a valid email address."
        }
        if msg.contains("email not confirmed") || msg.contains("confirm") {
            return "Check your email and click the confirmation link first."
        }
        if msg.contains("invalid login") || msg.contains("invalid credentials") {
            return "Incorrect email or password."
        }
        if msg.contains("unexpected") {
            return "We couldn't sign you in. Check your email and password, then try again."
        }
        return isSignUp
            ? "We couldn't create the account. Please try again."
            : "We couldn't sign you in. Check your email and password, then try again."
    }

    private func finishAuth() async {
        appState.isAuthenticated = appState.auth.isAuthenticated
        appState.currentUser     = appState.auth.currentUser
        if appState.isAuthenticated {
            await appState.loadCircles()
            appState.location.startUpdating()
            appState.loadPendingSharedImport()
        }
    }
}

// MARK: - Input components

private struct AtlasTextField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .font(Atlas.Font.sans(15))
            .foregroundColor(Atlas.ink)
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(Atlas.paper2)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Atlas.rule, lineWidth: 1)
            )
    }
}

private struct AtlasSecureField: View {
    let placeholder: String
    @Binding var text: String
    @State private var isRevealed = false

    var body: some View {
        HStack {
            Group {
                if isRevealed {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            .font(Atlas.Font.sans(15))
            .foregroundColor(Atlas.ink)

            Button {
                isRevealed.toggle()
            } label: {
                Image(systemName: isRevealed ? "eye.slash" : "eye")
                    .font(.system(size: 15))
                    .foregroundColor(Atlas.ink3)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(Atlas.paper2)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Atlas.rule, lineWidth: 1)
        )
    }
}

#Preview {
    SignInView()
        .environment(AppState.preview)
}
