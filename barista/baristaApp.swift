import SwiftUI

// From https://stackoverflow.com/a/74535684
extension Array: RawRepresentable where Element: Codable {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode([Element].self, from: data)
        else {
            return nil
        }
        self = result
    }
    
    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return result
    }
}

enum RunningState {
    case started, running, stopped
}

func handleEnabled(isEnabled: Bool) {
    if isEnabled {
        
    } else {
        
    }
}

@main
struct baristaApp: App {
    @State var isCaffeinateEnabled = false
    @State var isCaffeinateRunning = RunningState.stopped
    
    @AppStorage("canDisplaySleep")
    var canDisplaySleep = false
    
    @AppStorage("canSystemIdleSleep")
    var canSystemIdleSleep = false
    
    @AppStorage("canDiskIdleSleep")
    var canDiskIdleSleep = false
    
    @AppStorage("canSystemSleepOnAC")
    var canSystemSleepOnAC = false
    
    @AppStorage("preventSleep")
    var preventSleep = false
    
    @AppStorage("preventSleepSeconds")
    var preventSleepSeconds = 5
    
    @AppStorage("waitForPids")
    var waitForPids = false
    
    @AppStorage("pids")
    var pids: Array<Int> = []
    
    var body: some Scene {
        MenuBarExtra("Barista", systemImage: "cup.and.saucer.fill") {
            BaristaMenu(isCaffeinateEnabled: isCaffeinateEnabled, isCaffeinateRunning: isCaffeinateRunning,canDisplaySleep: canDisplaySleep, canSystemIdleSleep: canSystemIdleSleep, canDiskIdleSleep: canDiskIdleSleep, canSystemSleepOnAC: canSystemSleepOnAC, preventSleep: preventSleep, preventSleepSeconds: preventSleepSeconds, waitForPids: waitForPids, pids: pids)
        }.menuBarExtraStyle(.window)
    }
}

struct MenuToggle : ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        return VStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, content: {
            HStack {
                configuration.label.font(.system(size: 12))
                Spacer()
                Toggle(configuration).toggleStyle(.switch).labelsHidden()
            }
        })
        .padding([.horizontal], 10.0)
    }
}

struct BaristaMenu: View {
    // TODO: Maybe support a list of PIDs/process names to automatically turn on?
    // TODO: Enable on start of Barista?
    // TODO: Enable on start of system?
    
    @State var isCaffeinateEnabled: Bool
    @State var isCaffeinateRunning: RunningState
    
    // Corresponds to -d
    @State var canDisplaySleep: Bool
    
    // Corresponds to -i
    @State var canSystemIdleSleep: Bool
    
    // Corresponds to -m
    @State var canDiskIdleSleep: Bool
    
    // Corresponds to -s
    @State var canSystemSleepOnAC: Bool
    
    // Corresponds to -u
    @State var preventSleep: Bool
    
    // Corresponds to -t
    @State var preventSleepSeconds: Int
    
    // Corresponds to -w
    @State var waitForPids: Bool
    @State var pids: Array<Int>
    
    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    let vertical_padding = 10.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8){
            Toggle("Prevent Display Sleep", isOn: $canDisplaySleep).toggleStyle(MenuToggle()).padding([.top], vertical_padding)
            Toggle("Prevent Idle Sleep", isOn: $canSystemIdleSleep).toggleStyle(MenuToggle())
            Toggle("Prevent Disks from Idle Sleep", isOn: $canDiskIdleSleep).toggleStyle(MenuToggle())
            Toggle("Keep System Awake on AC", isOn: $canSystemSleepOnAC).toggleStyle(MenuToggle())
            Toggle("Automatically Wake Computer", isOn: $preventSleep).toggleStyle(MenuToggle())
            
            Divider()
            
            let enableTogglePadding = vertical_padding
            
            Toggle("Enable Barista", isOn: $isCaffeinateEnabled).toggleStyle(MenuToggle()).fontWeight(.bold).padding([.bottom], enableTogglePadding)
        }.onChange(of: isCaffeinateEnabled, perform: handleEnabled)
    }
}
