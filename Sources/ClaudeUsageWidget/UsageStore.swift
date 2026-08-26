import Foundation
import Combine

final class UsageStore: ObservableObject {
    @Published var snapshot = UsageSnapshot()

    private let parser = UsageParser()
    private let queue = DispatchQueue(label: "com.claudeusagewidget.parser", qos: .utility)
    private var timer: Timer?

    func start(refreshInterval: TimeInterval = 30) {
        refreshNow()
        timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            self?.refreshNow()
        }
    }

    func refreshNow() {
        queue.async { [weak self] in
            guard let self else { return }
            self.parser.refresh()
            let snap = self.parser.snapshot()
            DispatchQueue.main.async {
                self.snapshot = snap
            }
        }
    }
}
