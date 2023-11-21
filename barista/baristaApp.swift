import SwiftUI

func handleEnabled(isEnabled: Bool) {
    if isEnabled {
        print("caffeinate is enabled")
        
        if self.isCaffeinateRunning {
            // If it is currently running, restart with current settings.
            print("caffeinate is already running, restarting")
            
            // TODO: In this case, toggle off enabled for a second...
        } else {
            print("Starting caffeinate")
        }
    } else {
        print("caffeinate is disabled")
        
        if self.isCaffeinateRunning {
            // If it is currently running, stop it
            print("caffeinate is running, stopping")
        }
    }
}

@main
struct baristaApp: App {
    private var state = BaristaState()
    
    init() {
        // TODO: Pull from state
        handleEnabled(isEnabled: self.state.isCaffeinateEnabled)
    }
    
    var body: some Scene {
        MenuBarExtra("Barista", systemImage: "cup.and.saucer.fill") {
            BaristaMenu(state: state)
        }.menuBarExtraStyle(.window)
    }
}

struct BaristaState {
    @State var isCaffeinateEnabled = false
    @State var isCaffeinateRunning = false
    
    // Corresponds to -d
    @State var canDisplaySleep = false
    
    // Corresponds to -i
    @State var canSystemIdleSleep = false
    
    // Corresponds to -m
    @State var canDiskIdleSleep = false
    
    // Corresponds to -s
    @State var canSystemSleepOnAC = false
    
    // Corresponds to -u
    @State var preventSleep = false
    
    // Corresponds to -t
    @State var preventSleepSeconds = 0
    
    // Corresponds to -w
    @State var waitForPids = false
    @State var pids: Array<Int> = []
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
    
    @State var state: BaristaState
    
    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    let vertical_padding = 10.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8){
            Toggle("Prevent Display Sleep", isOn: state.$canDisplaySleep).toggleStyle(MenuToggle()).padding([.top], vertical_padding)
            Toggle("Prevent Idle Sleep", isOn: state.$canSystemIdleSleep).toggleStyle(MenuToggle())
            Toggle("Prevent Disks from Idle Sleep", isOn: state.$canDiskIdleSleep).toggleStyle(MenuToggle())
            Toggle("Keep System Awake on AC", isOn: state.$canSystemSleepOnAC).toggleStyle(MenuToggle())
            Toggle("Automatically Wake Computer", isOn: state.$preventSleep).toggleStyle(MenuToggle())
            
            Divider()
            
            let enableTogglePadding = if state.isCaffeinateRunning {
                0.0
            } else {
                vertical_padding
            }
            
            Toggle("Enable Barista", isOn: state.$isCaffeinateEnabled).toggleStyle(MenuToggle()).fontWeight(.bold).padding([.bottom], enableTogglePadding)
            
            if state.isCaffeinateRunning {
                Text("Barista is running").padding([.bottom], vertical_padding).padding([.horizontal], 10.0)   .frame(maxWidth: .infinity, alignment: .center)
            }
        }.onChange(of: state.$isCaffeinateEnabled, perform: handleEnabled)
    }
}
