import SwiftUI

struct BackgroundView: View {
    @ObservedObject private var systemMenuBarDetector = SystemMenuBarDetector.shared
    @ObservedObject var configManager = ConfigManager.shared

    private func spacer(_ geometry: GeometryProxy) -> some View {
        let theme: ColorScheme? = {
            switch configManager.config.rootToml.theme {
            case "dark": return .dark
            case "light": return .light
            default: return nil
            }
        }()
        
        let height = configManager.config.experimental.background.resolveHeight()
        
        return Color.clear
            .frame(height: height ?? geometry.size.height)
            .preferredColorScheme(theme)
        
    }
    
    var body: some View {
        if configManager.config.experimental.background.displayed {
            GeometryReader { geometry in
                if configManager.config.experimental.background.black {
                    spacer(geometry)
                        .background(.black)
                        .id("black")
                } else {
                    spacer(geometry)
                        .background(configManager.config.experimental.background.blur)
                        .id("blur")
                }
            }
            .opacity(systemMenuBarDetector.isSystemMenuBarVisible ? 0.0 : 1.0)
            .offset(y: systemMenuBarDetector.isSystemMenuBarVisible ? 8 : 0)
            .animation(.easeInOut(duration: 0.2), value: systemMenuBarDetector.isSystemMenuBarVisible)
        }
    }
}
