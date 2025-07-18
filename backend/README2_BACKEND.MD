# 🚀 MedApp Backend Setup Guide (FastAPI + MongoDB)

This guide walks you step-by-step through setting up the MedApp backend locally using FastAPI, MongoDB Atlas, and Python.

---

## 🗓️ Requirements

| Tool          | Version/Info              |
| ------------- | ------------------------- |
| Python        | >= 3.10                   |
| MongoDB Atlas | Access + Connection URI   |
| Poetry OR pip | Optional: virtualenv tool |

---

## 📚 1. Set Up a Virtual Environment

### ✅ Windows (CMD/PowerShell):

```bash
python -m venv venv
venv\Scripts\activate
```

### 🌐 macOS/Linux:

```bash
python3 -m venv venv
source venv/bin/activate
```

> ✉ Important: Reactivate the environment in every new terminal session.

---

## 🔧 2. Install Dependencies

This command will automatically create a `requirements.txt` file **and** install all dependencies:

```bash
echo "fastapi
uvicorn[standard]
python-dotenv
pymongo
passlib[bcrypt]
python-jose
email-validator" > requirements.txt && pip install -r requirements.txt
```

Just press **Enter** — everything will be handled for you ✅

---

## 🔐 3. Set Environment Variables

Create a `.env` file in your project folder:

```env
MONGO_URI=mongodb+srv://<USER>:<PASSWORD>@medapp.xxxxxx.mongodb.net/MedApp?retryWrites=true&w=majority
JWT_SECRET=<your_secret_jwt_key>
```

Example values for local testing:

```env
MONGO_URI=mongodb+srv://dbUser:dbUserPassword@medapp.tdtpszy.mongodb.net/MedApp?retryWrites=true&w=majority
JWT_SECRET=RyiYP7ng6iZIFtNGKww5EWyqcs6BdmKaegxbWjsCIWPGqspiXEJRvaRkOsHYw3G74QbtAhnW7Hq97qWSEtYt8g
```

---

## 🔢 4. Start the Server (Locally)

```bash
uvicorn backend.app:app --reload
```

* `--reload`: Enables hot reloading on code changes
* Default Port: `http://127.0.0.1:8000`
* API Docs: `http://127.0.0.1:8000/docs`

---

## 🔍 5. Functionality Test

**Ping Check:**

```bash
curl http://127.0.0.1:8000/ping
# Response: {"msg": "pong"}
```

**Test MongoDB Connection:**

```bash
python backend/mongo_ping.py
```

---

## 📁 Project Structure (Excerpt)

```text
backend/
├── app.py                # Main API entry point
├── db.py                 # MongoDB connection
├── auth_utils.py         # JWT & password handling
├── auth_service.py       # Alternative auth API
├── patient.py            # Patient endpoints
├── community.py          # Communities & groups
├── com_message.py        # Group posts
├── dm_message.py         # Direct messages
├── mongo_ping.py         # MongoDB connection check
└── __init__.py           # Marks folder as Python module
```

---

## ❌ Important Notes

* Never push `.env` to the repository
* `JWT_SECRET` should be complex and secure
* Ensure your MongoDB cluster allows access from your IP (e.g. `0.0.0.0/0` for testing purposes)

---

## 💪 Example Commands

**Register a User:**

```bash
curl -X POST http://127.0.0.1:8000/register \
 -H "Content-Type: application/json" \
 -d '{
     "email": "demo@example.com",
     "password": "abc123",
     "password_confirm": "abc123",
     "firstname": "Max",
     "lastname": "Mustermann",
     "med_id": "A12345"
 }'
```

**Authorized Request Using Token:**

```bash
curl http://127.0.0.1:8000/patient/me \
 -H "Authorization: Bearer <TOKEN>"
```

---

## 🌟 Done!

The backend is now running locally. You can test all endpoints via Swagger at `/docs`. Have fun and stay healthy! ✨
