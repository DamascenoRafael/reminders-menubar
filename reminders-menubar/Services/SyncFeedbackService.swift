import Foundation
import Combine

@MainActor
final class SyncFeedbackService: ObservableObject {
    static let shared = SyncFeedbackService()
    private init() {}

    @Published var toastMessage: String? = nil

    func show(message: String, duration: TimeInterval = 3.0) {
        toastMessage = message
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            self?.toastMessage = nil
        }
    }
}

