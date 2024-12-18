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
struct BaristaApp: App {
    @State var isCaffeinateEnabled = false
    
    var body: some Scene {
        MenuBarExtra() {
            BaristaMenu(isCaffeinateEnabled: $isCaffeinateEnabled)
        } label: {
            let icon = isCaffeinateEnabled ? "cup.and.saucer.fill" : "cup.and.saucer"
            let image = NSImage(systemSymbolName: icon, accessibilityDescription: nil)
            Image(nsImage: image!).bold()
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
    
    @Environment(\.openURL) private var openURL
    
    @Binding var isCaffeinateEnabled: Bool
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
    
    //    // Corresponds to -u
    //    @AppStorage("preventSleep")
    //    var preventSleep = false
    //
    //    // Corresponds to -t
    //    @AppStorage("preventSleepSeconds")
    //    var preventSleepSeconds = 5
    
    //    // Corresponds to -w
    //    @AppStorage("waitForPids")
    //    var waitForPids = false
    //
    //    @AppStorage("pids")
    //    var pids: Array<Int> = []
    
//    @AppStorage("disableWhenNotOnAC")
//    var disableWhenNotOnAC = false
    
    @State private var quitHovered = false
    @State private var githubHovered = false
    @State private var donateHovered = false
    
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
            // Toggle("Automatically Wake Computer", isOn: $preventSleep).toggleStyle(MenuToggle())
            // Toggle("Disable When Not on AC", isOn: $disableWhenNotOnAC).toggleStyle(MenuToggle())
            
            Divider()
            
            let BaristaToggleDescription = if isCaffeinateEnabled {
                switch (caffeinateRunState) {
                case let .starting(process):
                    "Barista is starting (PID: \(process.processIdentifier))"
                case let .running(process):
                    "Barista is running (PID: \(process.processIdentifier))"
                case let .stopping(process):
                    "Barista is stopping (PID: \(process.processIdentifier))"
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
                        Text(BaristaToggleDescription).font(.system(size: 10))
                    }
                    Spacer()
                    Toggle("Enable Barista", isOn: $isCaffeinateEnabled).toggleStyle(.switch).labelsHidden()
                }
            })
            .padding([.horizontal], 10.0)
            
            Divider()
            
            HStack(alignment: .center, spacing: 8.0) {
                Button(action: {
                    openURL(URL(string: "https://github.com/ClementTsang/Barista")!)
                }) {
                    Text("GitHub")
                }.buttonStyle(.borderless)
                    .tint(githubHovered ? .accentColor : .primary)
                    .onHover(perform: { hovering in
                        githubHovered = hovering
                    })
                
                Divider().frame(height: 14)
                
                Button(action: {
                    openURL(URL(string: "https://ko-fi.com/clementtsang")!)
                }) {
                    Text("Donate")
                }.buttonStyle(.borderless)
                    .tint(donateHovered ? .accentColor : .primary)
                    .onHover(perform: { hovering in
                        donateHovered = hovering
                    })
                
                Divider().frame(height: 14)
                
                Button(action: {
                    switch (caffeinateRunState) {
                    case let .starting(process):
                        process.terminate()
                    case let .running(process):
                        process.terminate()
                    case let .stopping(process):
                        process.terminate()
                    case .stopped:
                        break
                    }
                    NSApplication.shared.terminate(nil)
                }) {
                    Text("Quit")
                }
                .buttonStyle(.borderless)
                .tint(quitHovered ? .accentColor : .primary)
                .onHover(perform: { hovering in
                    quitHovered = hovering
                })
            }
            .frame(maxWidth: .infinity)
            .padding([.horizontal], 8.0)
            .padding([.bottom], vertical_padding)
            
            
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
