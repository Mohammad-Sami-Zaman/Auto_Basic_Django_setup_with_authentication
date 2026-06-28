param (
    [string]$RootFolder = "ProjectFolder",
    [string]$ProjectName = "myProject",
    [string]$AppName = "myApp"
)

# -----------------------------
# Step 1: Create root folder
# -----------------------------
Write-Host "Creating root folder..." -ForegroundColor Cyan
mkdir $RootFolder -ErrorAction SilentlyContinue
Set-Location $RootFolder

# -----------------------------
# Step 2: Create virtual environment
# -----------------------------
Write-Host "Creating virtual environment..." -ForegroundColor Cyan
python -m venv env

# -----------------------------
# Step 3: Activate virtual environment
# -----------------------------
Write-Host "Activating virtual environment..." -ForegroundColor Cyan
& "$PWD\env\Scripts\Activate.ps1"

# -----------------------------
# Step 4: Install Django, DRF & Pillow (Pillow is required for ImageField)
# -----------------------------
Write-Host "Installing Django, DRF & Pillow..." -ForegroundColor Cyan
pip install django djangorestframework pillow

# -----------------------------
# Step 5: Create Django project in outer folder
# -----------------------------
Write-Host "Creating Django project..." -ForegroundColor Cyan
django-admin startproject $ProjectName .

# -----------------------------
# Step 6: Adjust folder structure & create app
# -----------------------------
Write-Host "Creating app and static folder..." -ForegroundColor Cyan
mkdir static
python manage.py startapp $AppName

# -----------------------------
# Step 7: Create templates and static subfolders
# -----------------------------
Write-Host "Creating templates and static folders..." -ForegroundColor Cyan
"static\css","static\js","static\images","$AppName\templates","$AppName\templates\$AppName" | ForEach-Object { mkdir $_ -ErrorAction SilentlyContinue }

# -----------------------------
# Step 8: Create simple CSS
# -----------------------------
Write-Host "Creating CSS..." -ForegroundColor Cyan
@"
body { font-family: Arial, sans-serif; background:#0879eb; }
.container { width:500px; margin:60px auto; background:white; padding:20px; border-radius:6px; box-shadow:0 0 15px rgba(0,0,0,.1); text-align:center; }
input, textarea { width:90%; padding:8px; margin:6px 0; border:1px solid #ccc; border-radius:4px; }
button { padding:8px 20px; border:none; background:#0879eb; color:white; border-radius:4px; cursor:pointer; }
button:hover { background:#065fb8; }
.msg { padding:8px; border-radius:4px; background:#eef6ff; margin:8px 0; }
a { color:#0879eb; text-decoration:none; }
"@ | Set-Content "static\css\style.css"

# -----------------------------
# Step 9: Create home page template (login required)
# -----------------------------
Write-Host "Creating home page template..." -ForegroundColor Cyan
@"
{% load static %}
<!DOCTYPE html>
<html>
<head>
    <title>Home</title>
    <link rel='stylesheet' href='{% static "css/style.css" %}'>
</head>
<body>
<div class='container'>
    <h2>Welcome, {{ request.user.full_name|default:request.user.username }}</h2>
    <p>This is your basic Django setup with login/signup!</p>
    <a href='{% url "logout" %}'>Logout</a>
</div>
</body>
</html>
"@ | Set-Content "$AppName\templates\$AppName\index.html"

# -----------------------------
# Step 10: Create login template
# -----------------------------
Write-Host "Creating login template..." -ForegroundColor Cyan
@"
{% load static %}
<!DOCTYPE html>
<html>
<head>
    <title>Login</title>
    <link rel='stylesheet' href='{% static "css/style.css" %}'>
</head>
<body>
<div class='container'>
    <h2>Login</h2>
    {% if messages %}
        {% for message in messages %}
            <p class='msg'>{{ message }}</p>
        {% endfor %}
    {% endif %}
    <form method='post'>
        {% csrf_token %}
        <input type='text' name='username' placeholder='Username' required><br>
        <input type='password' name='password' placeholder='Password' required><br>
        <button type='submit'>Login</button>
    </form>
    <p>Don't have an account? <a href='{% url "signup" %}'>Sign up</a></p>
</div>
</body>
</html>
"@ | Set-Content "$AppName\templates\login.html"

# -----------------------------
# Step 11: Create signup template
# -----------------------------
Write-Host "Creating signup template..." -ForegroundColor Cyan
@"
{% load static %}
<!DOCTYPE html>
<html>
<head>
    <title>Sign Up</title>
    <link rel='stylesheet' href='{% static "css/style.css" %}'>
</head>
<body>
<div class='container'>
    <h2>Sign Up</h2>
    {% if messages %}
        {% for message in messages %}
            <p class='msg'>{{ message }}</p>
        {% endfor %}
    {% endif %}
    <form method='post' enctype='multipart/form-data'>
        {% csrf_token %}
        <input type='text' name='username' placeholder='Username' required><br>
        <input type='text' name='full_name' placeholder='Full Name'><br>
        <input type='email' name='email' placeholder='Email'><br>
        <textarea name='bio' placeholder='Bio' rows='3'></textarea><br>
        <input type='file' name='profile'><br>
        <input type='password' name='password' placeholder='Password' required><br>
        <input type='password' name='password2' placeholder='Confirm Password' required><br>
        <button type='submit'>Sign Up</button>
    </form>
    <p>Already have an account? <a href='{% url "login" %}'>Login</a></p>
</div>
</body>
</html>
"@ | Set-Content "$AppName\templates\signup.html"

# -----------------------------
# Step 12: Create models.py with CustomUser
# -----------------------------
Write-Host "Creating models.py with CustomUser..." -ForegroundColor Cyan
@"
from django.db import models
from django.contrib.auth.models import AbstractUser


class CustomUser(AbstractUser):
    full_name = models.CharField(max_length=100, null=True, blank=True)
    bio = models.TextField(null=True, blank=True)
    profile = models.ImageField(upload_to='profiles', null=True, blank=True)

    def __str__(self):
        return self.username
"@ | Set-Content "$AppName\models.py"

# -----------------------------
# Step 13: Update settings.py
# -----------------------------
Write-Host "Updating settings.py..." -ForegroundColor Cyan
$settingsPath = "$ProjectName\settings.py"

# Add app to INSTALLED_APPS
(Get-Content $settingsPath) -replace "INSTALLED_APPS = \[", "INSTALLED_APPS = [`n    '$AppName'," | Set-Content $settingsPath

# Add templates DIRS
$settingsContent = Get-Content $settingsPath -Raw
if ($settingsContent -notmatch "BASE_DIR / '$AppName' / 'templates'") {
    $settingsContent = $settingsContent -replace "'DIRS': \[\],", "'DIRS': [BASE_DIR / '$AppName' / 'templates'],"
    Set-Content -Path $settingsPath -Value $settingsContent
}

# Add STATICFILES_DIRS, custom user model, media config, and auth redirects
$settingsContent = Get-Content $settingsPath -Raw
if ($settingsContent -notmatch "STATICFILES_DIRS") {
    Add-Content $settingsPath @"

STATICFILES_DIRS = [ BASE_DIR / 'static' ]

MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

AUTH_USER_MODEL = '$AppName.CustomUser'

LOGIN_URL = 'login'
LOGIN_REDIRECT_URL = 'home'
LOGOUT_REDIRECT_URL = 'login'
"@
}

# -----------------------------
# Step 14: Update urls.py
# -----------------------------
Write-Host "Updating urls.py..." -ForegroundColor Cyan
$urlsPath = "$ProjectName\urls.py"

@"
from django.contrib import admin
from django.urls import path
from django.conf import settings
from django.conf.urls.static import static
from $AppName.views import home, login_page, signup_page, logout_page

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', home, name='home'),
    path('login/', login_page, name='login'),
    path('signup/', signup_page, name='signup'),
    path('logout/', logout_page, name='logout'),
]

# Serve static & media files during development
if settings.DEBUG:
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATICFILES_DIRS[0])
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
"@ | Set-Content $urlsPath

# -----------------------------
# Step 15: Create views.py (login, signup, logout, home)
# -----------------------------
Write-Host "Creating views.py..." -ForegroundColor Cyan
@"
from django.shortcuts import render, redirect
from django.contrib.auth import login, logout, authenticate
from django.contrib import messages
from django.contrib.auth.decorators import login_required
from $AppName.models import CustomUser


def login_page(req):
    if req.method == 'POST':
        username = req.POST.get('username')
        password = req.POST.get('password')

        user = authenticate(req, username=username, password=password)

        if user:
            login(req, user)
            messages.success(req, 'Login successful')
            return redirect('home')
        else:
            messages.warning(req, 'Invalid username or password')
            return redirect('login')

    return render(req, 'login.html')


def signup_page(req):
    if req.method == 'POST':
        username = req.POST.get('username')
        full_name = req.POST.get('full_name')
        bio = req.POST.get('bio')
        profile = req.FILES.get('profile')
        email = req.POST.get('email')
        password = req.POST.get('password')
        password2 = req.POST.get('password2')

        if CustomUser.objects.filter(username=username).exists():
            messages.warning(req, 'Username already exists')
            return redirect('signup')

        if password != password2:
            messages.warning(req, 'Passwords do not match')
            return redirect('signup')

        CustomUser.objects.create_user(
            username=username,
            full_name=full_name,
            bio=bio,
            profile=profile,
            email=email,
            password=password,
        )
        messages.success(req, 'Account created successfully')
        return redirect('login')

    return render(req, 'signup.html')


@login_required
def home(request):
    return render(request, '$AppName/index.html')


@login_required
def logout_page(req):
    logout(req)
    messages.success(req, 'Logged out successfully')
    return redirect('login')
"@ | Set-Content "$AppName\views.py"

# -----------------------------
# Step 16: Register CustomUser in admin.py
# -----------------------------
Write-Host "Updating admin.py..." -ForegroundColor Cyan
@"
from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from $AppName.models import CustomUser


class CustomUserAdmin(UserAdmin):
    fieldsets = UserAdmin.fieldsets + (
        ('Extra Info', {'fields': ('full_name', 'bio', 'profile')}),
    )
    list_display = ('username', 'email', 'full_name', 'is_staff')


admin.site.register(CustomUser, CustomUserAdmin)
"@ | Set-Content "$AppName\admin.py"

# -----------------------------
# Step 17: Make migrations & migrate
# -----------------------------
# IMPORTANT: AUTH_USER_MODEL and CustomUser must exist BEFORE the first
# migrate, otherwise Django builds the auth tables against the default
# User model and the project breaks. makemigrations must run first since
# startapp only creates an empty migrations/ folder.
Write-Host "Making migrations..." -ForegroundColor Cyan
python manage.py makemigrations $AppName

Write-Host "Running migrations..." -ForegroundColor Cyan
python manage.py migrate

# -----------------------------
# Step 18: Create .gitignore
# -----------------------------
@"
env/
__pycache__/
*.pyc
db.sqlite3
.env
media/
"@ | Set-Content .gitignore

# -----------------------------
# Step 19: Save requirements
# -----------------------------
pip freeze > requirements.txt

# -----------------------------
# Step 20: Create superuser
# -----------------------------
Write-Host "Creating Django superuser..." -ForegroundColor Cyan

$superuserScript = @"
import os
import django
from django.contrib.auth import get_user_model

os.environ.setdefault('DJANGO_SETTINGS_MODULE', '$ProjectName.settings')
django.setup()

User = get_user_model()

if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@example.com', '1234')
    print('Superuser created: username=admin, password=1234')
else:
    print('Superuser already exists')
"@

$superuserScript | Set-Content "create_superuser.py"
python create_superuser.py
Remove-Item "create_superuser.py"

# -----------------------------
# Step 21: Run server
# -----------------------------
Write-Host "`n[DONE] Django project with login/signup setup complete!" -ForegroundColor Green
Write-Host "Visit http://127.0.0.1:8000/login/ to sign in, or http://127.0.0.1:8000/signup/ to create an account." -ForegroundColor Yellow
Start-Process "http://127.0.0.1:8000/login/"
python manage.py runserver
