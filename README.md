# Offline-First Notes App 📌

## Overview

This project is a Flutter-based offline-first notes application that demonstrates reliable data persistence, offline writes, and a queue-based sync mechanism with a backend (Firebase). The core focus is on offline resilience, idempotent syncing, and real-world production thinking rather than just CRUD functionality.

---

## 🚀 Features

The app allows users to:

- Create notes while offline
- Save and delete notes without an internet connection
- Store all changes locally in a persistent queue until sync is triggered
- Sync data with the cloud only when internet is available and the user taps **"Sync Now"**
- Automatically reflect cached notes instantly (local-first UX)
- Ensure safe and reliable syncing using a queue-based system with idempotency keys
- Prevent duplicate writes during retries

---

## 🧠 Core Architecture

### Local-First Storage
- Hive is used for offline persistence
- All notes are immediately stored locally
- UI always reads from local storage first

### Sync Queue System
- Every offline action (add/save/delete) is stored in a queue
- Each action has an idempotency key
- Queue persists across app restarts

### Manual Sync Trigger
Sync happens only when:
- Internet is available
- User clicks **Sync Now**
- Prevents uncontrolled background syncing

### Retry Handling
- Failed sync operations remain in queue
- Retry is handled safely without duplicate writes

### Conflict Strategy
- **Last Write Wins (LWW)** — simplest and most consistent approach for this scope

---

## 📡 Offline + Sync Behavior

### Scenario 1: Online Usage
1. Notes added → instantly saved locally
2. Sync button → pushes all changes to Firebase
3. UI shows **"All notes synced"**

### Scenario 2: Offline Usage
1. Notes added without internet → stored locally
2. Queue increases (pending sync)
3. UI shows **"No internet — will sync when online"**

### Scenario 3: Sync After Reconnection
1. Internet restored + **Sync Now** clicked
2. Queue processed successfully
3. All notes synced to cloud

---

## 📸 Verification Evidence

| # | Description |
|---|-------------|
| SS-1 | [Notes added online → pending sync state](View%20Screenshot) |
| SS-2 | [Sync successful with internet](View%20Screenshot) |
| SS-3 | [Offline note added + sync attempt (no internet error)](View%20Screenshot) |
| SS-4 | [Reconnected + successful sync](View%20Screenshot) |

**Screen recording also included.**

---

## ⚠️ Edge Cases Handled

- No internet during sync → graceful failure message
- App restart → queue persists
- Duplicate sync attempts → prevented using idempotency key
- Empty note validation
- Safe `setState` handling after async calls

---

## 🧪 Testing & Logs

Debug logs used for:
- Queue size tracking
- Sync success/failure
- Offline actions tracking

| Log | Description |
|-----|-------------|
| log1 | [log1] |
| log2 | [log2] |

---

## 🤖 AI Prompt Log

> Realistic iteration history of prompts used during development.

**Prompt 1:** I am building a Flutter offline-first notes app. I need local storage + sync to Firebase when internet is available. Suggest architecture.
- **Response summary:** Suggested Hive for local storage, Firebase for backend, and queue-based sync system with idempotency keys
- **Decision:** Accepted with minor modifications
- **Why:** Matched offline-first requirement and scalable structure

**Prompt 2:** How do I ensure offline actions (add/save/delete) don't get lost and sync safely later?
- **Response summary:** Recommended implementing a persistent sync queue with actions stored in Hive and processed later
- **Decision:** Accepted
- **Why:** Solves durability and offline write reliability

**Prompt 3:** I am getting duplicate writes in Firebase when retrying sync. How do I fix it?
- **Response summary:** Suggested using idempotency keys per action and ensuring backend ignores duplicates
- **Decision:** Accepted
- **Why:** Prevents duplicate writes during retries and re-sync

**Prompt 4:** Improve UI so users clearly understand sync status (offline, pending, synced)
- **Response summary:** Added UI indicators like pending count, sync badge, and status labels per note
- **Decision:** Modified and partially accepted
- **Why:** Improved UX clarity but simplified some design suggestions

**Prompt 5:** Handle no internet case properly when user clicks Sync Now
- **Response summary:** Added connectivity check + snackbar message: "No internet — will sync automatically when connected"
- **Decision:** Accepted
- **Why:** Required for real-world offline behavior and better UX feedback

---

## 📦 Tech Stack

| Technology | Purpose |
|------------|---------|
| Flutter | UI framework |
| Hive | Local offline storage |
| Firebase | Backend sync |
| Dart | Programming language |

---

## ⚖️ Tradeoffs

- Used **manual sync** instead of real-time sync for better control
- Chose **Last Write Wins** instead of complex conflict resolution
- **Simple retry logic** instead of exponential backoff (scope constraint)

---

## 🔮 Future Improvements

- Background auto-sync when internet returns
- Better conflict resolution (merge-based sync)
- Encryption for offline data
- Unit tests for queue + idempotency
- Pagination for large note lists

---

## 📌 How to Run

```bash
git clone <repo-url>
cd offline_notes_app
flutter pub get
flutter run
```

---

## 🏁 Summary

This project demonstrates a real-world offline-first architecture with:

- ✅ Persistent local storage
- ✅ Reliable sync queue
- ✅ Idempotent operations
- ✅ Clear UX for offline state
