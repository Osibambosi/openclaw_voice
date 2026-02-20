# Live_Chatty: Local Setup & Restore Guide

Welcome! If you are trying to run the **Live_Chatty** voice assistant locally, this step-by-step guide is designed specifically for beginners. 

This project consists of two main parts:
1. **The Backend** (`live_chatty_backend` folder): The Python server that connects to LiveKit and the AI models (OpenAI/Anthropic).
2. **The Frontend** (`live_chatty` folder): The Flutter web app user interface.

Before you begin, ensure you have the following installed on your computer:
*   [Python 3.11+](https://www.python.org/downloads/)
*   [Flutter SDK](https://docs.flutter.dev/get-started/install)
*   [Git](https://git-scm.com/downloads)

---

## Step 1: Download the Project
First, get the code onto your machine. If you are downloading from GitHub:
1. Open your terminal or command prompt.
2. Run the following command:
   ```bash
   git clone <YOUR_GITHUB_REPO_URL_HERE>
   ```
3. Navigate into the main workspace folder.

---

## Step 2: Setup the Brain (The Backend)
The backend does the heavy lifting: listening to audio, passing it to the AI, and generating speech.

1. Open your terminal and go into the backend folder:
   ```bash
   cd live_chatty_backend
   ```
2. Create an isolated "Virtual Environment" for Python to install dependencies without messing up your computer. Run:
   ```bash
   python3 -m venv venv
   ```
3. **Activate** the virtual environment:
   * **On Mac/Linux:** `source venv/bin/activate`
   * **On Windows:** `venv\Scripts\activate`
   *(You should see `(venv)` appear at the start of your terminal line).*
4. Install all the required packages:
   ```bash
   pip install livekit-agents livekit-plugins-openai livekit-plugins-silero python-dotenv
   ```
5. **CRITICAL STEP:** Create the environment variables file! 
   Because API Keys are like passwords, they are **NEVER** uploaded to GitHub. You must recreate the file locally.
   * Create a new file in the `live_chatty_backend` folder exactly called `.env`
   * Open `.env` in a text editor and paste in your secret keys:
     ```env
     LIVEKIT_URL=wss://your-livekit-project-url.cloud
     LIVEKIT_API_KEY=your_livekit_api_key_here
     LIVEKIT_API_SECRET=your_livekit_api_secret_here
     OPENAI_API_KEY=your_openai_api_key_here
     ```
6. Start the backend server!
   ```bash
   python agent.py start
   ```
   *Leave this terminal window open and running!*

---

## Step 3: Setup the Interface (The Frontend)
Now let's get the visual app running so you can talk to the AI.

1. Open a **NEW** terminal window (keep the backend running in the old one).
2. Go into the frontend folder:
   ```bash
   cd live_chatty
   ```
3. Download the Flutter dependencies:
   ```bash
   flutter pub get
   ```
4. Run the web application in Chrome:
   ```bash
   flutter run -d chrome
   ```

A Chrome window will automatically open with the Live_Chatty app. Click the connect button, and you should hear the AI greet you!

---

### Oops, something broke? (How to Reset)
If you made changes and the app stopped working, you can easily discard your changes and return to the last saved working state.
Run this command in the folder where you made the mistake (`live_chatty` or `live_chatty_backend`):
```bash
git restore .
```
*(Warning: This will delete any code changes you made since your last commit!)*
