import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var prefs: Preferences
    @State private var loginAtStartup: Bool = LoginItem.isEnabled
    @State private var loginError: String?
    @State private var selectedScreenID: String = ""

    var body: some View {
        TabView {
            appearanceTab
                .tabItem { Label("外観", systemImage: "paintbrush") }
            layoutTab
                .tabItem { Label("配置・表示", systemImage: "rectangle.3.group") }
            generalTab
                .tabItem { Label("一般", systemImage: "gear") }
        }
        .frame(width: 480, height: 520)
        .padding(20)
        .onAppear {
            if selectedScreenID.isEmpty {
                selectedScreenID = NSScreen.main?.displayID
                    ?? NSScreen.screens.first?.displayID
                    ?? ""
            }
        }
    }

    private var appearanceTab: some View {
        Form {
            Section("フォント") {
                Picker("デザイン", selection: $prefs.fontDesign) {
                    ForEach(FontDesignOption.allCases) { Text($0.label).tag($0) }
                }
                Picker("ウェイト", selection: $prefs.fontWeight) {
                    ForEach(FontWeightOption.allCases) { Text($0.label).tag($0) }
                }
                HStack {
                    Text("サイズ")
                    Slider(value: $prefs.fontSize, in: 16...96, step: 1)
                    Text("\(Int(prefs.fontSize))").monospacedDigit().frame(width: 32, alignment: .trailing)
                }
            }
            Section("文字") {
                ColorPicker("文字色", selection: textColorBinding, supportsOpacity: false)
                Toggle("影を付ける", isOn: $prefs.showShadow)
            }
            Section("背景") {
                ColorPicker("背景色", selection: backgroundColorBinding, supportsOpacity: false)
                HStack {
                    Text("不透明度")
                    Slider(value: $prefs.backgroundOpacity, in: 0...1, step: 0.01)
                    Text(String(format: "%.0f%%", prefs.backgroundOpacity * 100))
                        .monospacedDigit().frame(width: 44, alignment: .trailing)
                }
                Toggle("ぼかし (Blur)", isOn: $prefs.enableBlur)
                HStack {
                    Text("角丸")
                    Slider(value: $prefs.cornerRadius, in: 0...32, step: 1)
                    Text("\(Int(prefs.cornerRadius))").monospacedDigit().frame(width: 32, alignment: .trailing)
                }
            }
        }
        .formStyle(.grouped)
    }

    private var layoutTab: some View {
        Form {
            Section("表示する画面") {
                ForEach(NSScreen.screens, id: \.displayID) { screen in
                    Toggle(screen.localizedName, isOn: visibilityBinding(for: screen))
                }
            }
            Section("配置") {
                Toggle("画面ごとに位置を設定", isOn: $prefs.perScreenEnabled)
                if prefs.perScreenEnabled {
                    Picker("対象スクリーン", selection: $selectedScreenID) {
                        ForEach(NSScreen.screens, id: \.displayID) { screen in
                            Text(screen.localizedName).tag(screen.displayID ?? "")
                        }
                    }
                }
                Picker("横位置", selection: hAlignBinding) {
                    ForEach(HorizontalAlign.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
                Picker("縦位置", selection: vAlignBinding) {
                    ForEach(VerticalAlign.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
                Toggle("オフセットを画面サイズ比 (%) で扱う", isOn: $prefs.useRelativeOffset)
                HStack {
                    Text(prefs.useRelativeOffset ? "横オフセット (%)" : "横オフセット")
                    Slider(value: offsetXBinding, in: offsetRange, step: prefs.useRelativeOffset ? 0.5 : 1)
                    Text(offsetLabel(offsetXBinding.wrappedValue))
                        .monospacedDigit().frame(width: 56, alignment: .trailing)
                }
                HStack {
                    Text(prefs.useRelativeOffset ? "縦オフセット (%)" : "縦オフセット")
                    Slider(value: offsetYBinding, in: offsetRange, step: prefs.useRelativeOffset ? 0.5 : 1)
                    Text(offsetLabel(offsetYBinding.wrappedValue))
                        .monospacedDigit().frame(width: 56, alignment: .trailing)
                }
                Text(offsetHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("ドラッグで移動") {
                Picker("修飾キー", selection: $prefs.dragModifier) {
                    ForEach(DragModifier.allCases) { Text($0.label).tag($0) }
                }
                Text("選択した修飾キーを押しながらクロックをドラッグすると、好きな位置に移動できます。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("時刻フォーマット") {
                Picker("形式", selection: $prefs.format) {
                    ForEach(ClockFormat.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }
        }
        .formStyle(.grouped)
    }

    private var generalTab: some View {
        Form {
            Section("起動") {
                Toggle("ログイン時に Cloak を起動", isOn: $loginAtStartup)
                    .onChange(of: loginAtStartup) { newValue in
                        do {
                            try LoginItem.setEnabled(newValue)
                            loginError = nil
                        } catch {
                            loginAtStartup = LoginItem.isEnabled
                            loginError = error.localizedDescription
                        }
                    }
                if let loginError {
                    Text(loginError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            Section("情報") {
                LabeledContent("Cloak", value: "1.0")
                LabeledContent("Bundle ID", value: "com.vvsaito.Cloak")
            }
        }
        .formStyle(.grouped)
    }

    private func currentPosition() -> ScreenPosition {
        if prefs.perScreenEnabled, !selectedScreenID.isEmpty,
           let pos = prefs.screenPositions[selectedScreenID] {
            return pos
        }
        return ScreenPosition(
            horizontalAlign: prefs.horizontalAlign,
            verticalAlign: prefs.verticalAlign,
            offsetX: prefs.offsetX,
            offsetY: prefs.offsetY
        )
    }

    private func updatePosition(_ transform: (inout ScreenPosition) -> Void) {
        var pos = currentPosition()
        transform(&pos)
        if prefs.perScreenEnabled, !selectedScreenID.isEmpty {
            prefs.screenPositions[selectedScreenID] = pos
        } else {
            prefs.horizontalAlign = pos.horizontalAlign
            prefs.verticalAlign = pos.verticalAlign
            prefs.offsetX = pos.offsetX
            prefs.offsetY = pos.offsetY
        }
    }

    private var hAlignBinding: Binding<HorizontalAlign> {
        Binding(
            get: { currentPosition().horizontalAlign },
            set: { newValue in updatePosition { $0.horizontalAlign = newValue } }
        )
    }

    private var vAlignBinding: Binding<VerticalAlign> {
        Binding(
            get: { currentPosition().verticalAlign },
            set: { newValue in updatePosition { $0.verticalAlign = newValue } }
        )
    }

    private var offsetXBinding: Binding<Double> {
        Binding(
            get: { currentPosition().offsetX },
            set: { newValue in updatePosition { $0.offsetX = newValue } }
        )
    }

    private var offsetYBinding: Binding<Double> {
        Binding(
            get: { currentPosition().offsetY },
            set: { newValue in updatePosition { $0.offsetY = newValue } }
        )
    }

    private var offsetRange: ClosedRange<Double> {
        prefs.useRelativeOffset ? -50...50 : -400...400
    }

    private func offsetLabel(_ value: Double) -> String {
        if prefs.useRelativeOffset {
            return String(format: "%.1f%%", value)
        } else {
            return "\(Int(value))"
        }
    }

    private var offsetHint: String {
        let pos = currentPosition()
        let hx: String
        switch pos.horizontalAlign {
        case .left:   hx = "左端からの距離"
        case .center: hx = "中央からの水平ずれ"
        case .right:  hx = "右端からの距離"
        }
        let vy: String
        switch pos.verticalAlign {
        case .top:    vy = "上端 (メニューバー下) からの距離"
        case .bottom: vy = "下端 (Dock 上) からの距離"
        }
        return "横: \(hx) / 縦: \(vy)"
    }

    private func visibilityBinding(for screen: NSScreen) -> Binding<Bool> {
        Binding(
            get: { prefs.isVisible(on: screen) },
            set: { newValue in
                guard let id = screen.displayID else { return }
                prefs.screenVisibility[id] = newValue
            }
        )
    }

    private var textColorBinding: Binding<Color> {
        Binding(
            get: { Color(hexString: prefs.textColorHex) },
            set: { prefs.textColorHex = $0.toHexString() }
        )
    }

    private var backgroundColorBinding: Binding<Color> {
        Binding(
            get: { Color(hexString: prefs.backgroundColorHex) },
            set: { prefs.backgroundColorHex = $0.toHexString() }
        )
    }
}
