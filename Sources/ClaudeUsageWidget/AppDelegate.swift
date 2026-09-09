import AppKit
import SwiftUI
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private let store = UsageStore()
    private var cancellables: Set<AnyCancellable> = []
    private var lastSnapshot = UsageSnapshot()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            if let image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "Claude Usage") {
                image.isTemplate = true
                button.image = image
            }
            button.title = store.showPercentInMenuBar ? " …" : "" // placeholder until the first scan finishes
            button.imagePosition = .imageLeading
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        popover = NSPopover()
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 300, height: 480)
        popover.contentViewController = NSHostingController(rootView: PopoverView(store: store))

        store.start()

        store.$snapshot
            .sink { [weak self] snapshot in
                self?.lastSnapshot = snapshot
                self?.updateStatusBarTitle()
            }
            .store(in: &cancellables)

        store.$showPercentInMenuBar
            .sink { [weak self] _ in
                self?.updateStatusBarTitle()
            }
            .store(in: &cancellables)
    }

    private func updateStatusBarTitle() {
        guard let button = statusItem.button else { return }
        guard store.showPercentInMenuBar else {
            button.title = ""
            return
        }
        let percent = Int(lastSnapshot.contextPercent * 100)
        button.title = " \(percent)%"
    }

    @objc private func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            store.refreshNow()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
