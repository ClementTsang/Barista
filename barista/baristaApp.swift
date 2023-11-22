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

enum CaffeinateState: Equatable {
    case starting(Process)
    case running(Process)
    case stopping(Process)
    case stopped
}

@main
struct baristaApp: App {
    var body: some Scene {
        MenuBarExtra("Barista", systemImage: "cup.and.saucer.fill") {
            BaristaMenu()
        }.menuBarExtraStyle(.window)
    }
    
    // TODO: Kill caffeinate on app kill
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
    
    @State var isCaffeinateEnabled = false
    @State var caffeinateRunState = CaffeinateState.stopped
    
    // Corresponds to -d
    @AppStorage("canDisplaySleep")
    var canDisplaySleep = false
    
    // Corresponds to -i
    @AppStorage("canSystemIdleSleep")
    var canSystemIdleSleep = false
    
    // Corresponds to -m
    @AppStorage("canDiskIdleSleep")
    var canDiskIdleSleep = false
    
    // Corresponds to -s
    @AppStorage("canSystemSleepOnAC")
    var canSystemSleepOnAC = false
    
    // Corresponds to -u
    @AppStorage("preventSleep")
    var preventSleep = false
    
    // Corresponds to -t
    @AppStorage("preventSleepSeconds")
    var preventSleepSeconds = 5
    
    // Corresponds to -w
    @AppStorage("waitForPids")
    var waitForPids = false
    
    @AppStorage("pids")
    var pids: Array<Int> = []
    
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
            
            let baristaToggleDescription = if isCaffeinateEnabled {
                switch (caffeinateRunState) {
                case let .starting(process):
                    "Barista is starting (\(process.processIdentifier))"
                case let .running(process):
                    "Barista is running (\(process.processIdentifier))"
                case let .stopping(process):
                    "Barista is stopping (\(process.processIdentifier))"
                case .stopped:
                    "Barista is off"
                }
            } else {
                "Barista is off"
            }
            
            VStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, content: {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Enable Barista").font(.system(size: 12)).fontWeight(.semibold)
                        Text(baristaToggleDescription).font(.system(size: 10))
                    }
                    Spacer()
                    Toggle("Enable Barista", isOn: $isCaffeinateEnabled).toggleStyle(.switch).labelsHidden()
                }
            })
            .padding([.horizontal], 10.0).padding([.bottom], enableTogglePadding)
        }.onChange(of: isCaffeinateEnabled, perform: { isCaffeinateEnabled in
            if isCaffeinateEnabled {
                let process = Process()
                process.executableURL = URL(fileURLWithPath:"/bin/bash")
                var arguments = ["caffeinate"]
                
                if canDisplaySleep {
                    arguments.append("-d")
                }
                
                if canSystemIdleSleep {
                    arguments.append("-i")
                }
                
                if canDiskIdleSleep {
                    arguments.append("-m")
                }
                
                if canSystemSleepOnAC {
                    arguments.append("-s")
                }
                
                let caffeinateCommand = arguments.joined(separator: " ")
                
                process.arguments = ["-c", caffeinateCommand]
                try? process.run()
                
                caffeinateRunState = CaffeinateState.starting(process)
            } else {
                switch(caffeinateRunState) {
                case let .starting(process):
                    caffeinateRunState = CaffeinateState.stopping(process)
                case let .running(process):
                    caffeinateRunState = CaffeinateState.stopping(process)
                case .stopping(_):
                    break
                case .stopped:
                    caffeinateRunState = CaffeinateState.stopped
                }
            }
        }).onChange(of: caffeinateRunState, perform: { state in
            switch (state) {
            case let .starting(process):
                if isCaffeinateEnabled {
                    while !process.isRunning {}
                    caffeinateRunState = CaffeinateState.running(process)
                } else {
                    process.terminate()
                    while process.isRunning {}
                    caffeinateRunState = CaffeinateState.stopped
                }
            case let .running(process):
                if !isCaffeinateEnabled {
                    process.terminate()
                    while process.isRunning {}
                    caffeinateRunState = CaffeinateState.stopped
                }
            case let .stopping(process):
                if isCaffeinateEnabled {
                    // TODO: Restart
                } else {
                    process.terminate()
                    while process.isRunning {}
                    caffeinateRunState = CaffeinateState.stopped
                }
            case .stopped:
                break
            }
        })
    }
}
