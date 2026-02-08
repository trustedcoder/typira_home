# Typira Backend API

The Typira Backend API is built with **Flask** and serves as the central hub for user data, synchronization, and advanced AI processing.

## Prerequisites

- **Python** (version 3.8 or higher)
- **MySQL** (or compatible SQL database)
- **Virtualenv** (recommended)

## Setup Instructions

1.  **Navigate to the backend directory:**
    ```bash
    cd backend_api/typira
    ```

2.  **Create and Activate Virtual Environment:**
    ```bash
    python3 -m venv venv
    source venv/bin/activate  # On Windows use `venv\Scripts\activate`
    ```

3.  **Install Dependencies:**
    ```bash
    pip install -r requirements.txt
    ```

4.  **Environment Configuration:**
    Create a `.env` file in the `backend_api/typira` directory and set the following variables:

| Variable | Description | Default |
| :--- | :--- | :--- |
| `ENV` | Environment mode (`dev` or `prod`) | `dev` |
| `SECRET_KEY` | Secret key for JWT encryption and session security | - |
| `DATABASE_URL` | SQLAlchemy connection string (e.g., `mysql+pymysql://user:pass@host/db`) | - |
| `GEMINI_API_KEY` | API Key for Google Gemini AI | - |

5.  **Firebase Credentials:**
    Ensure the Firebase Admin SDK JSON file (`typira-ee2d4-firebase-adminsdk-fbsvc-43257b6e08.json`) is present in the `backend_api/typira` root directory.

## Database Management

This project uses **Flask-Migrate** (Alembic) for database migrations.

- **Initialize/Upgrade Database:**
  ```bash
  flask db upgrade
  ```

- **Seed Database:**
  Populate the database with initial data (roles, test users, etc.):
  ```bash
  python seed_db.py
  ```

## Running the Server

You can run the server using Flask's built-in command or via the `manage.py` script.

- **Using Flask:**
  ```bash
  flask run
  ```

- **Using Python Script:**
  ```bash
  python manage.py runserver
  ```
  *(Note: Check `manage.py` for exact command arguments support)*

## Tech Stack

- **Framework**: Flask (Python)
- **Database**: SQLAlchemy ORM (with MySQL driver)
- **Authentication**: JWT & Firebase Admin SDK
- **WebSockets**: Flask-SocketIO (for real-time updates)
- **AI**: Google GenAI SDK
- **Task Scheduling**: APScheduler

## API Documentation

- **Swagger UI**: [http://localhost:7009/api/doc/](http://localhost:7009/api/doc/)
- Endpoints are organized in `app/endpoints`.
- Typical structure:
    - `/auth`: Authentication routes
    - `/user`: User profile management
    - `/data`: Syncing typing data and analytics
