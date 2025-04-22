//
//  Untitled 2.swift
//  ChatApp1
//
//  Created by Umar Farooq on 21/04/25.
//

import UIKit

class MainViewControllerTableHandler: NSObject, UITableViewDataSource, UITableViewDelegate {

    private var conversations: [Conversation] = []
    private var messages: [Message] = []
    private var onConversationSelected: ((Conversation) -> Void)?
    private var currentConversation: Conversation? // Add this property


    init(conversations: [Conversation], messages: [Message], onConversationSelected: @escaping (Conversation) -> Void) {
        self.conversations = conversations
        self.messages = messages
        self.onConversationSelected = onConversationSelected
    }

    func updateConversations(_ conversations: [Conversation]) {
        self.conversations = conversations

    }
    
    
    // Method to update the current conversation
       func updateCurrentConversation(_ conversation: Conversation?) {
           self.currentConversation = conversation
       }

       // Method to update messages for the current conversation
       func updateMessages(_ messages: [Message]) {
           self.currentConversation?.messages = messages
       }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of messages in the current conversation safely
        if tableView.tag == 0 {
            return conversations.count  // Conversations count

        }else{
            return currentConversation?.messages.count ?? 0

        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView.tag == 0 {
            // Conversations table
            guard indexPath.row < conversations.count else {
                fatalError("Index out of range for conversations array")
            }

            let cell = tableView.dequeueReusableCell(withIdentifier: "convCell", for: indexPath)
            let conversation = conversations[indexPath.row]

            // Fetch the last message if there are any messages
            let lastMessage: String
            if let lastMsg = conversation.messages.last {
                lastMessage = lastMsg.text // Assuming `text` holds the message content
            } else {
                lastMessage = "New Chat" // If there are no messages in the conversation
            }

            // Set up the cell
            cell.textLabel?.numberOfLines = 2
            cell.textLabel?.text = "\(conversation.title)\n\(lastMessage)"
            return cell
        } else {
            // Messages table
            guard let currentConversation = currentConversation else {
                // If there's no current conversation, return an empty cell or handle accordingly
                let cell = tableView.dequeueReusableCell(withIdentifier: "msgCell", for: indexPath)
                return cell
            }
            
            guard indexPath.row < currentConversation.messages.count else {
                fatalError("Index out of range for messages array")
            }
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "msgCell", for: indexPath)
            let msg = currentConversation.messages[indexPath.row]
            cell.textLabel?.text = (msg.isFromUser ? "You: " : "Bot: ") + msg.text
            cell.textLabel?.textAlignment = msg.isFromUser ? .right : .left
            cell.textLabel?.textColor = msg.isFromUser && !msg.isSent ? .gray : .black
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.tag == 0 {
            onConversationSelected?(conversations[indexPath.row])
        }
    }
}

