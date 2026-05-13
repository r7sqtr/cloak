import AppKit

final class ClockPanel: NSPanel {
    var onDragEnded: (() -> Void)?

    private var dragStartMouse: NSPoint?
    private var dragStartOrigin: NSPoint?
    private var didMoveDuringDrag = false

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 60),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        self.level = .statusBar
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.ignoresMouseEvents = true
        self.isMovable = false
        self.isMovableByWindowBackground = false
        self.hidesOnDeactivate = false
        self.isReleasedWhenClosed = false
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.animationBehavior = .none
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    override func mouseDown(with event: NSEvent) {
        dragStartMouse = NSEvent.mouseLocation
        dragStartOrigin = self.frame.origin
        didMoveDuringDrag = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = dragStartMouse, let origin = dragStartOrigin else { return }
        let current = NSEvent.mouseLocation
        let dx = current.x - start.x
        let dy = current.y - start.y
        self.setFrameOrigin(NSPoint(x: origin.x + dx, y: origin.y + dy))
        didMoveDuringDrag = true
    }

    override func mouseUp(with event: NSEvent) {
        let moved = didMoveDuringDrag
        dragStartMouse = nil
        dragStartOrigin = nil
        didMoveDuringDrag = false
        if moved {
            onDragEnded?()
        }
    }
}
