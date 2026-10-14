import SwiftUI

/// tvOS account tab: signed-in profile with sign out, or a prompt to sign
/// in on iPhone (tvOS has no text-field sign-in UI).
struct TVAccountView: View {
    @EnvironmentObject var auth: AuthManager

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if auth.isSignedIn {
                VStack(spacing: 24) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 96))
                        .foregroundColor(.gray)
                    Text(auth.displayName ?? "anon")
                        .font(.title)
                        .bold()
                        .foregroundColor(.white)
                    if let email = auth.email {
                        Text(email)
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                    Button("Sign Out") { auth.signOut() }
                        .buttonStyle(.bordered)
                        .tint(.red)
                }
                .padding(48)
            } else {
                VStack(spacing: 24) {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .font(.system(size: 96))
                        .foregroundColor(.gray)
                    Text("Sign in on your iPhone to access your account")
                        .font(.title2)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                .padding(48)
            }
        }
    }
}
