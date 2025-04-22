//
//  Model.swift
//  ChatApp
//
//  Created by Umar Farooq on 21/04/25.
//

// MARK: - Models/Conversation.swift
import Foundation

struct Conversation: Identifiable, Equatable {
    let id: UUID
    var title: String
    var messages: [Message]
    var lastUpdated: Date
    var lastMessage: String? // Add this property

}


// MARK: - Models/Message.swift
import Foundation

struct Message: Equatable {
    let id: UUID
    let text: String
    let isFromUser: Bool
    let timestamp: Date
    var isSent: Bool = true // Default to true for sent messages
}
