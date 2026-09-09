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
            button.image = StatusBadge.render(topText: "CLAUDE", bottomText: "…")
            button.imagePosition = .imageOnly
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
                self?.updateStatusBarIcon()
            }
            .store(in: &cancellables)

        store.$showPercentInMenuBar
            .sink { [weak self] _ in
                self?.updateStatusBarIcon()
            }
            .store(in: &cancellables)
    }

    private func updateStatusBarIcon() {
        guard let button = statusItem.button else { return }

        guard store.showPercentInMenuBar else {
            let image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "Claude Usage")
            image?.isTemplate = true
            button.image = image
            button.imagePosition = .imageOnly
            return
        }

        let percent = Int(lastSnapshot.contextPercent * 100)
        button.image = StatusBadge.render(topText: "CLAUDE", bottomText: "\(percent)%")
        button.imagePosition = .imageOnly
    }

    @objc private func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            store.refreshNow()
            // Accessory (menu-bar-only) apps aren't always the "active app" when
            // clicked, and NSPopover can anchor itself incorrectly (falling back
            // to screen center) if the app isn't active yet when show() is called.
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}

/// Renders a compact two-line status-bar badge (label on top, value below),
/// as a template image so it stays monochrome and blends into the menu bar
/// like every other native status item — no colored background pill.
private enum StatusBadge {
    static func render(topText: String, bottomText: String) -> NSImage {
        let size = NSSize(width: 40, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let topAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 7, weight: .medium),
                .foregroundColor: NSColor.black,
            ]
            let bottomAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 10, weight: .semibold),
                .foregroundColor: NSColor.black,
            ]

            let top = NSAttributedString(string: topText, attributes: topAttrs)
            let bottom = NSAttributedString(string: bottomText, attributes: bottomAttrs)
            let topSize = top.size()
            let bottomSize = bottom.size()

            let totalHeight = topSize.height + bottomSize.height
            let topY = rect.midY + totalHeight / 2 - topSize.height + 1
            let bottomY = topY - bottomSize.height

            top.draw(at: NSPoint(x: rect.midX - topSize.width / 2, y: topY))
            bottom.draw(at: NSPoint(x: rect.midX - bottomSize.width / 2, y: bottomY))

            return true
        }
        image.isTemplate = true
        return image
    }
}
