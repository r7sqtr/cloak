import SwiftUI

struct ClockView: View {
    @ObservedObject var prefs: Preferences

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            Text(formatted(context.date))
                .font(.system(
                    size: prefs.fontSize,
                    weight: prefs.fontWeight.swiftUI,
                    design: prefs.fontDesign.swiftUI
                ))
                .monospacedDigit()
                .kerning(0.5)
                .foregroundStyle(Color(hexString: prefs.textColorHex))
                .shadow(
                    color: prefs.showShadow ? .black.opacity(0.45) : .clear,
                    radius: prefs.showShadow ? 6 : 0,
                    x: 0,
                    y: prefs.showShadow ? 2 : 0
                )
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(background)
                .fixedSize()
        }
    }

    private var background: some View {
        let shape = RoundedRectangle(cornerRadius: prefs.cornerRadius, style: .continuous)
        return ZStack {
            if prefs.enableBlur {
                shape.fill(.ultraThinMaterial)
            }
            shape.fill(
                Color(hexString: prefs.backgroundColorHex)
                    .opacity(prefs.backgroundOpacity)
            )
            if prefs.backgroundOpacity > 0.05 || prefs.enableBlur {
                shape.strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
            }
        }
    }

    private func formatted(_ date: Date) -> String {
        CachedFormatter.string(date, template: prefs.format.template)
    }
}

private enum CachedFormatter {
    static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    static func string(_ date: Date, template: String) -> String {
        if formatter.dateFormat != template {
            formatter.dateFormat = template
        }
        return formatter.string(from: date)
    }
}
