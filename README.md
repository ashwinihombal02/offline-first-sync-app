Offline-First Notes App (Sync Queue System)
📌 Overview

This project is a Flutter-based offline-first notes application that demonstrates reliable data persistence, offline writes, and a queue-based sync mechanism with a backend (Firebase).

The core focus is on offline resilience, idempotent syncing, and real-world production thinking rather than just CRUD functionality.

🚀 Features

The app allows users to:

Create notes while offline
Save and delete notes without an internet connection
Store all changes locally in a persistent queue until sync is triggered
Sync data with the cloud only when internet is available and the user taps “Sync Now”
Automatically reflect cached notes instantly (local-first UX)
Ensure safe and reliable syncing using a queue-based system with idempotency keys
Prevent duplicate writes during retries
🧠 Core Architecture
1. Local-First Storage
Hive is used for offline persistence
All notes are immediately stored locally
UI always reads from local storage first
2. Sync Queue System
Every offline action (add/save/delete) is stored in a queue
Each action has an idempotency key
Queue persists across app restarts
3. Manual Sync Trigger
Sync happens only when:
Internet is available
User clicks Sync Now
Prevents uncontrolled background syncing
4. Retry Handling
Failed sync operations remain in queue
Retry is handled safely without duplicate writes
5. Conflict Strategy
Last Write Wins (LWW)
Simplest and most consistent approach for this assignment scope
📡 Offline + Sync Behavior
Scenario 1: Online usage
Notes added → instantly saved locally
Sync button → pushes all changes to Firebase
UI shows "All notes synced"
Scenario 2: Offline usage
Notes added without internet → stored locally
Queue increases (pending sync)
UI shows "No internet — will sync when online"
Scenario 3: Sync after reconnection
Internet restored + Sync Now clicked
Queue processed successfully
All notes synced to cloud
📸 Verification Evidence

## 📸 Verification Evidence (Screenshots)

- **SS-1: Notes added online → pending sync state**  
  [View Screenshot](https://drive.google.com/file/d/1_rlkLUTTmRyYwindlGtWMIr2iKHeAmwT/view?usp=drive_link)

- **SS-2: Sync successful with internet**  
  [View Screenshot](https://drive.google.com/file/d/1IoX6qLTBtiMJX94L_NwQmWB7xVK_9yVG/view?usp=drive_link)

- **SS-3: Offline note added + sync attempt (no internet error)**  
  [View Screenshot](https://drive.google.com/file/d/1tXf1-uJ8IcpXAv86_sShFpWSKckcDsMD/view?usp=drive_link)

- **SS-4: Reconnected + successful sync**  
  [View Screenshot](https://drive.google.com/file/d/1RS1GrIW3_2NG1lle7pkcrNj56qFEuAeo/view?usp=drive_link)

📹 Screen recording also included : 

⚠️ Edge Cases Handled
No internet during sync → graceful failure message
App restart → queue persists
Duplicate sync attempts → prevented using idempotency key
Empty note validation
Safe setState handling after async calls
🧪 Testing & Logs
Debug logs used for:
Queue size tracking
Sync success/failure
Offline actions tracking

## 📹 Logs / Evidence

- log1: [Sync Demo Video 1](https://drive.google.com/file/d/1C30j15jrbZoyQXHl2rRBneVQxXwxIr0V/view?usp=drive_link)  
- log2: [Sync Demo Video 2](https://drive.google.com/file/d/1W07aYdl9ZgXn-K2qYDG50Du2X3PU6lrV/view?usp=drive_link)

🤖 AI Prompt Log
🤖 AI Prompt Log (Realistic Iteration History)
1) Prompt:

I am building a Flutter offline-first notes app. I need local storage + sync to Firebase when internet is available. Suggest architecture.

Key response summary: Suggested Hive for local storage, Firebase for backend, and queue-based sync system with idempotency keys
Decision: Accepted with minor modifications
Why: Matched offline-first requirement and scalable structure
2) Prompt:

How do I ensure offline actions (add/save/delete) don’t get lost and sync safely later?

Key response summary: Recommended implementing a persistent sync queue with actions stored in Hive and processed later
Decision: Accepted
Why: Solves durability and offline write reliability
3) Prompt:

I am getting duplicate writes in Firebase when retrying sync. How do I fix it?

Key response summary: Suggested using idempotency keys per action and ensuring backend ignores duplicates
Decision: Accepted
Why: Prevents duplicate writes during retries and re-sync
4) Prompt:

Improve UI so users clearly understand sync status (offline, pending, synced)

Key response summary: Added UI indicators like pending count, sync badge, and status labels per note
Decision: Modified and partially accepted
Why: Improved UX clarity but simplified some design suggestions
5) Prompt:

Handle no internet case properly when user clicks Sync Now

Key response summary: Added connectivity check + snackbar message: “No internet — will sync automatically when connected”
Decision: Accepted
Why: Required for real-world offline behavior and better UX feedback
📦 Tech Stack
Flutter
Hive (Local storage)
Firebase (Backend sync)
Dart
⚖️ Tradeoffs
Used manual sync instead of real-time sync for better control
Chose Last Write Wins instead of complex conflict resolution
Simple retry logic instead of exponential backoff (scope constraint)
🔮 Future Improvements
Background auto-sync when internet returns
Better conflict resolution (merge-based sync)
Encryption for offline data
Unit tests for queue + idempotency
Pagination for large note lists
📌 How to Run
git clone <repo-url>
cd offline_notes_app
flutter pub get
flutter run
🏁 Summary

This project demonstrates a real-world offline-first architecture with:

Persistent local storage
Reliable sync queue
Idempotent operations
Clear UX for offline states
