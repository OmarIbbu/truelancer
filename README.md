# Chat App

This is a Swift-based iOS application that uses WebSocket to enable real-time chat functionality with a chatbot.

---

## Features

- Real-time communication using WebSocket.
- Handles network interruptions and automatically reconnects when the internet is restored.
- Follows key SOLID principles (especially Dependency Inversion).
- Implements testable components using dependency injection.
- Designed with separation of concerns in mind.
- Supports both iPhone and iPad, with portrait and landscape orientations.

---

## Architecture & Design Patterns

This app follows a lightweight *MVVM architecture*:

### View (ChatViewController)
- Handles UI-related logic.
- Displays chat messages in a UITableView.
- Delegates user input and WebSocket connection handling to the ViewModel.

### ViewModel (ChatViewModel)
- Contains business logic and acts as a bridge between the View and Model layers.
- Uses dependency injection to allow testability and loose coupling.
- Responsible for:
  - Managing WebSocket connections via WebSocketManager.
  - Sending and receiving messages.
  - Updating the View with new messages or connection status.

### Model
- Message struct representing chat messages.
- Conforms to Codable for easy JSON encoding/decoding.

### WebSocket Layer
- WebSocketManager: Manages WebSocket connections.
  - Handles connection, disconnection, and message listening.
  - Automatically reconnects on network restoration.
- Uses URLSession's WebSocketTask for real-time communication.

### Network Error Handling
- Defines custom error types (e.g., `NetworkError`) for better error handling.
- Ensures errors are propagated and handled gracefully in the ViewModel and View.

---
##  Setup Instructions

1. Clone the repo:
   git clone https://github.com/OmarIbbu/truelancer

3. Open the project in Xcode:
   open ChatApp1.xcodeproj
 
4. Build & run the app on a simulator or real device.
