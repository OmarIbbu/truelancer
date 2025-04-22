//
//  Untitled 2.swift
//  ChatApp1
//
//  Created by Umar Farooq on 21/04/25.
//
import UIKit

class MainViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var convTable: UITableView!
    @IBOutlet weak var msgTable: UITableView!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!

    private let chatService = ChatService(socketManager: WebSocketManager())
     var conversations: [Conversation] = []
    private var messages: [Message] = []
    private var currentConversation: Conversation?
    private var tableHandler: MainViewControllerTableHandler!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        setupTableHandler()
        setupChatService()
        setupUI()
        styleUIElements()


        // Create a default conversation
        let conversation = chatService.createConversation(title: "")
        chatService.setActiveConversation(conversation)
        currentConversation = conversation
        reloadConversations()

        messageTextField.delegate = self
    }

    @IBAction func add(_ sender: Any) {
        // Step 1: Create a new conversation
          let newConversation = chatService.createConversation(title: "")

          // Step 2: Update active conversation
          chatService.setActiveConversation(newConversation)

          // Step 3: Fetch updated conversations and update the table handler
          self.conversations = chatService.fetchConversations() // Make sure we update the local array
          tableHandler.updateConversations(self.conversations) // Update tableHandler with new conversations

          // Step 4: Update the current conversation and messages
          tableHandler.updateMessages([]) // Fresh chat, no messages yet
          tableHandler.updateCurrentConversation(newConversation)

          // Step 5: Reload the tables
          convTable.reloadData()  // Reload conversations table
          msgTable.reloadData()   // Reload messages table
     }
    
       
    
    private func startNewChat() {
        let newConversation = Conversation(
               id: UUID(),
               title: "",
               messages: [],
               lastUpdated: Date()
           )

           chatService.conversations.append(newConversation)
           currentConversation = newConversation
           messages = []

           tableHandler.updateConversations(chatService.conversations)
           tableHandler.updateCurrentConversation(currentConversation)
           tableHandler.updateMessages(messages)
           convTable.reloadData()
           msgTable.reloadData()
           scrollToBottom()
    }
        
    
    // MARK: - UI Setup
    
  
    private func setupUI() {
        convTable.register(UITableViewCell.self, forCellReuseIdentifier: "convCell")
        msgTable.register(UITableViewCell.self, forCellReuseIdentifier: "msgCell")

        convTable.tag = 0
        msgTable.tag = 1
    }
    
    private func styleUIElements() {
        // Style the send button
        sendButton.layer.cornerRadius = 8
        sendButton.clipsToBounds = true

        // Style the message text field
        messageTextField.layer.cornerRadius = 8
        messageTextField.layer.borderWidth = 1
        messageTextField.layer.borderColor = UIColor.lightGray.cgColor
        messageTextField.clipsToBounds = true
    }
    
 
    private func setupTableHandler() {
        tableHandler = MainViewControllerTableHandler(
            conversations: conversations,
            messages: messages,
            onConversationSelected: { [weak self] selectedConversation in
                self?.selectConversation(selectedConversation)
                self?.currentConversation = selectedConversation

            }
        )

        convTable.dataSource = tableHandler
        convTable.delegate = tableHandler
        convTable.tag = 0

        msgTable.dataSource = tableHandler
        msgTable.delegate = tableHandler
        msgTable.tag = 1
    }
    // MARK: - Chat Logic

    private func setupChatService() {
        chatService.connect()

        chatService.onConversationsUpdated = { [weak self] in
            DispatchQueue.main.async {
                self?.reloadConversations()
            }
        }

        chatService.onNewMessage = { [weak self] message, conversation in
            guard let self = self else { return }
            if self.currentConversation?.id == conversation.id {
                self.messages.append(message)
                DispatchQueue.main.async {
                    self.msgTable.reloadData()
                    self.scrollToBottom()
                }
            }
        }

        chatService.onInternetStatusChanged = { [weak self] isOnline in
            guard let self = self else { return }
            if isOnline {
                DispatchQueue.main.async {
                    self.convTable.reloadData()
                    self.msgTable.reloadData()
                    self.scrollToBottom()
                }
            }
        }
    }

    private func reloadConversations() {
        conversations = chatService.fetchConversations()
        tableHandler.updateConversations(conversations)
        convTable.reloadData()

        if let first = conversations.first, first != currentConversation {
            selectConversation(first)
        }
    }

    private func selectConversation(_ conv: Conversation) {
        currentConversation = conv
        messages = chatService.fetchMessages(for: conv)
        tableHandler.updateMessages(messages)
        tableHandler.updateCurrentConversation(currentConversation)
        msgTable.reloadData()
        scrollToBottom()
    }
    private func scrollToBottom() {
        guard !messages.isEmpty else { return }
        let lastRow = messages.count - 1
        let indexPath = IndexPath(row: lastRow, section: 0)
        if msgTable.numberOfRows(inSection: 0) > lastRow {
            msgTable.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }

    // MARK: - Actions

    @IBAction func didTapOnSendButton(_ sender: UIButton) {
        guard let text = messageTextField.text, !text.isEmpty,
              let conversation = currentConversation else { return }

        chatService.sendMessage(text, to: conversation)
        messageTextField.text = ""
        scrollToBottom()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
