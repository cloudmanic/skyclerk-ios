# Skyclerk iOS

Native SwiftUI iOS app for [Skyclerk](https://skyclerk.com), a simple bookkeeping and accounting platform. This is a rewrite of the original Ionic mobile app.

## Requirements

- Xcode 26+
- iOS 18.0+ deployment target
- Swift 6.0
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/skyclerk/skyclerk-ios.git
cd skyclerk-ios
```

### 2. Configure secrets

Copy the example secrets file into the source directory and fill in your values:

```bash
cp Secrets.example.swift Skyclerk/Services/Secrets.swift
```

Edit `Skyclerk/Services/Secrets.swift` with your API keys:

- **clientId** — OAuth client ID for the Skyclerk API
- **googleMapsApiKey** — Google Maps API key for location services

`Secrets.swift` is excluded from version control via `.gitignore`.

### 3. Generate the Xcode project and build

```bash
make build
```

This runs `xcodegen generate` to create `Skyclerk.xcodeproj` from `project.yml`, then builds for the simulator.

### 4. Run on simulator

```bash
make run
```

The Makefile auto-detects available iPhone simulators, preferring iOS 26+ runtimes.

## Makefile Commands

| Command | Description |
|---------|-------------|
| `make build` | Generate Xcode project and build for simulator |
| `make run` | Build and launch on simulator |
| `make logs` | Stream API logs from the simulator in real time |
| `make typecheck` | Type-check all Swift files (fast, no full build) |
| `make clean` | Clean build artifacts and DerivedData |
| `make wipe` | Clean everything and regenerate the Xcode project |
| `make open` | Open the project in Xcode |
| `make info` | Show detected build environment |
| `make simulators` | List available iPhone simulators |
| `make runtimes` | List installed simulator runtimes |
| `make count` | Count lines of Swift code |
| `make files` | List all Swift source files |

## Project Structure

```
Skyclerk/
├── Assets.xcassets/        # App icon, logo, accent color
├── Info.plist              # App configuration and permissions
├── SkyclerkApp.swift       # App entry point
├── Models/                 # Data models (Codable structs)
│   ├── Account.swift       # Account (workspace)
│   ├── APIResponse.swift   # Login/Register responses, PnlCurrentYear
│   ├── Billing.swift       # Subscription and billing info
│   ├── Category.swift      # Income/expense categories
│   ├── Contact.swift       # Payees and payers
│   ├── FileModel.swift     # Uploaded files and receipts
│   ├── Label.swift         # Tags for ledger entries (LedgerLabel)
│   ├── Ledger.swift        # Financial transactions
│   ├── SnapClerk.swift     # Receipt processing submissions
│   └── User.swift          # Authenticated user profile
├── Services/               # API communication and business logic
│   ├── APIService.swift    # HTTP client (GET, POST, PUT, DELETE, multipart)
│   ├── AccountService.swift
│   ├── AuthService.swift   # Login, register, logout, session management
│   ├── CategoryService.swift
│   ├── ContactService.swift
│   ├── Environment.swift   # App configuration (server URL, version)
│   ├── FileService.swift
│   ├── LabelService.swift
│   ├── LedgerService.swift
│   ├── MeService.swift     # User profile and account resolution
│   ├── PingService.swift   # Subscription status polling
│   ├── ReportService.swift
│   └── SnapClerkService.swift
├── Utilities/
│   ├── Extensions.swift    # Color, date, and currency helpers
│   ├── ImagePicker.swift   # Camera and photo library integration
│   └── LocationManager.swift
└── Views/
    ├── Components/
    │   ├── LedgerRowView.swift
    │   └── SnapClerkRowView.swift
    ├── HomeView.swift      # Main tabbed interface (4 tabs)
    ├── IntroView.swift     # Onboarding screen
    ├── LabelsView.swift    # Label picker for ledger entries
    ├── LedgerModifyView.swift  # Create/edit ledger entry
    ├── LedgerViewPage.swift    # Ledger entry detail
    ├── LoginView.swift
    ├── PaywallView.swift
    ├── RegisterView.swift
    ├── SettingsView.swift
    └── UploadReceiptView.swift
```

## Architecture

- **SwiftUI** with `@Published` / `ObservableObject` for reactive state
- **Singleton services** for API communication (`APIService.shared`, `AuthService.shared`, etc.)
- **Swift concurrency** (async/await) for all network calls
- **UserDefaults** for session persistence (access token, account ID)
- **xcodegen** for project generation — the `.xcodeproj` is not committed

### Authentication Flow

1. User logs in via `/oauth/token` (password grant)
2. App stores the access token in UserDefaults
3. App calls `/oauth/me` to fetch the user's accounts list
4. First account ID is stored as the active account
5. All subsequent API calls include `Bearer {token}` in the Authorization header

### Multi-Account Support

Users can belong to multiple accounts (workspaces). The active account ID is stored in UserDefaults and used to build API URL paths (`/api/v3/{accountId}/...`). Users can switch accounts from the home screen header.

## API Endpoints

All account-scoped endpoints use the pattern `/api/v3/{accountId}/{resource}`. The base URL is `https://app.skyclerk.com`.

### Authentication

| Method | Path | Description | Body Format |
|--------|------|-------------|-------------|
| POST | `/oauth/token` | Login (password grant) | form-urlencoded |
| POST | `/register` | Create new user account | form-urlencoded |
| GET | `/oauth/me` | Get current user profile and accounts list | — |

### Ledger (Transactions)

| Method | Path | Description | Body Format |
|--------|------|-------------|-------------|
| GET | `/api/v3/{accountId}/ledger` | List ledger entries (paginated) | — |
| GET | `/api/v3/{accountId}/ledger/{id}` | Get single ledger entry | — |
| POST | `/api/v3/{accountId}/ledger` | Create ledger entry | JSON |
| DELETE | `/api/v3/{accountId}/ledger/{id}` | Delete ledger entry | — |

**Query parameters for listing:** `page` (int), `type` (optional: "Income", "Expense"), `search` (optional text).
Pagination is indicated by the `X-Last-Page` response header (`true`/`false`).

### Contacts

| Method | Path | Description | Body Format |
|--------|------|-------------|-------------|
| GET | `/api/v3/{accountId}/contacts` | List contacts | — |
| POST | `/api/v3/{accountId}/contacts` | Create contact | JSON |

**Query parameters:** `limit` (int), `search` (optional text).

### Categories

| Method | Path | Description | Body Format |
|--------|------|-------------|-------------|
| GET | `/api/v3/{accountId}/categories` | List all categories | — |

### Labels

| Method | Path | Description | Body Format |
|--------|------|-------------|-------------|
| GET | `/api/v3/{accountId}/labels` | List all labels | — |
| POST | `/api/v3/{accountId}/labels` | Create label | JSON |

### Files

| Method | Path | Description | Body Format |
|--------|------|-------------|-------------|
| POST | `/api/v3/{accountId}/files` | Upload file | multipart/form-data |

### SnapClerk (Receipt Processing)

| Method | Path | Description | Body Format |
|--------|------|-------------|-------------|
| GET | `/api/v3/{accountId}/snapclerk` | List receipt submissions (paginated) | — |
| POST | `/api/v3/{accountId}/snapclerk` | Upload receipt for processing | multipart/form-data |

**Query parameters for listing:** `page` (int), `order` ("desc"), `sort` ("created_at").

### Account Management

| Method | Path | Description | Body Format |
|--------|------|-------------|-------------|
| GET | `/api/v3/{accountId}/account` | Get account details | — |
| PUT | `/api/v3/{accountId}/account` | Update account | JSON |
| POST | `/api/v3/{accountId}/account/delete` | Delete account | — |
| GET | `/api/v3/{accountId}/account/billing` | Get billing info | — |

### User Profile

| Method | Path | Description | Body Format |
|--------|------|-------------|-------------|
| PUT | `/api/v3/{accountId}/me` | Update profile | JSON |
| POST | `/api/v3/{accountId}/me/change-password` | Change password | JSON |

### Reports

| Method | Path | Description | Body Format |
|--------|------|-------------|-------------|
| GET | `/api/v3/{accountId}/reports/pnl-current-year` | Current year P&L | — |

### Health Check

| Method | Path | Description | Body Format |
|--------|------|-------------|-------------|
| GET | `/api/v3/{accountId}/ping` | Check subscription status | — |

Returns a status field: `"active"`, `"delinquent"`, `"expired"`, or `"logout"`. Polled every 10 seconds while authenticated.

## API Response Format

All API responses use **snake_case** JSON keys. The Swift models use PascalCase properties with `CodingKeys` enums to map between the two conventions. For example:

```json
{
  "id": 173057,
  "account_id": 101,
  "contact_id": 55223,
  "date": "2026-02-01T08:00:00Z",
  "amount": 542.66,
  "category": { "id": 204672, "name": "Sales", "type": "income" },
  "contact": { "id": 55223, "name": "Acme Corp" },
  "labels": [{ "id": 51, "name": "project-x" }],
  "files": [],
  "note": "Monthly invoice"
}
```

The `/oauth/me` endpoint also uses snake_case and is decoded via intermediate structs in `MeService.swift`.

## Debugging

### API Logging

All API requests and responses are logged via `os.Logger` with subsystem `com.cloudmanic.skyclerk` and category `API`. Stream logs from the CLI:

```bash
make logs
```

Or manually:

```bash
xcrun simctl spawn booted log stream --predicate 'subsystem == "com.cloudmanic.skyclerk"' --style compact
```

Log output includes the HTTP method, full URL, auth token, response status code, and a truncated response body preview.

### View recent logs

```bash
xcrun simctl spawn booted log show --predicate 'subsystem == "com.cloudmanic.skyclerk"' --last 5m --style compact
```

## License

Copyright 2026 Cloudmanic Labs, LLC. All rights reserved.
