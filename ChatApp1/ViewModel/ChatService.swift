
//
//  Untitled 2.swift
//  ChatApp1
//
//  Created by Umar Farooq on 21/04/25.
//

import Foundation
import UIKit

class ChatService {
    
    // MARK: - Properties
     var conversations: [Conversation] = []
    private let socketManager: WebSocketManager
    private var activeConversation: Conversation?
    private var reachability: Reachability?
    private var messageQueue: [(Message, Conversation)] = []
    private var isOnline: Bool = true

    // MARK: - Callbacks
    var onConversationsUpdated: (() -> Void)?
    var onNewMessage: ((Message, Conversation) -> Void)?
    var onInternetStatusChanged: ((Bool) -> Void)?
    var currentConversation: Conversation?


    // MARK: - Initializer
    init(socketManager: WebSocketManager) {
        self.socketManager = socketManager
        setupReachability()
        setupSocketCallbacks()
    }

    // MARK: - Reachability Setup
    private func setupReachability() {
        guard let reachability = Reachability.shared else { return }
        self.reachability = reachability

        reachability.onStatusChange = { [weak self] isConnected in
            guard let self = self else { return }
            self.isOnline = isConnected
            isConnected ? self.handleInternetRestored() : self.handleInternetLost()
        }

        reachability.startMonitoring()
    }
    
    func startNewConversation(conversation: Conversation) {
           self.currentConversation = conversation
           
           // Notify observers that the conversation has been updated, or handle it as needed
           onConversationsUpdated?()
       }

    private func handleInternetRestored() {
        do {
            try socketManager.connect()
            retryQueuedMessages()
            onInternetStatusChanged?(true)
        } catch NetworkError.invalidURL {
            print("Failed to connect: Invalid URL.")
        } catch {
            print("Failed to connect: \(error.localizedDescription)")
        }
    }

    private func handleInternetLost() {
        socketManager.disconnect()
        onInternetStatusChanged?(false)
        notifyNoInternetConnection()
    }

    private func notifyNoInternetConnection() {
        guard let topViewController = UIApplication.shared.keyWindow?.rootViewController else { return }
        let alertController = UIAlertController(
            title: "No Internet Connection",
            message: "Please check your network settings.",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        topViewController.present(alertController, animated: true)
    }

    // MARK: - Socket Callbacks
    private func setupSocketCallbacks() {
        socketManager.onMessageReceived = { [weak self] text in
            guard let self = self, let activeConversation = self.activeConversation,
                  let index = self.conversations.firstIndex(where: { $0.id == activeConversation.id }) else { return }

            let message = Message(id: UUID(), text: text, isFromUser: false, timestamp: Date())
            self.appendMessage(message, to: index)
        }
    }

    // MARK: - Message Handling
    func sendMessage(_ text: String, to conversation: Conversation, isRetry: Bool = false) {
        var message = Message(id: UUID(), text: text, isFromUser: true, timestamp: Date(), isSent: isOnline)

        // Make sure you're updating the conversation in the array
           if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
               conversations[index].messages.append(message)
               conversations[index].lastUpdated = Date()
           }

        if !isOnline && !isRetry {
            queueMessage(message, for: conversation)
            return
        }

        socketManager.send(text) { [weak self] success in
            guard let self = self else { return }
            if success {
                message.isSent = true
                self.updateMessageStatus(message, in: conversation)
            } else {
                self.queueMessage(message, for: conversation)
            }
        }
    }

    private func appendMessage(_ message: Message, to index: Int) {
        conversations[index].messages.append(message)
        conversations[index].lastUpdated = Date()

        DispatchQueue.main.async {
            self.onNewMessage?(message, self.conversations[index])
            self.onConversationsUpdated?()
        }
    }

    private func updateMessageStatus(_ message: Message, in conversation: Conversation) {
        guard let index = conversations.firstIndex(of: conversation),
              let messageIndex = conversations[index].messages.firstIndex(where: { $0.id == message.id }) else { return }

        conversations[index].messages[messageIndex].isSent = true
        DispatchQueue.main.async {
            self.onConversationsUpdated?()
        }
    }

    private func queueMessage(_ message: Message, for conversation: Conversation) {
        messageQueue.append((message, conversation))
    }

    func retryQueuedMessages() {
        guard isOnline else { return }
        for (message, conversation) in messageQueue {
            sendMessage(message.text, to: conversation, isRetry: true)
        }
        messageQueue.removeAll()
    }

    // MARK: - Conversation Management
    func createConversation(title: String) -> Conversation {
        let newConversation = Conversation(id: UUID(), title: title, messages: [], lastUpdated: Date())
        conversations.insert(newConversation, at: 0)
        onConversationsUpdated?()
        return newConversation
    }

    func fetchConversations() -> [Conversation] {
        return conversations
    }

    func fetchMessages(for conversation: Conversation) -> [Message] {
        return conversations.first(where: { $0.id == conversation.id })?.messages ?? []
    }

    func setActiveConversation(_ conversation: Conversation) {
        activeConversation = conversation
    }

    func getActiveConversation() -> Conversation? {
        return activeConversation
    }

    // MARK: - Connection Management
    func connect() {
        do {
            try socketManager.connect()
        } catch NetworkError.invalidURL {
            print("Failed to connect: Invalid URL.")
        } catch {
            print("Failed to connect: \(error.localizedDescription)")
        }
    }
}
