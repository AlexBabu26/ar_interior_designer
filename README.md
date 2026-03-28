# AR Commerce Platform

A mobile-first e-commerce platform where users can place real products into their environment using augmented reality and purchase them. The Flutter app uses **Supabase** for auth, catalog, cart, and orders; an optional **Dart Frog** backend is included in the `server/` directory.

---

## Project structure

| Path        | Description                          |
|------------|--------------------------------------|
| `/` (root) | Flutter app — run `flutter` from here |
| `/server`  | Dart Frog API backend                |
| `/lib`     | Flutter app source code              |
| `/Docs`    | Design and documentation             |

---

## Getting started on Windows 11

Use **PowerShell** for all steps below (unless noted). Open PowerShell via Start menu or `Win + X` → “Windows PowerShell”.

### Prerequisites

- **Git** — [git-scm.com/downloads](https://git-scm.com/downloads)
- **VS Code (recommended)** — [code.visualstudio.com](https://code.visualstudio.com/) with the **Flutter** extension
- **Android Studio** (for Android) — [developer.android.com/studio](https://developer.android.com/studio) — install if you plan to run on emulator or device; `flutter doctor` will guide you

---

## 1. Install Flutter SDK

Flutter includes the Dart SDK; you do not install Dart separately.

### 1.1 Download and extract

1. Open [Flutter SDK archive](https://docs.flutter.dev/release/archive) and download the latest **stable** Windows zip (e.g. `flutter_windows_x.x.x-stable.zip`).
2. Extract the zip to a folder **without** spaces or elevated permissions, for example:
   - `C:\src\flutter`
   - or `C:\Users\<YourUsername>\flutter`
3. **Do not** use `C:\Program Files\` or other system-protected paths.

### 1.2 Add Flutter to PATH

Add the `bin` folder inside your Flutter install directory to your user **Path** so `flutter` and `dart` work in any terminal.

**Option A — GUI**

1. Press `Win`, type **env**, open **Edit the system environment variables**.
2. Click **Environment Variables...**.
3. Under **User variables**, select **Path** → **Edit...**.
4. Click **New** and add:
   - `C:\src\flutter\bin`  
   (or your path, e.g. `C:\Users\<YourUsername>\flutter\bin`).
5. Confirm with **OK** on all dialogs.

**Option B — PowerShell (current user)**

Run in PowerShell (replace with your actual Flutter path):

```powershell
$flutterPath = "C:\src\flutter\bin"
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";$flutterPath", "User")
```

Then **close and reopen PowerShell** (and VS Code if open) so the new PATH is loaded.

### 1.3 Verify Flutter and Dart

In a **new** PowerShell window:

```powershell
flutter doctor
dart --version
```

- Fix any issues reported by `flutter doctor` (e.g. Android licenses, Android Studio).
- You should see a Dart version (e.g. `Dart SDK version: 3.x.x`).

---

## 2. Install Dart Frog CLI (for the backend)

The `server/` app uses [Dart Frog](https://dartfrog.vgv.dev/). Install the CLI and ensure its scripts are on your PATH.

### 2.1 Activate the CLI

In PowerShell:

```powershell
dart pub global activate dart_frog_cli
```

### 2.2 Add Dart global bin to PATH

Global Dart packages install to a folder like:

`C:\Users\<YourUsername>\AppData\Local\Pub\Cache\bin`

Add this to your user **Path** using one of the following.

**Option A — GUI**

1. **Edit the system environment variables** → **Environment Variables...** → User **Path** → **Edit...**.
2. **New** → paste:  
   `C:\Users\<YourUsername>\AppData\Local\Pub\Cache\bin`  
   (replace `<YourUsername>` with your Windows username).
3. **OK** on all dialogs.

**Option B — PowerShell**

```powershell
$dartGlobalBin = "$env:LOCALAPPDATA\Pub\Cache\bin"
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";$dartGlobalBin", "User")
```

Close and reopen PowerShell.

### 2.3 Verify Dart Frog

```powershell
dart_frog --version
```

You should see a version string. If the command is not found, the PATH from step 2.2 is not visible in that session.

---

## 3. Clone the project

In PowerShell:

```powershell
cd D:\Projects\Academic Projects
git clone <repository-url> ar_interior_designer
cd ar_interior_designer
```

(Adjust paths and repo URL as needed.)

---

## 4. Run the Dart Frog backend (optional)

If you use the local API in `server/`:

1. In PowerShell, from the **project root**:

```powershell
cd server
dart pub get
dart_frog dev
```

2. Leave this window open. The server usually runs at **http://localhost:8080**.

---

## 5. Run the Flutter app from PowerShell

The Flutter app lives in the **project root**. Run all commands from there.

### 5.1 Install dependencies

From the project root in PowerShell:

```powershell
cd D:\Projects\Academic Projects\ar_interior_designer
flutter pub get
```

### 5.2 Choose a device and run

List devices:

```powershell
flutter devices
```

Then run on one of the following.

**Chrome (web):**

```powershell
flutter run -d chrome
```

**Windows desktop:**

```powershell
flutter run -d windows
```

(Requires Windows desktop support; `flutter doctor` will mention it.)

**Android emulator:**

1. Start an emulator from Android Studio.
2. Run:

```powershell
flutter run
```

**Physical Android device (recommended — use the helper script):**

1. Connect your phone via USB and enable **USB debugging** in Developer options.
2. Verify the device is visible:

```powershell
flutter devices
```

3. Run the helper script from the project root:

```powershell
.\run_device.ps1
```

This script automatically sets up ADB port forwarding for the Dart Frog backend and launches `flutter run` on the connected device.

> **Why port forwarding?** In debug mode the app loads 3D models from `http://localhost:8080` (the Dart Frog server on your PC). On an emulator this works automatically, but a physical phone's `localhost` refers to the phone itself. The script runs `adb reverse tcp:8080 tcp:8080` to tunnel the port back to the PC before every launch.

**Physical Android device (manual alternative):**

If you prefer to run each step yourself:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" reverse tcp:8080 tcp:8080
flutter run -d <device_id>
```

You need to re-run `adb reverse` each time you reconnect the USB cable.

The app will connect to the configured **Supabase** project (see `lib/config/supabase_config.dart`). If you use the Dart Frog backend, keep it running in the other terminal.

---

## Quick reference — PowerShell commands

From **project root** (`ar_interior_designer`):

| Task              | Command              |
|-------------------|----------------------|
| Get dependencies  | `flutter pub get`    |
| List devices      | `flutter devices`   |
| Run (default)     | `flutter run`        |
| Run on Chrome     | `flutter run -d chrome` |
| Run on Windows    | `flutter run -d windows` |
| Run on phone      | `.\run_device.ps1` (auto port-forward + run) |
| Run on phone (manual) | `flutter run -d android` |
| ADB reverse port  | `& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" reverse tcp:8080 tcp:8080` |
| Run tests         | `flutter test`       |
| Check environment | `flutter doctor`     |

From **project root** for backend:

| Task        | Command           |
|------------|--------------------|
| Backend dir| `cd server`       |
| Get deps   | `dart pub get`     |
| Start API  | `dart_frog dev`    |

---

## Troubleshooting

- **`flutter` or `dart` not found**  
  PATH not set or terminal not restarted. Add Flutter `bin` (and Dart `Pub\Cache\bin` if using global packages), then close and reopen PowerShell/VS Code.

- **`dart_frog` not found**  
  Add `%LOCALAPPDATA%\Pub\Cache\bin` to user PATH and restart the terminal.

- **Android / Windows not available**  
  Run `flutter doctor` and follow its instructions (e.g. accept Android licenses, install Visual Studio for Windows desktop).

- **"Clear Text HTTP traffic to localhost not permitted" on a physical device**  
  The Android manifest must allow cleartext to localhost. This project includes a `network_security_config.xml` that permits it. If you still see the error, uninstall the app from the phone first, then rebuild with `flutter run`.

- **"Failed to connect to localhost:8080" for 3D models on a physical device**  
  The Dart Frog server runs on your PC, not the phone. Use `.\run_device.ps1` which handles port forwarding automatically, or run `adb reverse tcp:8080 tcp:8080` manually (see step 5.2 above). Re-run after every USB reconnect.

- **Supabase**  
  The app uses Supabase by default. Configure URL and anon key in `lib/config/supabase_config.dart` for your project.
