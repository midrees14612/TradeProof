# trade_proof

A new Flutter project.




# ⚡ TradeProof Terminal: The Ultimate Trading Journal

TradeProof Terminal is a high-performance, cyber-themed trading journal and monitoring ecosystem built with **Flutter** and **Firebase**. Designed for disciplined traders (Forex/Crypto/Indices), it helps track performance through psychological modules like **The Vault**, **The Graveyard**, and **Monk Mode**.



## 🚀 Key Modules
* **🏦 The Vault:** Secured storage for your winning trades (Hall of Fame).
* **⚰️ The Graveyard:** A dark purgatory for your losses to remind you of your mistakes.
* **🧘‍♂️ Monk Mode:** A stoic interface that hides profits/losses to keep your emotions in check.
* **📊 Cyber Dashboard:** Real-time P&L tracking with neon-accented cyber-cards.
* **🕵️‍♂️ Admin Command Center:** Full control over user accounts, trade monitoring, and system security.
* **📈 Live Market:** Integrated TradingView charts with custom indicators.

## 🛠️ Tech Stack
* **Frontend:** Flutter (Dart)
* **Database:** Cloud Firestore
* **Auth:** Firebase Authentication
* **State Mgmt:** Provider / SharedPreferences
* **Charts:** WebView (TradingView API)

## 🏁 Getting Started

### 1. Prerequisites
* Flutter SDK (v3.0+)
* Java Development Kit (JDK)
* Firebase Account
* Git Installed

### 2. Installation
```bash
# Clone the repository
git clone [https://github.com/YOUR_USERNAME/TradeProof-Terminal.git](https://github.com/YOUR_USERNAME/TradeProof-Terminal.git)

# Navigate to project folder
cd TradeProof-Terminal

# Install dependencies
flutter pub get

# Run the app
flutter run

```

---

## 📡 Connecting MT5 (MetaTrader 5)

TradeProof Terminal supports automation with MT5 through a **Python Bridge/Expert Advisor (EA)**.

### Step 1: Python Bridge Setup

App ke `commands` collection (Firestore) ko listen karne ke liye aapko aik Python script ki zaroori hai jo MT5 Terminal par run karegi.

### Step 2: Firestore Commands

Dashboard mein jab aap "Close Trade" button press karte hain, Firebase mein ye command save hoti hai:

```json
{
  "action": "close",
  "ticket": "12345678",
  "timestamp": "serverTimestamp"
}

```

### Step 3: MT5 Execution

Python script Firestore se command read karke MT5 API ke zariye trade close kar deti hai:

```python
import MetaTrader5 as mt5
# Example logic
mt5.trade_order_send(request_to_close)

```

---

## 🛡️ Security & Roles

Project supports **Role-Based Access Control (RBAC)**:

* **ADMIN:** Access to Command Center, Block/Unblock users, Delete accounts, View user trades.
* **USER:** Access to Terminal, Market, and Personal Journal.


