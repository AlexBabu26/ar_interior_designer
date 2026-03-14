# AR Commerce Platform

This project is a mobile-first e-commerce platform where users can place real products into their environment using augmented reality and purchase them instantly.

## Getting Started on Windows 11

Follow these steps to set up and run the AR Commerce Platform on your Windows 11 PC.

### Prerequisites

*   **Git:** Download and install Git from [git-scm.com](https://git-scm.com/downloads).
*   **VS Code (Recommended):** Download and install Visual Studio Code from [code.visualstudio.com](https://code.visualstudio.com/). Install the Flutter extension.

### 1. Install Flutter SDK

1.  **Download Flutter:** Go to the [Flutter SDK archive](https://docs.flutter.dev/release/archive) and download the latest stable release for Windows.
2.  **Extract the archive:** Extract the `flutter_windows_x.x.x-stable.zip` file to a preferred installation location (e.g., `C:\src\flutter`). Do NOT install Flutter in a directory like `C:\Program Files\` that requires elevated privileges.
3.  **Update your PATH:**
    *   In the Windows search bar, type `env` and select **"Edit the system environment variables"**.
    *   In the System Properties dialog, click **"Environment Variables..."**.
    *   Under "User variables for <your-username>", select `Path` and click **"Edit..."**.
    *   Click **"New"** and add the path to the `bin` folder inside your Flutter installation directory (e.g., `C:\src\flutter\bin`).
    *   Click "OK" on all dialogs to close.
4.  **Verify Flutter Installation:** Open a new Command Prompt or PowerShell window and run:
    ```bash
    flutter doctor
    ```
    This command checks your environment and displays a report of the status of your Flutter installation. Follow any suggestions it provides for missing dependencies (e.g., Android SDK, Android Studio).

### 2. Install Dart Frog CLI

The backend is built with Dart Frog. You need to install its command-line interface.

1.  Open a Command Prompt or PowerShell and run:
    ```bash
    dart pub global activate dart_frog_cli
    ```
2.  **Add Dart's global bin to PATH (if not already there):**
    *   The command above will tell you where `dart pub global` installed the executables (e.g., `C:\Users\<your-username>\AppData\Local\Pub\Cache\bin`).
    *   Add this path to your system's `Path` environment variable, similar to how you added Flutter's `bin` directory in step 1.3.

### 3. Clone the Project

1.  Open Git Bash, Command Prompt, or PowerShell.
2.  Navigate to the directory where you want to clone the project.
3.  Clone the repository:
    ```bash
    git clone <repository-url>
    cd <project-folder-name>
    ```

### 4. Run the Dart Frog Backend

1.  Navigate into the `server` directory from your project root:
    ```bash
    cd server
    ```
2.  Install backend dependencies:
    ```bash
    dart pub get
    ```
3.  Start the Dart Frog development server:
    ```bash
    dart_frog dev
    ```
    The server will start, usually on `http://localhost:8080`. Keep this terminal window open.

### 5. Run the Flutter Client

1.  Open a **NEW** Command Prompt or PowerShell window.
2.  Navigate back to the root of your project (e.g., `cd ..` if you are in the `server` directory).
3.  Install frontend dependencies:
    ```bash
    flutter pub get
    ```
4.  **Choose a device to run on:**
    *   To see available devices: `flutter devices`
    *   **Web (Chrome):** `flutter run -d chrome`
    *   **Android Emulator:** Start an emulator from Android Studio, then `flutter run`
    *   **Windows Desktop App:** `flutter run -d windows` (if Windows development is configured via `flutter doctor`)
    *   **iOS Simulator/Physical Device:** Requires macOS.

The Flutter application will launch on your selected device, connecting to the running Dart Frog backend.
