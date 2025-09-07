
import Foundation
import LocalAuthentication

class AuthenticationService {
    private let context = LAContext()
    private var error: NSError?

    func authenticate(completion: @escaping (Bool) -> Void) {
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            print("Biometrics not available: \(error?.localizedDescription ?? "Unknown error")")
            // Fallback to device passcode can be handled here if desired
            completion(false)
            return
        }

        let reason = "Please authenticate to unlock KharchaMitra."
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
            DispatchQueue.main.async {
                if success {
                    completion(true)
                } else {
                    print("Authentication failed: \(authenticationError?.localizedDescription ?? "Unknown error")")
                    completion(false)
                }
            }
        }
    }
}
