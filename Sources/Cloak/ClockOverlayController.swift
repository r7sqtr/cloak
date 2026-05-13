import AppKit
import Combine
import CoreGraphics
import SwiftUI

final class ClockOverlayController {
    private var panels: [ClockPanel] = []
    private var hostingViews: [NSHostingView<ClockView>] = []
    private var panelScreens: [NSScreen] = []
    private let prefs: Preferences
    private var cancellables = Set<AnyCancellable>()
    private var modifierTimer: Timer?
    private var flagsGlobalMonitor: Any?
    private var flagsLocalMonitor: Any?
    private var dragModeActive = false
    private var visibleScreenIDs: Set<String> = []

    init(prefs: Preferences) {
        self.prefs = prefs

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        prefs.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                DispatchQueue.main.async { self?.syncToCurrentState() }
            }
            .store(in: &cancellables)

        rebuild()
        startModifierMonitor()
    }

    deinit {
        modifierTimer?.invalidate()
        if let m = flagsGlobalMonitor { NSEvent.removeMonitor(m) }
        if let m = flagsLocalMonitor { NSEvent.removeMonitor(m) }
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func screensChanged() {
        rebuild()
    }

    private func rebuild() {
        for panel in panels {
            panel.orderOut(nil)
        }
        panels.removeAll()
        hostingViews.removeAll()
        panelScreens.removeAll()

        var newIDs: Set<String> = []
        for screen in NSScreen.screens {
            guard prefs.isVisible(on: screen) else { continue }
            let panel = ClockPanel()
            let hosting = NSHostingView(rootView: ClockView(prefs: prefs))
            hosting.translatesAutoresizingMaskIntoConstraints = false
            panel.contentView = hosting
            position(panel, for: screen, hosting: hosting)
            panel.orderFrontRegardless()

            panel.onDragEnded = { [weak self, weak panel] in
                guard let self, let panel else { return }
                self.commitDraggedPosition(of: panel)
            }

            panels.append(panel)
            hostingViews.append(hosting)
            panelScreens.append(screen)
            if let id = screen.displayID {
                newIDs.insert(id)
            }
        }

        visibleScreenIDs = newIDs
        applyDragMode()
    }

    private func currentVisibleIDs() -> Set<String> {
        Set(NSScreen.screens.compactMap { screen in
            prefs.isVisible(on: screen) ? screen.displayID : nil
        })
    }

    private func syncToCurrentState() {
        if currentVisibleIDs() != visibleScreenIDs {
            rebuild()
        } else {
            relayoutAll()
        }
    }

    private func relayoutAll() {
        for (index, panel) in panels.enumerated() where index < panelScreens.count {
            let screen = panelScreens[index]
            let hosting = hostingViews[index]
            position(panel, for: screen, hosting: hosting)
        }
    }

    private func position(_ panel: ClockPanel, for screen: NSScreen, hosting: NSHostingView<ClockView>) {
        hosting.layoutSubtreeIfNeeded()
        let size = hosting.fittingSize
        let visible = screen.visibleFrame
        let p = prefs.position(for: screen)
        let ox: CGFloat
        let oy: CGFloat
        if prefs.useRelativeOffset {
            ox = visible.width * CGFloat(p.offsetX) / 100.0
            oy = visible.height * CGFloat(p.offsetY) / 100.0
        } else {
            ox = CGFloat(p.offsetX)
            oy = CGFloat(p.offsetY)
        }

        let x: CGFloat
        switch p.horizontalAlign {
        case .left:   x = visible.minX + ox
        case .center: x = visible.midX - size.width / 2 + ox
        case .right:  x = visible.maxX - size.width - ox
        }

        let y: CGFloat
        switch p.verticalAlign {
        case .top:    y = visible.maxY - size.height - oy
        case .bottom: y = visible.minY + oy
        }

        let maxX = max(visible.minX, visible.maxX - size.width)
        let maxY = max(visible.minY, visible.maxY - size.height)
        let clampedX = min(max(x, visible.minX), maxX)
        let clampedY = min(max(y, visible.minY), maxY)

        panel.setFrame(
            NSRect(x: clampedX, y: clampedY, width: size.width, height: size.height),
            display: true
        )
    }

    private func startModifierMonitor() {
        syncModifierFromSystem()

        flagsGlobalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.updateDragMode(flags: event.modifierFlags)
        }
        flagsLocalMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.updateDragMode(flags: event.modifierFlags)
            return event
        }

        modifierTimer?.invalidate()
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.syncModifierFromSystem()
        }
        RunLoop.main.add(timer, forMode: .common)
        modifierTimer = timer
    }

    private func updateDragMode(flags: NSEvent.ModifierFlags) {
        let held = flags.contains(prefs.dragModifier.nsFlag)
        if held != dragModeActive {
            dragModeActive = held
            applyDragMode()
        }
    }

    private func syncModifierFromSystem() {
        let flags = CGEventSource.flagsState(.combinedSessionState)
        let held = flags.contains(prefs.dragModifier.cgFlag)
        if held != dragModeActive {
            dragModeActive = held
            applyDragMode()
        }
    }

    private func applyDragMode() {
        for panel in panels {
            panel.ignoresMouseEvents = !dragModeActive
            panel.hasShadow = dragModeActive
        }
    }

    private func commitDraggedPosition(of panel: ClockPanel) {
        guard let screen = panel.screen ?? NSScreen.main else { return }
        let visible = screen.visibleFrame
        let size = panel.frame.size

        let maxFX = max(visible.minX, visible.maxX - size.width)
        let maxFY = max(visible.minY, visible.maxY - size.height)
        let cx = min(max(panel.frame.minX, visible.minX), maxFX)
        let cy = min(max(panel.frame.minY, visible.minY), maxFY)
        let frame = NSRect(x: cx, y: cy, width: size.width, height: size.height)

        let current = prefs.position(for: screen)

        let x: Double
        switch current.horizontalAlign {
        case .left:   x = Double(frame.minX - visible.minX)
        case .center: x = Double(frame.midX - visible.midX)
        case .right:  x = Double(visible.maxX - frame.maxX)
        }

        let y: Double
        switch current.verticalAlign {
        case .top:    y = Double(visible.maxY - frame.maxY)
        case .bottom: y = Double(frame.minY - visible.minY)
        }

        let finalX: Double
        let finalY: Double
        if prefs.useRelativeOffset, visible.width > 0, visible.height > 0 {
            finalX = x / Double(visible.width) * 100.0
            finalY = y / Double(visible.height) * 100.0
        } else {
            finalX = x
            finalY = y
        }

        let updated = ScreenPosition(
            horizontalAlign: current.horizontalAlign,
            verticalAlign: current.verticalAlign,
            offsetX: finalX,
            offsetY: finalY
        )
        prefs.savePosition(updated, for: screen)
    }
}
