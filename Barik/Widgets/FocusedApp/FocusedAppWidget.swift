import SwiftUI

struct FocusedAppWidget: View {
    @EnvironmentObject var configProvider: ConfigProvider
    var config: ConfigData { configProvider.config }
    
    @StateObject private var focusedAppManager = FocusedAppManager()
    
    // Configuration options
    var showIcon: Bool { config["show-icon"]?.boolValue ?? true }
    var showName: Bool { config["show-name"]?.boolValue ?? true }
    var maxNameLength: Int { config["max-name-length"]?.intValue ?? 30 }
    
    var body: some View {
        HStack(spacing: 8) {
            if showIcon, let icon = focusedAppManager.focusedAppIcon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .shadow(color: .iconShadow, radius: 2)
            }
            
            if showName && !focusedAppManager.focusedAppName.isEmpty {
                Text(truncatedAppName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.foregroundOutside)
                    .shadow(color: .foregroundShadowOutside, radius: 3)
                    .fixedSize(horizontal: true, vertical: false)
                    .transition(.blurReplace)
            }
        }
        .experimentalConfiguration(horizontalPadding: 8, cornerRadius: 8)
        .animation(.smooth(duration: 0.2), value: focusedAppManager.focusedAppName)
    }
    
    private var truncatedAppName: String {
        let name = focusedAppManager.focusedAppName
        if name.count > maxNameLength {
            return String(name.prefix(maxNameLength)) + "..."
        }
        return name
    }
}

struct FocusedAppWidget_Previews: PreviewProvider {
    static var previews: some View {
        FocusedAppWidget()
            .environmentObject(ConfigProvider(config: [:]))
            .frame(width: 200, height: 50)
            .background(.gray.opacity(0.2))
    }
}
