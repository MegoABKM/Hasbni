# Hasbni POS (حاسبني) - Point of Sale System

<p align="center">
  <img src="https://raw.githubusercontent.com/m7md-abo-jacob/hasbni_app/main/assets/images/logo.png" alt="Hasbni Logo" width="150"/>
</p>

<p align="center">
  <strong>A modern, full-featured Point of Sale (POS) application built with Flutter and Supabase.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-blue.svg" alt="Flutter Version">
  <img src="https://img.shields.io/badge/Backend-Supabase-brightgreen.svg" alt="Backend Supabase">
  <img src="https://img.shields.io/badge/State%20Management-Bloc-blueviolet.svg" alt="State Management Bloc">
  <img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License MIT">
</p>

---

**Hasbni (حاسبني)**, which translates to "Calculate for me," is a comprehensive POS system designed for small to medium-sized businesses. It provides a seamless experience for managing sales, inventory, finances, and employees, all powered by a robust backend on Supabase.

## ✨ Features

Hasbni is packed with features to streamline your business operations:

#### 🔐 **Authentication & Security**
- **Email/Password Login:** Secure user authentication.
- **Dual Role System:**
  - **Manager:** Full access to all features, including reports, settings, and employee management.
  - **Employee:** Restricted access limited to the Point of Sale screen for daily operations.
- **Manager Password Protection:** An additional layer of security for the manager role, separate from the account password.

#### 🛒 **Point of Sale (POS)**
- **Intuitive Cart System:** Easily add products to the cart.
- **Dynamic Search & Scan:** Find products instantly by name or by scanning their barcode with the device camera.
- **Flexible Pricing & Quantity:** Adjust item prices and quantities directly in the cart.
- **Multi-Currency Support:** Complete sales in various currencies with real-time exchange rates.
- **Returns & Exchanges:** Process customer returns and exchanges against previous sales invoices.
- **PDF Receipts:** Generate, preview, print, and share professional PDF receipts for every transaction.

#### 📦 **Inventory Management**
- **Full CRUD Operations:** Add, edit, and delete products with ease.
- **Detailed Product Information:** Track quantity, cost price, selling price, and barcode for each item.
- **Advanced Filtering & Sorting:** Sort inventory by name, quantity, price, or date added.
- **Lazy Loading/Infinite Scrolling:** Efficiently handle and display large inventory lists without performance degradation.

#### 📊 **Financial Reporting & Analytics**
- **Comprehensive Dashboard:** Get a real-time overview of your business's financial health.
- **Flexible Time Periods:** Filter reports by day, week, month, year, or a custom date range.
- **Key Metrics Tracking:** Monitor total revenue, gross profit, expenses, and net profit.
- **Multi-Currency Reporting:** View financial summaries in your base currency (USD) or any configured local currency.

#### 💸 **Expense & Withdrawal Management**
- **Expense Tracking:** Log operational expenses with custom categories (e.g., rent, salaries).
- **Owner Withdrawals:** Record personal withdrawals made by the business owner.
- **Multi-Currency Transactions:** Log expenses and withdrawals in their original currency.

#### 👥 **Employee Management**
- **Centralized Management:** The manager can add, edit, and remove employee accounts.
- **Simple Employee Onboarding:** Create accounts for staff who only need access to the POS.

#### ⚙️ **System Configuration**
- **Shop Profile:** Set up your business details, including name, address, and phone number, which appear on receipts.
- **Exchange Rate Management:** Define and manage exchange rates for various currencies against a base currency (USD).

## 🚀 Technology Stack

This project leverages a modern, scalable tech stack:

- **Framework:** [Flutter](https://flutter.dev/)
- **Backend:** [Supabase](https://supabase.io/) (Authentication, PostgreSQL Database, Storage, Edge Functions/RPC)
- **State Management:** [Flutter Bloc](https://bloclibrary.dev/) (Cubit)
- **Database:** PostgreSQL (via Supabase)
- **Key Packages:**
  - `supabase_flutter`: Official Supabase client for Flutter.
  - `flutter_bloc`: Predictable state management.
  - `equatable`: Simplified value equality.
  - `mobile_scanner`: High-performance barcode scanning.
  - `printing` & `pdf`: PDF receipt generation and printing.
  - `just_audio`: Sound effects for user feedback (e.g., scan beep).
  - `google_fonts`: Beautiful, custom typography.
  - `shared_preferences`: Local session and role persistence.

## 🔧 Getting Started

To run this project locally, follow these steps:

**1. Prerequisites:**
- Ensure you have the [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
- Create a free [Supabase](https://supabase.com/) account.

**2. Clone the Repository:**
```bash
git clone https://github.com/your-username/hasbni-pos.git
cd hasbni-pos
```

**3. Set up Supabase Project:**
- On your Supabase dashboard, create a new project.
- Navigate to the **SQL Editor** and run the necessary SQL scripts to create tables (`products`, `sales`, `profiles`, `employees`, etc.) and RPC functions (`get_financial_summary`, `create_sale_and_update_inventory`, etc.).
  - *(Note: You will need to extract the schema and functions from the repository's database logic in `lib/data/repositories/`)*
- Go to **Project Settings > API** to find your **Project URL** and **anon public key**.

**4. Configure Flutter App:**
- Open the `lib/main.dart` file.
- Replace the placeholder values with your Supabase URL and anon key:
  ```dart
  // lib/main.dart

  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Supabase.initialize(
      url: 'YOUR_SUPABASE_URL',    // <-- Paste your URL here
      anonKey: 'YOUR_SUPABASE_ANON_KEY', // <-- Paste your anon key here
    );
    // ...
  }
  ```

**5. Install Dependencies:**
```bash
flutter pub get
```

**6. Run the App:**
```bash
flutter run
```

## 📂 Project Structure

The project follows a clean, feature-first architecture to ensure scalability and maintainability.

```
lib/
├── core/         # Core services, theme, constants, utils
│   ├── services/
│   ├── theme/
│   └── utils/
├── data/         # Data layer: models, repositories
│   ├── models/
│   └── repositories/
├── presentation/ # UI Layer: screens, widgets, and state management (Cubits)
│   ├── cubits/
│   ├── screens/
│   └── widgets/
└── main.dart     # App entry point
```

## 🤝 Contributing

Contributions are welcome! If you have suggestions for improvements or want to fix a bug, please feel free to:
1.  Fork the repository.
2.  Create a new branch (`git checkout -b feature/your-feature-name`).
3.  Make your changes.
4.  Commit your changes (`git commit -m 'Add some feature'`).
5.  Push to the branch (`git push origin feature/your-feature-name`).
6.  Open a Pull Request.

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
