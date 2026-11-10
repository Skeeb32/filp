import Foundation

/// A window-width capability, independent of hypothetical device APIs.
/// Future multi-display scene coordination belongs behind this boundary.
enum WorkspaceLayout {
    static func usesTwoPanes(width: CGFloat) -> Bool { width >= 850 }
}
