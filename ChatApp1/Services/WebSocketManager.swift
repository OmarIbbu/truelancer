import Foundation

class WebSocketManager {
    // MARK: - Properties
    private var socket: URLSessionWebSocketTask?
    private var isConnected: Bool = false
    var onMessageReceived: ((String) -> Void)?

    // MARK: - Public Methods
    func connect() throws {
        guard let url = ApiEndpoint.baseURL else {
            throw NetworkError.invalidURL
        }

        guard !isConnected else {
            print("WebSocket is already connected.")
            return
        }

        let session = URLSession(configuration: .default)
        socket = session.webSocketTask(with: url)
        socket?.resume()
        isConnected = true

        listenForMessages()
    }

    func send(_ text: String, completion: @escaping (Bool) -> Void) {
        guard isConnected else {
            print("Cannot send message. WebSocket is not connected.")
            completion(false)
            return
        }

        let message = URLSessionWebSocketTask.Message.string(text)
        socket?.send(message) { error in
            if let error = error {
                print("Failed to send message: \(error.localizedDescription)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }

    func disconnect() {
        guard isConnected else {
            print("WebSocket is already disconnected.")
            return
        }

        socket?.cancel(with: .normalClosure, reason: nil)
        isConnected = false
    }

    // MARK: - Private Methods
    private func listenForMessages() {
        socket?.receive { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                print("Failed to receive message: \(error.localizedDescription)")
                self.isConnected = false
            case .success(let message):
                self.handleReceivedMessage(message)
            }

            // Continue listening for messages if still connected
            if self.isConnected {
                self.listenForMessages()
            }
        }
    }

    private func handleReceivedMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            onMessageReceived?(text)
        default:
            print("Unsupported message type received.")
        }
    }
}
