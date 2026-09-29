import AppKit
import CoreMediaIO
import CryptoKit
import Foundation

let deviceName = "OBS Virtual Camera"
let obsBundleID = "com.obsproject.obs-studio"
let extensionProcess = "com.obsproject.obs-studio.mac-camera-extension"
let settleDelay: TimeInterval = 4
let pollInterval: TimeInterval = 1
let launchGrace: TimeInterval = 30
let quitCooldown: TimeInterval = 8

func log(_ message: String) {
    FileHandle.standardError.write("\(Date()) \(message)\n".data(using: .utf8)!)
}

enum Camera {
    private static let globalScope = CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal)
    private static let anyScope = CMIOObjectPropertyScope(kCMIOObjectPropertyScopeWildcard)

    static func inUse() -> Bool {
        guard let device = devices().first(where: { name(of: $0) == deviceName }) else { return false }
        var address = address(kCMIODevicePropertyDeviceIsRunningSomewhere, scope: anyScope)
        var value: UInt32 = 0
        var used: UInt32 = 0
        CMIOObjectGetPropertyData(device, &address, 0, nil, UInt32(MemoryLayout<UInt32>.size), &used, &value)
        return value != 0
    }

    private static func devices() -> [CMIOObjectID] {
        var address = address(kCMIOHardwarePropertyDevices, scope: globalScope)
        var size: UInt32 = 0
        CMIOObjectGetPropertyDataSize(CMIOObjectID(kCMIOObjectSystemObject), &address, 0, nil, &size)
        var ids = [CMIOObjectID](repeating: 0, count: Int(size) / MemoryLayout<CMIOObjectID>.size)
        var used: UInt32 = 0
        CMIOObjectGetPropertyData(CMIOObjectID(kCMIOObjectSystemObject), &address, 0, nil, size, &used, &ids)
        return ids
    }

    private static func name(of id: CMIOObjectID) -> String? {
        var address = address(kCMIOObjectPropertyName, scope: globalScope)
        var value: Unmanaged<CFString>?
        var used: UInt32 = 0
        let status = CMIOObjectGetPropertyData(
            id, &address, 0, nil, UInt32(MemoryLayout<Unmanaged<CFString>?>.size), &used, &value)
        guard status == 0, let value else { return nil }
        return value.takeRetainedValue() as String
    }

    private static func address(_ selector: Int, scope: CMIOObjectPropertyScope) -> CMIOObjectPropertyAddress {
        CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(selector),
            mScope: scope,
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain))
    }
}

enum OBSSocket {
    struct Config {
        let port: Int
        let password: String
    }

    static func config() -> Config? {
        let path = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/obs-studio/plugin_config/obs-websocket/config.json")
        guard let data = try? Data(contentsOf: path),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              json["server_enabled"] as? Bool == true else { return nil }
        let password = json["auth_required"] as? Bool == true ? json["server_password"] as? String ?? "" : ""
        return Config(port: json["server_port"] as? Int ?? 4455, password: password)
    }

    static func request(_ type: String) async throws -> [String: Any] {
        guard let config = config() else { throw URLError(.cannotConnectToHost) }
        let task = URLSession.shared.webSocketTask(with: URL(string: "ws://127.0.0.1:\(config.port)")!)
        task.resume()
        defer { task.cancel(with: .normalClosure, reason: nil) }

        let hello = try await receive(task)
        var identify: [String: Any] = ["rpcVersion": 1, "eventSubscriptions": 0]
        if let auth = (hello["d"] as? [String: Any])?["authentication"] as? [String: Any],
           let challenge = auth["challenge"] as? String, let salt = auth["salt"] as? String {
            let secret = sha256Base64(config.password + salt)
            identify["authentication"] = sha256Base64(secret + challenge)
        }
        try await send(task, ["op": 1, "d": identify])
        _ = try await receive(task)
        try await send(task, ["op": 6, "d": ["requestType": type, "requestId": UUID().uuidString]])
        let response = try await receive(task)["d"] as? [String: Any] ?? [:]
        guard (response["requestStatus"] as? [String: Any])?["result"] as? Bool == true else {
            throw URLError(.badServerResponse)
        }
        return response["responseData"] as? [String: Any] ?? [:]
    }

    private static func sha256Base64(_ text: String) -> String {
        Data(SHA256.hash(data: Data(text.utf8))).base64EncodedString()
    }

    private static func send(_ task: URLSessionWebSocketTask, _ message: [String: Any]) async throws {
        let data = try JSONSerialization.data(withJSONObject: message)
        try await task.send(.string(String(decoding: data, as: UTF8.self)))
    }

    private static func receive(_ task: URLSessionWebSocketTask) async throws -> [String: Any] {
        let message = try await task.receive()
        let data: Data
        switch message {
        case .string(let text): data = Data(text.utf8)
        case .data(let raw): data = raw
        @unknown default: data = Data()
        }
        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }
}

@MainActor
final class Controller {
    private var launchedAt: Date?
    private var quitAt: Date?
    private var wasInUse = Camera.inUse()
    private var obsWasRunning = false
    private var closedByHand = false
    private var pendingStop: Task<Void, Never>?

    private var obs: NSRunningApplication? {
        NSRunningApplication.runningApplications(withBundleIdentifier: obsBundleID).first
    }

    func tick() {
        let inUse = Camera.inUse()
        let running = obs != nil
        defer {
            wasInUse = inUse
            obsWasRunning = running
        }
        if running {
            if inUse && !wasInUse && launchedAt == nil { startVirtualCam(retries: 1) }
            return
        }
        if obsWasRunning && quitAt == nil {
            launchedAt = nil
            closedByHand = true
            log("OBS closed by hand, waiting for the camera to be released")
        }
        if closedByHand {
            if !inUse { closedByHand = false }
            return
        }
        if let quitAt {
            guard Date().timeIntervalSince(quitAt) > quitCooldown else { return }
            self.quitAt = nil
        }
        if let launchedAt {
            guard Date().timeIntervalSince(launchedAt) > launchGrace else { return }
            self.launchedAt = nil
            log("OBS did not start")
        }
        if inUse { launch() }
    }

    func consumerStarted() {
        pendingStop?.cancel()
        pendingStop = nil
    }

    func consumerStopped() {
        guard launchedAt != nil else { return }
        pendingStop?.cancel()
        pendingStop = Task {
            try? await Task.sleep(for: .seconds(settleDelay))
            guard !Task.isCancelled else { return }
            await stop()
        }
    }

    private func launch() {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: obsBundleID) else { return }
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = false
        launchedAt = Date()
        log("camera requested, starting OBS")
        NSWorkspace.shared.openApplication(at: url, configuration: configuration) { _, error in
            if let error { log("failed to start OBS: \(error.localizedDescription)") }
        }
        startVirtualCam(retries: Int(launchGrace))
    }

    private func startVirtualCam(retries: Int) {
        Task {
            for _ in 0..<retries {
                if (try? await OBSSocket.request("StartVirtualCam")) != nil { return }
                try? await Task.sleep(for: .seconds(1))
            }
            log("could not start the virtual camera through obs-websocket")
        }
    }

    private func stop() async {
        guard launchedAt != nil, let obs else { return }
        do {
            let record = try await OBSSocket.request("GetRecordStatus")
            let stream = try await OBSSocket.request("GetStreamStatus")
            if record["outputActive"] as? Bool == true || stream["outputActive"] as? Bool == true {
                log("camera released but OBS is recording or streaming, leaving it running")
                launchedAt = nil
                return
            }
            _ = try await OBSSocket.request("StopVirtualCam")
        } catch {
            log("obs-websocket unavailable (\(error.localizedDescription)), leaving OBS running")
            return
        }
        log("camera released, quitting OBS")
        launchedAt = nil
        quitAt = Date()
        obs.terminate()
    }
}

final class LineBuffer: @unchecked Sendable {
    private var pending = ""

    func append(_ data: Data) -> [String] {
        pending += String(decoding: data, as: UTF8.self)
        var lines: [String] = []
        while let newline = pending.firstIndex(of: "\n") {
            lines.append(String(pending[..<newline]))
            pending.removeSubrange(...newline)
        }
        return lines
    }
}

final class ExtensionLog {
    private let process = Process()
    private let pipe = Pipe()

    init(onEvent: @escaping @Sendable (Bool) -> Void) {
        process.executableURL = URL(fileURLWithPath: "/usr/bin/log")
        process.arguments = [
            "stream", "--style", "compact", "--level", "info", "--predicate",
            "process == \"\(extensionProcess)\" AND eventMessage CONTAINS \"Stream Source\" " +
                "AND eventMessage CONTAINS \"streaming client\"",
        ]
        process.standardOutput = pipe
        let buffer = LineBuffer()
        pipe.fileHandleForReading.readabilityHandler = { handle in
            for line in buffer.append(handle.availableData) {
                if line.contains("adding streaming client") { onEvent(true) }
                if line.contains("removing streaming client") { onEvent(false) }
            }
        }
        process.terminationHandler = { _ in exit(1) }
    }

    func start() throws { try process.run() }

    func stop() { process.terminate() }
}

let controller = MainActor.assumeIsolated { Controller() }
let extensionLog = ExtensionLog { started in
    Task { @MainActor in started ? controller.consumerStarted() : controller.consumerStopped() }
}
try extensionLog.start()
signal(SIGTERM, SIG_IGN)
signal(SIGINT, SIG_IGN)
let signalSources = [SIGTERM, SIGINT].map { signalNumber in
    let source = DispatchSource.makeSignalSource(signal: signalNumber, queue: .main)
    source.setEventHandler {
        extensionLog.stop()
        exit(0)
    }
    source.resume()
    return source
}
Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { _ in
    MainActor.assumeIsolated { controller.tick() }
}
log("watching \(deviceName)")
RunLoop.main.run()
