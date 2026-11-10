import SwiftUI
import SwiftData

@main struct FLIPApp: App {
    private let result: Result<ModelContainer, Error> = Result {
        try ModelContainer(for: LifeItem.self, FocusSession.self)
    }
    var body: some Scene {
        WindowGroup {
            switch result {
            case .success(let container): RootView().modelContainer(container).preferredColorScheme(.dark).tint(Palette.purple)
            case .failure(let error): ContentUnavailableView("Your data couldn’t be opened", systemImage: "externaldrive.badge.exclamationmark", description: Text("FLIP has not erased your data. Restart the app or check available storage. \(error.localizedDescription)"))
            }
        }
    }
}
