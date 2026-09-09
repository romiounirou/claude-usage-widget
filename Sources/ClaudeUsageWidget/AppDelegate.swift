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
            button.image = StatusBadge.render(topText: "CLAUDE", bottomText: "…", color: .systemGray)
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
        let color: NSColor
        switch lastSnapshot.contextPercent {
        case ..<0.5: color = .systemGreen
        case ..<0.8: color = .systemOrange
        default: color = .systemRed
        }
        button.image = StatusBadge.render(topText: "CLAUDE", bottomText: "\(percent)%", color: color)
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
/// styled after classic menu bar monitor widgets (Stats, iStat Menus, …).
private enum StatusBadge {
    static func render(topText: String, bottomText: String, color: NSColor) -> NSImage {
        let size = NSSize(width: 42, height: 20)
        let image = NSImage(size: size, flipped: false) { rect in
            let path = NSBezierPath(roundedRect: rect, xRadius: 4, yRadius: 4)
            color.setFill()
            path.fill()

            let topAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 7, weight: .semibold),
                .foregroundColor: NSColor.white,
            ]
            let bottomAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 10.5, weight: .bold),
                .foregroundColor: NSColor.white,
            ]

            let top = NSAttributedString(string: topText, attributes: topAttrs)
            let bottom = NSAttributedString(string: bottomText, attributes: bottomAttrs)
            let topSize = top.size()
            let bottomSize = bottom.size()

            let gap: CGFloat = 0
            let totalHeight = topSize.height + bottomSize.height + gap
            let topY = rect.midY + totalHeight / 2 - topSize.height + 2
            let bottomY = topY - bottomSize.height - gap

            top.draw(at: NSPoint(x: rect.midX - topSize.width / 2, y: topY))
            bottom.draw(at: NSPoint(x: rect.midX - bottomSize.width / 2, y: bottomY))

            return true
        }
        image.isTemplate = false
        return image
    }
}
