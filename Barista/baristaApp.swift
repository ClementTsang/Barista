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

final class CaffeinateController: ObservableObject {
  @Published var isEnabled: Bool {
    didSet {
      if isEnabled {
        start()
      } else {
        stop()
      }
    }
  }

  @Published private(set) var runState = CaffeinateState.stopped

  private var process: Process?

  init() {
    isEnabled = UserDefaults.standard.bool(forKey: "enableOnStartup")

    if isEnabled {
      start()
    }
  }

  private func stop() {
    guard let process else {
      runState = .stopped
      return
    }

    runState = .stopping(process)
    process.terminate()
    process.waitUntilExit()
    self.process = nil
    runState = .stopped
  }

  private func start() {
    guard process == nil else {
      return
    }

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/bash")
    var arguments = ["caffeinate"]
    let defaults = UserDefaults.standard

    if defaults.bool(forKey: "canDisplaySleep") {
      arguments.append("-d")
    }

    if defaults.bool(forKey: "canSystemIdleSleep") {
      arguments.append("-i")
    }

    if defaults.bool(forKey: "canDiskIdleSleep") {
      arguments.append("-m")
    }

    if defaults.bool(forKey: "canSystemSleepOnAC") {
      arguments.append("-s")
    }

    process.arguments = ["-c", arguments.joined(separator: " ")]
    self.process = process
    runState = .starting(process)

    do {
      try process.run()
      runState = .running(process)
    } catch {
      self.process = nil
      runState = .stopped
      isEnabled = false
    }
  }
}

@main
struct BaristaApp: App {
  @StateObject private var caffeinateController = CaffeinateController()

  var body: some Scene {
    MenuBarExtra {
      BaristaMenu(caffeinateController: caffeinateController)
    } label: {
      let icon = caffeinateController.isEnabled ? "cup.and.saucer.fill" : "cup.and.saucer"
      let image = NSImage(systemSymbolName: icon, accessibilityDescription: nil)
      Image(nsImage: image!).bold()
    }.menuBarExtraStyle(.window)
  }

  // TODO: Kill caffeinate on app kill
}

struct MenuToggle: ToggleStyle {
  func makeBody(configuration: Configuration) -> some View {
    return VStack(
      alignment: /*@START_MENU_TOKEN@*/ .center /*@END_MENU_TOKEN@*/,
      content: {
        HStack {
          configuration.label.font(.system(size: 12))
          Spacer()
          Toggle(configuration).toggleStyle(.switch).labelsHidden()
        }
      }
    )
    .padding([.horizontal], 10.0)
  }
}

struct BaristaMenu: View {
  // TODO: Maybe support a list of PIDs/process names to automatically turn on?

  @Environment(\.openURL) private var openURL

  @ObservedObject var caffeinateController: CaffeinateController

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

  @AppStorage("enableOnStartup")
  var enableOnStartup = false

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
    VStack(alignment: .leading, spacing: 8) {
      Toggle("Prevent Display Sleep", isOn: $canDisplaySleep).toggleStyle(MenuToggle()).padding(
        [.top], vertical_padding)
      Toggle("Prevent Idle Sleep", isOn: $canSystemIdleSleep).toggleStyle(MenuToggle())
      Toggle("Prevent Disks from Idle Sleep", isOn: $canDiskIdleSleep).toggleStyle(MenuToggle())
      Toggle("Keep System Awake on AC", isOn: $canSystemSleepOnAC).toggleStyle(MenuToggle())
      Toggle("Enable on Startup", isOn: $enableOnStartup).toggleStyle(MenuToggle())
      // Toggle("Automatically Wake Computer", isOn: $preventSleep).toggleStyle(MenuToggle())
      // Toggle("Disable When Not on AC", isOn: $disableWhenNotOnAC).toggleStyle(MenuToggle())

      Divider()

      let BaristaToggleDescription =
        if caffeinateController.isEnabled {
          switch caffeinateController.runState {
          case .starting(let process):
            "Barista is starting (PID: \(process.processIdentifier))"
          case .running(let process):
            "Barista is running (PID: \(process.processIdentifier))"
          case .stopping(let process):
            "Barista is stopping (PID: \(process.processIdentifier))"
          case .stopped:
            "Barista is off"
          }
        } else {
          "Barista is off"
        }

      VStack(
        alignment: /*@START_MENU_TOKEN@*/ .center /*@END_MENU_TOKEN@*/,
        content: {
          HStack {
            VStack(alignment: .leading) {
              Text("Enable Barista").font(.system(size: 12)).fontWeight(.semibold)
              Text(BaristaToggleDescription).font(.system(size: 10))
            }
            Spacer()
            Toggle("Enable Barista", isOn: $caffeinateController.isEnabled).toggleStyle(.switch)
              .labelsHidden()
          }
        }
      )
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
          caffeinateController.isEnabled = false
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
    }
  }
}
