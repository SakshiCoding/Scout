import SwiftUI

struct ResetPasswordView: View {
    @Environment(AppState.self) private var appState

    @State private var password = ""
    @State private var confirmation = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var canSave: Bool {
        password.count >= 6 && password == confirmation && !isSaving
    }

    var body: some View {
        ZStack {
            Atlas.paper.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                Text("Choose a new\npassword")
                    .font(Atlas.Font.serif(40))
                    .foregroundColor(Atlas.ink)

                Text("Use at least six characters.")
                    .font(Atlas.Font.sans(14))
                    .foregroundColor(Atlas.ink2)
                    .padding(.top, 10)

                VStack(spacing: 12) {
                    RecoverySecureField(placeholder: "New password", text: $password)
                    RecoverySecureField(placeholder: "Confirm password", text: $confirmation)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(Atlas.Font.sans(13))
                            .foregroundColor(Atlas.burnt)
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        Task { await save() }
                    } label: {
                        Group {
                            if isSaving {
                                ProgressView().tint(.white)
                            } else {
                                Text("Update password")
                                    .font(Atlas.Font.sans(15, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Atlas.burnt)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSave)
                    .opacity(canSave ? 1 : 0.5)
                }
                .padding(.top, 28)

                Spacer()
            }
            .padding(.horizontal, Atlas.screenHPad)
        }
    }

    private func save() async {
        guard password == confirmation else {
            errorMessage = "Passwords do not match."
            return
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            return
        }

        isSaving = true
        errorMessage = nil
        do {
            try await appState.auth.updatePassword(password)
            await appState.finishPasswordRecovery()
        } catch {
            errorMessage = "Could not update your password. Request a new reset link and try again."
        }
        isSaving = false
    }
}

private struct RecoverySecureField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        SecureField(placeholder, text: $text)
            .font(Atlas.Font.sans(15))
            .foregroundColor(Atlas.ink)
            .textContentType(.newPassword)
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(Atlas.paper2)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Atlas.rule, lineWidth: 1)
            )
    }
}

#Preview {
    ResetPasswordView()
        .environment(AppState.preview)
}
