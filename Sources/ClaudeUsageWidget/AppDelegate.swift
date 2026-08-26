import AppKit
import SwiftUI
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private let store = UsageStore()
    private var cancellable: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            if let image = NSImage(systemSymbolName: "bolt.fill", accessibilityDescription: "Claude Usage") {
                image.isTemplate = true
                button.image = image
            }
            button.title = " …" // guaranteed-visible placeholder until the first scan finishes
            button.imagePosition = .imageLeading
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        popover = NSPopover()
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 300, height: 460)
        popover.contentViewController = NSHostingController(rootView: PopoverView(store: store))

        store.start()

        cancellable = store.$snapshot.sink { [weak self] snapshot in
            self?.updateStatusBarTitle(snapshot: snapshot)
        }
    }

    private func updateStatusBarTitle(snapshot: UsageSnapshot) {
        guard let button = statusItem.button else { return }
        let percent = Int(snapshot.contextPercent * 100)
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
