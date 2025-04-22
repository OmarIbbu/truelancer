import SystemConfiguration
import Foundation

class Reachability {

    static let shared = Reachability()

    private var reachability: SCNetworkReachability?
    private var previousFlags: SCNetworkReachabilityFlags?

    var onStatusChange: ((Bool) -> Void)?

    private init?() {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)

        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return nil
        }

        self.reachability = defaultRouteReachability
    }

    func startMonitoring() {
        guard let reachability = reachability else { return }

        var context = SCNetworkReachabilityContext(
            version: 0,
            info: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        if SCNetworkReachabilitySetCallback(reachability, { (_, flags, info) in
            guard let info = info else { return }
            let instance = Unmanaged<Reachability>.fromOpaque(info).takeUnretainedValue()
            instance.reachabilityChanged(flags)
        }, &context) {
            SCNetworkReachabilitySetDispatchQueue(reachability, DispatchQueue.global(qos: .background))
        }
    }

    func stopMonitoring() {
        if let reachability = reachability {
            SCNetworkReachabilitySetDispatchQueue(reachability, nil)
        }
    }

    private func reachabilityChanged(_ flags: SCNetworkReachabilityFlags) {
        guard previousFlags != flags else { return }
        previousFlags = flags

        let isConnected = flags.contains(.reachable) && !flags.contains(.connectionRequired)

        print("📡 Reachability Changed: \(isConnected ? "Connected" : "Disconnected")")

        onStatusChange?(isConnected)

        NotificationCenter.default.post(name: .NetworkStatusChanged, object: nil, userInfo: ["isConnected": isConnected])
    }
}

extension Notification.Name {
    static let NetworkStatusChanged = Notification.Name("NetworkStatusChanged")
}

