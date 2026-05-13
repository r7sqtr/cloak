import AppKit
import Combine
import CoreGraphics
import Foundation
import SwiftUI

enum FontDesignOption: String, CaseIterable, Identifiable {
    case `default`
    case rounded
    case monospaced
    case serif

    var id: String { rawValue }

    var label: String {
        switch self {
        case .default: return "System"
        case .rounded: return "Rounded"
        case .monospaced: return "Monospaced"
        case .serif: return "Serif"
        }
    }

    var swiftUI: Font.Design {
        switch self {
        case .default: return .default
        case .rounded: return .rounded
        case .monospaced: return .monospaced
        case .serif: return .serif
        }
    }
}

enum FontWeightOption: String, CaseIterable, Identifiable {
    case regular
    case medium
    case semibold
    case bold

    var id: String { rawValue }

    var label: String { rawValue.capitalized }

    var swiftUI: Font.Weight {
        switch self {
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        }
    }
}

enum ClockFormat: String, CaseIterable, Identifiable {
    case hhmmss24
    case hhmm24
    case hmmssAMPM
    case hmmAMPM

    var id: String { rawValue }

    var label: String {
        switch self {
        case .hhmmss24: return "HH:mm:ss (24h)"
        case .hhmm24:   return "HH:mm (24h)"
        case .hmmssAMPM: return "h:mm:ss a (12h)"
        case .hmmAMPM:   return "h:mm a (12h)"
        }
    }

    var template: String {
        switch self {
        case .hhmmss24: return "HH:mm:ss"
        case .hhmm24:   return "HH:mm"
        case .hmmssAMPM: return "h:mm:ss a"
        case .hmmAMPM:   return "h:mm a"
        }
    }
}

enum HorizontalAlign: String, CaseIterable, Identifiable, Codable {
    case left
    case center
    case right

    var id: String { rawValue }

    var label: String {
        switch self {
        case .left:   return "左"
        case .center: return "中央"
        case .right:  return "右"
        }
    }
}

struct ScreenPosition: Codable, Equatable {
    var horizontalAlign: HorizontalAlign
    var verticalAlign: VerticalAlign
    var offsetX: Double
    var offsetY: Double
}

enum DragModifier: String, CaseIterable, Identifiable {
    case option
    case command
    case control
    case shift

    var id: String { rawValue }

    var label: String {
        switch self {
        case .option:  return "⌥ Option"
        case .command: return "⌘ Command"
        case .control: return "⌃ Control"
        case .shift:   return "⇧ Shift"
        }
    }

    var cgFlag: CGEventFlags {
        switch self {
        case .option:  return .maskAlternate
        case .command: return .maskCommand
        case .control: return .maskControl
        case .shift:   return .maskShift
        }
    }

    var nsFlag: NSEvent.ModifierFlags {
        switch self {
        case .option:  return .option
        case .command: return .command
        case .control: return .control
        case .shift:   return .shift
        }
    }
}

enum VerticalAlign: String, CaseIterable, Identifiable, Codable {
    case top
    case bottom

    var id: String { rawValue }

    var label: String {
        switch self {
        case .top:    return "上"
        case .bottom: return "下"
        }
    }
}

final class Preferences: ObservableObject {
    static let shared = Preferences()

    @Published var fontDesign: FontDesignOption {
        didSet { defaults.set(fontDesign.rawValue, forKey: Keys.fontDesign) }
    }
    @Published var fontWeight: FontWeightOption {
        didSet { defaults.set(fontWeight.rawValue, forKey: Keys.fontWeight) }
    }
    @Published var fontSize: Double {
        didSet { defaults.set(fontSize, forKey: Keys.fontSize) }
    }
    @Published var textColorHex: String {
        didSet { defaults.set(textColorHex, forKey: Keys.textColorHex) }
    }
    @Published var backgroundColorHex: String {
        didSet { defaults.set(backgroundColorHex, forKey: Keys.backgroundColorHex) }
    }
    @Published var backgroundOpacity: Double {
        didSet { defaults.set(backgroundOpacity, forKey: Keys.backgroundOpacity) }
    }
    @Published var enableBlur: Bool {
        didSet { defaults.set(enableBlur, forKey: Keys.enableBlur) }
    }
    @Published var cornerRadius: Double {
        didSet { defaults.set(cornerRadius, forKey: Keys.cornerRadius) }
    }
    @Published var format: ClockFormat {
        didSet { defaults.set(format.rawValue, forKey: Keys.format) }
    }
    @Published var horizontalAlign: HorizontalAlign {
        didSet { defaults.set(horizontalAlign.rawValue, forKey: Keys.horizontalAlign) }
    }
    @Published var verticalAlign: VerticalAlign {
        didSet { defaults.set(verticalAlign.rawValue, forKey: Keys.verticalAlign) }
    }
    @Published var offsetX: Double {
        didSet { defaults.set(offsetX, forKey: Keys.offsetX) }
    }
    @Published var offsetY: Double {
        didSet { defaults.set(offsetY, forKey: Keys.offsetY) }
    }
    @Published var showShadow: Bool {
        didSet { defaults.set(showShadow, forKey: Keys.showShadow) }
    }
    @Published var dragModifier: DragModifier {
        didSet { defaults.set(dragModifier.rawValue, forKey: Keys.dragModifier) }
    }
    @Published var perScreenEnabled: Bool {
        didSet { defaults.set(perScreenEnabled, forKey: Keys.perScreenEnabled) }
    }
    @Published var screenPositions: [String: ScreenPosition] {
        didSet { encodeScreenPositions() }
    }
    @Published var screenVisibility: [String: Bool] {
        didSet { encodeScreenVisibility() }
    }
    @Published var useRelativeOffset: Bool {
        didSet {
            if useRelativeOffset != oldValue {
                convertOffsetUnit(toRelative: useRelativeOffset)
            }
            defaults.set(useRelativeOffset, forKey: Keys.useRelativeOffset)
        }
    }

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let fontDesign = "fontDesign"
        static let fontWeight = "fontWeight"
        static let fontSize = "fontSize"
        static let textColorHex = "textColorHex"
        static let backgroundColorHex = "backgroundColorHex"
        static let backgroundOpacity = "backgroundOpacity"
        static let enableBlur = "enableBlur"
        static let cornerRadius = "cornerRadius"
        static let format = "format"
        static let horizontalAlign = "horizontalAlign"
        static let verticalAlign = "verticalAlign"
        static let offsetX = "offsetX"
        static let offsetY = "offsetY"
        static let showShadow = "showShadow"
        static let dragModifier = "dragModifier"
        static let perScreenEnabled = "perScreenEnabled"
        static let screenPositions = "screenPositions"
        static let screenVisibility = "screenVisibility"
        static let useRelativeOffset = "useRelativeOffset"
    }

    private func convertOffsetUnit(toRelative: Bool) {
        guard let main = NSScreen.main else { return }
        let w = Double(main.visibleFrame.width)
        let h = Double(main.visibleFrame.height)
        guard w > 0, h > 0 else { return }
        if toRelative {
            offsetX = offsetX / w * 100.0
            offsetY = offsetY / h * 100.0
            for (key, var pos) in screenPositions {
                pos.offsetX = pos.offsetX / w * 100.0
                pos.offsetY = pos.offsetY / h * 100.0
                screenPositions[key] = pos
            }
        } else {
            offsetX = offsetX / 100.0 * w
            offsetY = offsetY / 100.0 * h
            for (key, var pos) in screenPositions {
                pos.offsetX = pos.offsetX / 100.0 * w
                pos.offsetY = pos.offsetY / 100.0 * h
                screenPositions[key] = pos
            }
        }
    }

    private func encodeScreenPositions() {
        if let data = try? JSONEncoder().encode(screenPositions) {
            defaults.set(data, forKey: Keys.screenPositions)
        }
    }

    private func encodeScreenVisibility() {
        if let data = try? JSONEncoder().encode(screenVisibility) {
            defaults.set(data, forKey: Keys.screenVisibility)
        }
    }

    private init() {
        let d = UserDefaults.standard

        self.fontDesign = FontDesignOption(rawValue: d.string(forKey: Keys.fontDesign) ?? "") ?? .rounded
        self.fontWeight = FontWeightOption(rawValue: d.string(forKey: Keys.fontWeight) ?? "") ?? .semibold

        let storedSize = d.double(forKey: Keys.fontSize)
        self.fontSize = storedSize > 0 ? storedSize : 32

        self.textColorHex = d.string(forKey: Keys.textColorHex) ?? "#FFFFFF"
        self.backgroundColorHex = d.string(forKey: Keys.backgroundColorHex) ?? "#000000"

        let storedOpacity = d.object(forKey: Keys.backgroundOpacity) as? Double
        self.backgroundOpacity = storedOpacity ?? 0.35

        let storedBlur = d.object(forKey: Keys.enableBlur) as? Bool
        self.enableBlur = storedBlur ?? false

        let storedRadius = d.object(forKey: Keys.cornerRadius) as? Double
        self.cornerRadius = storedRadius ?? 14

        self.format = ClockFormat(rawValue: d.string(forKey: Keys.format) ?? "") ?? .hhmmss24

        self.horizontalAlign = HorizontalAlign(rawValue: d.string(forKey: Keys.horizontalAlign) ?? "") ?? .right
        self.verticalAlign = VerticalAlign(rawValue: d.string(forKey: Keys.verticalAlign) ?? "") ?? .top

        let storedOX = d.object(forKey: Keys.offsetX) as? Double
        self.offsetX = storedOX ?? 16

        let storedOY = d.object(forKey: Keys.offsetY) as? Double
        self.offsetY = storedOY ?? 16

        let storedShadow = d.object(forKey: Keys.showShadow) as? Bool
        self.showShadow = storedShadow ?? true

        self.dragModifier = DragModifier(rawValue: d.string(forKey: Keys.dragModifier) ?? "") ?? .option

        let storedPerScreen = d.object(forKey: Keys.perScreenEnabled) as? Bool
        self.perScreenEnabled = storedPerScreen ?? false

        if let data = d.data(forKey: Keys.screenPositions),
           let decoded = try? JSONDecoder().decode([String: ScreenPosition].self, from: data) {
            self.screenPositions = decoded
        } else {
            self.screenPositions = [:]
        }

        if let data = d.data(forKey: Keys.screenVisibility),
           let decoded = try? JSONDecoder().decode([String: Bool].self, from: data) {
            self.screenVisibility = decoded
        } else {
            self.screenVisibility = [:]
        }

        let storedRelative = d.object(forKey: Keys.useRelativeOffset) as? Bool
        self.useRelativeOffset = storedRelative ?? true
    }

    func isVisible(on screen: NSScreen) -> Bool {
        guard let id = screen.displayID else { return true }
        return screenVisibility[id] ?? true
    }

    func position(for screen: NSScreen) -> ScreenPosition {
        if perScreenEnabled, let id = screen.displayID, let stored = screenPositions[id] {
            return stored
        }
        return ScreenPosition(
            horizontalAlign: horizontalAlign,
            verticalAlign: verticalAlign,
            offsetX: offsetX,
            offsetY: offsetY
        )
    }

    func savePosition(_ position: ScreenPosition, for screen: NSScreen) {
        if perScreenEnabled, let id = screen.displayID {
            screenPositions[id] = position
        } else {
            horizontalAlign = position.horizontalAlign
            verticalAlign = position.verticalAlign
            offsetX = position.offsetX
            offsetY = position.offsetY
        }
    }
}

extension NSScreen {
    var displayID: String? {
        guard let id = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            return nil
        }
        return String(id.uint32Value)
    }
}

extension Color {
    init(hexString: String) {
        let cleaned = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        guard cleaned.count == 6, let value = UInt32(cleaned, radix: 16) else {
            self = .white
            return
        }
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0
        self = Color(red: r, green: g, blue: b)
    }

    func toHexString() -> String {
        let nsColor = NSColor(self).usingColorSpace(.sRGB) ?? .white
        let r = Int(round(nsColor.redComponent * 255))
        let g = Int(round(nsColor.greenComponent * 255))
        let b = Int(round(nsColor.blueComponent * 255))
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
