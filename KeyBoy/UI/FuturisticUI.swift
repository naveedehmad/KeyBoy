import SwiftUI
import AppKit

// MARK: - Glass Morphism Effects
struct GlassPanel: ViewModifier {
    let cornerRadius: CGFloat
    let opacity: Double
    let blur: CGFloat
    
    init(cornerRadius: CGFloat = 16, opacity: Double = 0.2, blur: CGFloat = 20) {
        self.cornerRadius = cornerRadius
        self.opacity = opacity
        self.blur = blur
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.white.opacity(opacity))
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

struct NeonGlow: ViewModifier {
    let color: Color
    let radius: CGFloat
    let intensity: Double
    
    init(color: Color = Color.cyan, radius: CGFloat = 4, intensity: Double = 0.8) {
        self.color = color
        self.radius = radius
        self.intensity = intensity
    }
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(intensity), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(intensity * 0.6), radius: radius * 2, x: 0, y: 0)
            .shadow(color: color.opacity(intensity * 0.3), radius: radius * 3, x: 0, y: 0)
    }
}

struct AnimatedGradient: View {
    @State private var animateGradient = false
    
    let colors: [Color]
    let speed: Double
    
    init(colors: [Color] = [Color.blue.opacity(0.3), Color.purple.opacity(0.3), Color.cyan.opacity(0.3)], speed: Double = 3.0) {
        self.colors = colors
        self.speed = speed
    }
    
    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: animateGradient ? .topLeading : .bottomTrailing,
            endPoint: animateGradient ? .bottomTrailing : .topLeading
        )
        .onAppear {
            withAnimation(.easeInOut(duration: speed).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

// MARK: - Extension for easy use
extension View {
    func glassPanel(cornerRadius: CGFloat = 16, opacity: Double = 0.2, blur: CGFloat = 20) -> some View {
        modifier(GlassPanel(cornerRadius: cornerRadius, opacity: opacity, blur: blur))
    }
    
    func neonGlow(color: Color = Color.cyan, radius: CGFloat = 4, intensity: Double = 0.8) -> some View {
        modifier(NeonGlow(color: color, radius: radius, intensity: intensity))
    }
}

// MARK: - Neon Button
struct NeonButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var isHovered = false
    
    let style: NeonButtonStyle
    
    init(_ title: String, icon: String? = nil, style: NeonButtonStyle = .primary, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
        self.style = style
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                action()
            }
        }) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                }
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(style.textColor)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(style.backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(style.borderColor, lineWidth: 1.5)
                    )
            )
            .scaleEffect(isPressed ? 0.95 : (isHovered ? 1.05 : 1.0))
            .neonGlow(color: style.glowColor, radius: isHovered ? 8 : 4, intensity: isHovered ? 1.0 : 0.6)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

enum NeonButtonStyle {
    case primary
    case secondary
    case danger
    case success
    
    var backgroundColor: Color {
        switch self {
        case .primary:
            return Color.cyan.opacity(0.2)
        case .secondary:
            return Color.gray.opacity(0.2)
        case .danger:
            return Color.red.opacity(0.2)
        case .success:
            return Color.green.opacity(0.2)
        }
    }
    
    var textColor: Color {
        switch self {
        case .primary:
            return Color.cyan
        case .secondary:
            return Color.white
        case .danger:
            return Color.red
        case .success:
            return Color.green
        }
    }
    
    var borderColor: Color {
        switch self {
        case .primary:
            return Color.cyan.opacity(0.6)
        case .secondary:
            return Color.gray.opacity(0.6)
        case .danger:
            return Color.red.opacity(0.6)
        case .success:
            return Color.green.opacity(0.6)
        }
    }
    
    var glowColor: Color {
        switch self {
        case .primary:
            return Color.cyan
        case .secondary:
            return Color.white
        case .danger:
            return Color.red
        case .success:
            return Color.green
        }
    }
}

// MARK: - Shortcut Item Data Model
struct ShortcutItem {
    let key: String
    let appName: String
    let appPath: String
    let appIcon: NSImage?
    
    init(key: String, appPath: String) {
        self.key = key
        self.appPath = appPath
        
        if let appInfo = AppIconExtractor.extractAppInfo(from: appPath) {
            self.appName = appInfo.name
            self.appIcon = appInfo.icon
        } else {
            self.appName = URL(fileURLWithPath: appPath).deletingPathExtension().lastPathComponent
            self.appIcon = nil
        }
    }
}

// MARK: - Shortcut Card
struct ShortcutCard: View {
    let shortcut: ShortcutItem
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    @State private var rotation: Double = 0
    
    var body: some View {
        VStack(spacing: 12) {
            // App Icon
            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(0.1))
                    .frame(width: 52, height: 52)
                
                if let icon = shortcut.appIcon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 36, height: 36)
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                } else {
                    Image(systemName: "app")
                        .font(.system(size: 20))
                        .foregroundColor(.cyan)
                }
            }
            .overlay(
                // Key Badge
                Text(shortcut.key.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.cyan)
                            .neonGlow(color: .cyan, radius: 2)
                    )
                    .offset(x: 18, y: -18)
            )
            
            // App Name
            VStack(spacing: 2) {
                Text(shortcut.appName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text("⌘ + \(shortcut.key.uppercased())")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .frame(width: 110, height: 128)
        .glassPanel(cornerRadius: 16)
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .rotationEffect(.degrees(rotation))
        .overlay(
            // Hover Actions
            HStack(spacing: 8) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 12))
                        .foregroundColor(.cyan)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(.ultraThinMaterial))
                        .neonGlow(color: .cyan, radius: 2)
                }
                .buttonStyle(.plain)
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(.ultraThinMaterial))
                        .neonGlow(color: .red, radius: 2)
                }
                .buttonStyle(.plain)
            }
            .opacity(isHovered ? 1.0 : 0.0)
            .offset(y: -45)
        )
        .onHover { hovering in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isHovered = hovering
                rotation = hovering ? Double.random(in: -3...3) : 0
            }
        }
        .onTapGesture(count: 2) {
            onEdit()
        }
    }
}

// MARK: - Simple Futuristic Config Editor View
struct FuturisticConfigEditorView: View {
    @State private var shortcuts: [String: String] = [:]
    @State private var animateHeader = false
    @State private var showingAddShortcut = false
    @State private var showingEditShortcut = false
    @State private var editingKey = ""
    @State private var editingAppPath = ""
    @State private var selectedKey = ""
    
    private let configurationManager: ConfigurationManager
    private let onClose: () -> Void
    
    init(configurationManager: ConfigurationManager, onClose: @escaping () -> Void) {
        self.configurationManager = configurationManager
        self.onClose = onClose
    }
    
    var body: some View {
        ZStack {
            // Animated Background
            AnimatedGradient(colors: [
                Color.black.opacity(0.9),
                Color.blue.opacity(0.1),
                Color.purple.opacity(0.1),
                Color.cyan.opacity(0.1)
            ])
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                headerView
                
                shortcutsGridView
                
                Spacer(minLength: 16)
                
                quickActionsBar
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
        }
        .frame(width: 800, height: 680)
        .onAppear {
            loadConfiguration()
            startHeaderAnimation()
        }
        .sheet(isPresented: $showingAddShortcut) {
            AddShortcutDialog(
                existingKeys: Set(shortcuts.keys),
                onSave: { key, appPath in
                    addNewShortcut(key: key, appPath: appPath)
                }
            )
        }
        .sheet(isPresented: $showingEditShortcut) {
            EditShortcutDialog(
                key: selectedKey,
                currentAppPath: editingAppPath,
                onSave: { appPath in
                    updateShortcut(key: selectedKey, appPath: appPath)
                }
            )
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Animated KeyBoy Icon
                ZStack {
                    Circle()
                        .fill(Color.cyan.opacity(0.2))
                        .frame(width: 48, height: 48)
                        .neonGlow(color: .cyan)
                    
                    Text("⌨️")
                        .font(.system(size: 22))
                        .scaleEffect(animateHeader ? 1.2 : 1.0)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("KeyBoy")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .neonGlow(color: .cyan, radius: 2)
                    
                    Text("Supercharge your workflow with intelligent shortcuts")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Close Button
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(Color.red.opacity(0.2))
                        )
                        .neonGlow(color: .red, radius: 2)
                }
                .buttonStyle(.plain)
            }
            
            // Statistics Bar
            HStack(spacing: 32) {
                StatisticItem(title: "Active Shortcuts", value: "\(shortcuts.count)")
                StatisticItem(title: "Keystrokes Saved", value: "2.4K")
                StatisticItem(title: "Time Saved Today", value: "12m")
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .glassPanel(cornerRadius: 12, opacity: 0.1)
            .padding(.horizontal, 20)
        }
    }
    
    private var shortcutsGridView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Shortcuts")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Add Shortcut Button
                Button(action: {
                    showingAddShortcut = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .bold))
                        Text("Add")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.cyan.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.cyan.opacity(0.6), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
                .neonGlow(color: .cyan, radius: 2, intensity: 0.6)
                
                Text("\(shortcuts.count) of 26")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.1))
                    )
            }
            
            if shortcuts.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 4), spacing: 20) {
                        ForEach(shortcuts.keys.sorted(), id: \.self) { key in
                            if let appPath = shortcuts[key] {
                                ShortcutCard(
                                    shortcut: ShortcutItem(key: key, appPath: appPath),
                                    onEdit: {
                                        editShortcut(key: key)
                                    },
                                    onDelete: {
                                        deleteShortcut(key: key)
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .frame(maxHeight: 280)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .glassPanel(cornerRadius: 16, opacity: 0.1)
        .padding(.horizontal, 20)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "keyboard")
                .font(.system(size: 48))
                .foregroundColor(.cyan.opacity(0.6))
                .neonGlow(color: .cyan, radius: 4)
            
            VStack(spacing: 8) {
                Text("No shortcuts configured yet")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Use the original config editor to add shortcuts")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .padding(30)
        .frame(height: 200)
    }
    
    private var quickActionsBar: some View {
        HStack(spacing: 12) {
            NeonButton("Import Config", icon: "square.and.arrow.down", style: .secondary) {
                // TODO: Implement
            }
            
            NeonButton("Export Config", icon: "square.and.arrow.up", style: .secondary) {
                // TODO: Implement  
            }
            
            Spacer()
            
            NeonButton("Save & Close", icon: "checkmark", style: .success) {
                saveAndClose()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassPanel(cornerRadius: 12, opacity: 0.1)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    // MARK: - Helper Views
    
    private struct StatisticItem: View {
        let title: String
        let value: String
        
        var body: some View {
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyan)
                    .neonGlow(color: .cyan, radius: 1)
                
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Functions
    
    private func loadConfiguration() {
        shortcuts = configurationManager.configuration.shortcuts
    }
    
    private func startHeaderAnimation() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            animateHeader = true
        }
    }
    
    private func editShortcut(key: String) {
        selectedKey = key
        editingAppPath = shortcuts[key] ?? ""
        showingEditShortcut = true
    }
    
    private func deleteShortcut(key: String) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            shortcuts.removeValue(forKey: key)
            saveConfiguration()
        }
    }
    
    private func saveConfiguration() {
        let newConfiguration = KeyBoyConfiguration(shortcuts: shortcuts)
        configurationManager.saveConfiguration(newConfiguration)
    }
    
    private func saveAndClose() {
        saveConfiguration()
        onClose()
    }
    
    private func addNewShortcut(key: String, appPath: String) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            shortcuts[key] = appPath
            saveConfiguration()
        }
    }
    
    private func updateShortcut(key: String, appPath: String) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            shortcuts[key] = appPath
            saveConfiguration()
        }
    }
}

// MARK: - Dialog Components

struct AddShortcutDialog: View {
    let existingKeys: Set<String>
    let onSave: (String, String) -> Void
    
    @State private var selectedKey = ""
    @State private var appPath = ""
    @State private var showingFilePicker = false
    @Environment(\.dismiss) private var dismiss
    
    private let availableKeys = Array("abcdefghijklmnopqrstuvwxyz")
    
    var availableKeysFiltered: [String] {
        availableKeys.map { String($0) }.filter { !existingKeys.contains($0) }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Add New Shortcut")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Key")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Menu {
                        ForEach(availableKeysFiltered, id: \.self) { key in
                            Button(key.uppercased()) {
                                selectedKey = key
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedKey.isEmpty ? "Select key..." : "⌘ + \(selectedKey.uppercased())")
                                .foregroundColor(selectedKey.isEmpty ? .secondary : .white)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.1))
                        )
                    }
                    .buttonStyle(.plain)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Application")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    HStack {
                        TextField("App path", text: $appPath)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.1))
                            )
                            .foregroundColor(.white)
                        
                        Button("Browse") {
                            showingFilePicker = true
                        }
                        .buttonStyle(.plain)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.cyan.opacity(0.2))
                        )
                        .foregroundColor(.cyan)
                    }
                }
            }
            
            HStack(spacing: 16) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                )
                .foregroundColor(.white)
                
                Button("Add Shortcut") {
                    if !selectedKey.isEmpty && !appPath.isEmpty {
                        onSave(selectedKey, appPath)
                        dismiss()
                    }
                }
                .buttonStyle(.plain)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.cyan.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.cyan, lineWidth: 1)
                        )
                )
                .foregroundColor(.cyan)
                .disabled(selectedKey.isEmpty || appPath.isEmpty)
            }
        }
        .padding(32)
        .frame(width: 400)
        .background(Color.black.opacity(0.9))
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.application],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    appPath = url.path
                }
            case .failure(let error):
                print("File picker error: \(error)")
            }
        }
    }
}

struct EditShortcutDialog: View {
    let key: String
    let currentAppPath: String
    let onSave: (String) -> Void
    
    @State private var appPath = ""
    @State private var showingFilePicker = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Edit Shortcut")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Key")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("⌘ + \(key.uppercased())")
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.05))
                        )
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Application")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    HStack {
                        TextField("App path", text: $appPath)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.1))
                            )
                            .foregroundColor(.white)
                        
                        Button("Browse") {
                            showingFilePicker = true
                        }
                        .buttonStyle(.plain)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.cyan.opacity(0.2))
                        )
                        .foregroundColor(.cyan)
                    }
                }
            }
            
            HStack(spacing: 16) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                )
                .foregroundColor(.white)
                
                Button("Save Changes") {
                    if !appPath.isEmpty {
                        onSave(appPath)
                        dismiss()
                    }
                }
                .buttonStyle(.plain)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.cyan.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.cyan, lineWidth: 1)
                        )
                )
                .foregroundColor(.cyan)
                .disabled(appPath.isEmpty)
            }
        }
        .padding(32)
        .frame(width: 400)
        .background(Color.black.opacity(0.9))
        .onAppear {
            appPath = currentAppPath
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.application],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    appPath = url.path
                }
            case .failure(let error):
                print("File picker error: \(error)")
            }
        }
    }
}