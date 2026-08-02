import Foundation
import LocalAuthentication
import Observation

/// Reasons an authentication attempt did not succeed.
enum PrivacyLockError: Error {
    case cancelled
    case failed
    case unavailable

    var message: String {
        switch self {
        case .cancelled:
            return "Authentication was cancelled. Your private moments stay locked."
        case .failed:
            return "Authentication did not succeed. Your private moments stay locked."
        case .unavailable:
            return "This device has no passcode or biometrics set up. Add a device passcode in the Settings app to use private moments."
        }
    }
}

/// Owns every LocalAuthentication interaction and the "is the private area
/// currently unlocked" state. Views never talk to `LAContext` directly.
///
/// The unlocked state is intentionally in-memory only: it is cleared whenever
/// the app leaves the foreground, so returning to the app always re-asks.
@MainActor
@Observable
final class PrivacyLockService {
    static let shared = PrivacyLockService()

    /// True only while the user is authenticated for this foreground session.
    private(set) var isUnlocked = false

    /// Set when an attempt fails, so a view can surface it once and clear it.
    var lastErrorMessage: String?

    private init() {}

    // MARK: Capability

    /// The kind of authentication this device will present.
    var biometryType: LABiometryType {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        return context.biometryType
    }

    var biometryLabel: String {
        switch biometryType {
        case .faceID:  return "Face ID"
        case .touchID: return "Touch ID"
        default:       return "Device Passcode"
        }
    }

    var biometryIcon: String {
        switch biometryType {
        case .faceID:  return "faceid"
        case .touchID: return "touchid"
        default:       return "lock.shield"
        }
    }

    /// False when the device has neither biometrics nor a passcode configured.
    var canAuthenticate: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }

    // MARK: Authentication

    /// Runs a single authentication challenge.
    ///
    /// Uses `.deviceOwnerAuthentication`, which presents Face ID or Touch ID
    /// when available and automatically falls back to the device passcode.
    func authenticate(reason: String = "Unlock your private moments") async -> Result<Void, PrivacyLockError> {
        let context = LAContext()
        context.localizedFallbackTitle = "Use Passcode"

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return .failure(.unavailable)
        }

        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
            return success ? .success(()) : .failure(.failed)
        } catch let laError as LAError {
            switch laError.code {
            case .userCancel, .appCancel, .systemCancel:
                return .failure(.cancelled)
            case .passcodeNotSet, .biometryNotAvailable, .biometryNotEnrolled:
                return .failure(.unavailable)
            default:
                return .failure(.failed)
            }
        } catch {
            return .failure(.failed)
        }
    }

    /// Authenticates and, on success, opens the private area for this session.
    @discardableResult
    func unlock(reason: String = "Unlock your private moments") async -> Bool {
        let result = await authenticate(reason: reason)
        switch result {
        case .success:
            isUnlocked = true
            lastErrorMessage = nil
            return true
        case .failure(let error):
            isUnlocked = false
            lastErrorMessage = error.message
            return false
        }
    }

    /// Marks the session as unlocked after a challenge that already succeeded,
    /// so the user is not prompted twice in a row.
    func markUnlockedForCurrentSession() {
        isUnlocked = true
        lastErrorMessage = nil
    }

    /// Closes the private area. Called when the app leaves the foreground.
    func lock() {
        isUnlocked = false
    }
}
