# Django Login/Signup Setup Automation

A PowerShell script (`SETUP.ps1`) that scaffolds a complete Django project with a
**custom user model**, working **signup → login → dashboard → logout** flow,
Django REST Framework, and static/media file support — all in one run.

---

## Features

* Creates a Python virtual environment
* Installs Django, Django REST Framework, and Pillow
* Creates the Django project and app
* Custom user model (`CustomUser`) with `full_name`, `bio`, and `profile` picture
* Full authentication flow: Sign Up → Login → Dashboard (Home) → Logout
* Success/warning messages shown on the correct page at each step
* Static files (CSS) and media files (profile pictures) configured and served in dev
* Runs migrations in the correct order for a custom user model
* Auto-creates a superuser
* Starts the dev server and opens the login page in your browser

---

## Project Structure

```text
ProjectFolder/
│
├── env/                          Virtual environment
├── manage.py
├── db.sqlite3
├── requirements.txt
├── .gitignore
│
├── myProject/
│   ├── __init__.py
│   ├── settings.py               AUTH_USER_MODEL, MEDIA, STATIC, LOGIN_URL etc.
│   ├── urls.py                   home / login / signup / logout routes
│   ├── asgi.py
│   └── wsgi.py
│
├── myApp/
│   ├── migrations/
│   ├── templates/
│   │   ├── login.html
│   │   ├── signup.html
│   │   └── myApp/
│   │       └── index.html        Dashboard / home page
│   ├── models.py                 CustomUser
│   ├── views.py                  login_page, signup_page, home, logout_page
│   └── admin.py                  CustomUser registered with extra fields
│
├── static/
│   └── css/
│       └── style.css
│
└── media/
    └── profiles/                 Uploaded profile pictures
```

---

## Requirements

* Python 3.8+
* pip
* Windows PowerShell

Verify before running:

```bash
python --version
pip --version
```

---

## Running the Setup Script

### 1. Open PowerShell in the folder containing `SETUP.ps1`

### 2. Allow script execution (one-time, per session)

If you see:

```text
running scripts is disabled on this system
```

Run:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

### 3. Run it

```powershell
.\SETUP.ps1
```

The script will prompt you interactively:

```text
===== Django Project Setup =====
Press Enter to accept the default shown in [brackets].

Root folder name [ProjectFolder]:
Django project name [myProject]:
Django app name [myApp]:
```

Type a name and press Enter, or just press Enter to accept the default shown
in brackets.

You can also skip the prompts entirely by passing the values as parameters —
any parameter you supply this way is used as-is and its prompt is skipped:

```powershell
.\SETUP.ps1 -RootFolder MyApp -ProjectName CoreProject -AppName accounts
```

| Parameter      | Default         | Description                  |
|----------------|-----------------|-------------------------------|
| `-RootFolder`  | `ProjectFolder` | Folder created for the project |
| `-ProjectName` | `myProject`     | Django project (settings) name |
| `-AppName`     | `myApp`         | Django app name                |

When it finishes, it opens `http://127.0.0.1:8000/login/` automatically.

---

## The Authentication Flow

This is the part that's easy to get subtly wrong, so here's exactly what happens
at each step and **why**.

```text
┌─────────────┐      ┌─────────────┐      ┌─────────────────┐      ┌─────────────┐
│  Sign Up     │ ───▶ │   Login      │ ───▶ │  Dashboard/Home  │ ───▶ │   Logout     │
│ /signup/     │      │ /login/      │      │  /  (home view)  │      │  /logout/    │
└─────────────┘      └─────────────┘      └─────────────────┘      └─────────────┘
       │                     │                      │                      │
       ▼                     ▼                      ▼                      ▼
 creates CustomUser   authenticates user      shows logged-in        clears session,
 redirects to /login/  logs in, redirects     dashboard, shows       redirects to
                        to home (/)            "Login successful"    /login/, shows
                                                message here          "Logged out"
                                                                       message here
```

### 1. Sign Up (`/signup/`)

* Reads `username`, `full_name`, `email`, `bio`, `profile` (file), `password`, `password2` from the POST data.
* Rejects the submission (with a warning message, back on the signup page) if:
  * the username already exists, or
  * `password` and `password2` don't match.
* On success: creates the `CustomUser`, shows a success message, and **redirects to `/login/`** — it does not log the user in automatically. They sign in next.

### 2. Login (`/login/`)

* Authenticates `username`/`password` via Django's `authenticate()`.
* On success: logs the user in and **redirects to `home`** (the dashboard).
* On failure: shows a warning message and stays on `/login/`.

### 3. Dashboard / Home (`/`)

* Protected by `@login_required` — anonymous visitors get redirected to `/login/` automatically (this is what `LOGIN_URL = 'login'` in `settings.py` controls).
* Displays the logged-in user's name and a logout link.
* **Displays any queued messages** — this is the important part (see below).

### 4. Logout (`/logout/`)

* Logs the user out, queues a "Logged out successfully" message, and redirects to `/login/`.

### Why messages have to be displayed on *every* page in the chain

Django's messages framework doesn't push a message to a specific page — it
**queues** the message in the session, and the message only disappears once some
template actually loops over `{% if messages %}...{% endfor %}` and renders it.

If a page in the redirect chain never renders `{% if messages %}`, the message
isn't lost — it just sits in the queue and shows up on **whatever page renders
messages next**, which is why a "Login successful" message could previously show
up on the login page after a *later* logout, instead of on the dashboard right
after logging in.

That's why all three templates — `login.html`, `signup.html`, and
`myApp/index.html` (dashboard) — include the same block:

```django
{% if messages %}
    {% for message in messages %}
        <p class='msg'>{{ message }}</p>
    {% endfor %}
{% endif %}
```

This guarantees each message is consumed on the page it was meant for:

| Action  | Message               | Shown on        |
|---------|------------------------|------------------|
| Sign up | "Account created..."   | Login page       |
| Login   | "Login successful"     | Dashboard/Home   |
| Logout  | "Logged out successfully" | Login page    |

---

## Manual Setup (without the script)

```bash
python -m venv env
env\Scripts\Activate.ps1
pip install django djangorestframework pillow
django-admin startproject myProject .
python manage.py startapp myApp
```

Then manually:

1. Add `'myApp'` to `INSTALLED_APPS` in `settings.py`
2. Set `AUTH_USER_MODEL = 'myApp.CustomUser'` **before** running any migrations
3. Set `STATICFILES_DIRS`, `MEDIA_URL`, `MEDIA_ROOT`
4. Set `LOGIN_URL = 'login'`, `LOGIN_REDIRECT_URL = 'home'`, `LOGOUT_REDIRECT_URL = 'login'`
5. Write `models.py`, `views.py`, `admin.py`, `urls.py`, and the templates
6. Run:
   ```bash
   python manage.py makemigrations myApp
   python manage.py migrate
   python manage.py createsuperuser
   python manage.py runserver
   ```

> **Order matters.** `AUTH_USER_MODEL` and the `CustomUser` model must exist
> *before* the very first `migrate`. If you migrate first and switch the user
> model afterward, Django will have already built the `auth` tables against the
> default `User` model, and you'll need to delete the database and migrations to
> recover.

---

## Default Superuser

The script creates one automatically:

```text
username: admin
password: 1234
```

**Change this password** before doing anything beyond local testing —
it's hardcoded in the script for convenience, not security.

Access the admin panel at:

```text
http://127.0.0.1:8000/admin/
```

`CustomUser` is registered there with the extra `full_name`, `bio`, and
`profile` fields visible and editable.

---

## Django REST Framework

DRF is installed and added to `INSTALLED_APPS`, ready for you to add API views.
Example:

```python
from rest_framework.decorators import api_view
from rest_framework.response import Response

@api_view(['GET'])
def api_home(request):
    return Response({"message": "Hello from DRF"})
```

---

## Static & Media Files

```text
static/
└── css/
    └── style.css        Shared styling for login/signup/dashboard

media/
└── profiles/            Uploaded profile pictures (from signup)
```

Both are served automatically in development via `urls.py` when `DEBUG = True`.
In production you'd serve these through your web server (nginx, etc.) instead.

---

## Common Issues

### "running scripts is disabled on this system"

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

### "python is not recognized"

Reinstall Python and check **"Add Python to PATH"** during install, then verify:

```bash
python --version
```

### Profile picture upload does nothing

Make sure the signup form has `enctype='multipart/form-data'` — without it,
the browser submits the form without the file, and `req.FILES.get('profile')`
will always be `None`.

### A success/warning message shows up on the wrong page

Make sure every template in the login → dashboard → logout chain includes the
`{% if messages %}` block described above. A message only disappears once a
template actually renders it — otherwise it carries over to the next page that
does.

### `makemigrations` says "No changes detected" for the custom user model

This means `AUTH_USER_MODEL` wasn't set, or wasn't set *before* `migrate` ran
for the first time. Delete `db.sqlite3` and the contents of
`myApp/migrations/` (except `__init__.py`), confirm `AUTH_USER_MODEL` is set,
then re-run `makemigrations` and `migrate`.

---

## Future Improvements

* Form validation with Django Forms / ModelForms instead of raw `request.POST`
* Per-user task ownership checks (if extended into a task manager)
* `.env`-based configuration (`SECRET_KEY`, `DEBUG`) via `python-decouple`
* JWT authentication for the DRF API
* PostgreSQL support
* Docker support
* Production deployment configuration (`DEBUG=False`, `ALLOWED_HOSTS`, static file collection)

---

## License

MIT License — use freely for learning or as a starting point for your own projects.
