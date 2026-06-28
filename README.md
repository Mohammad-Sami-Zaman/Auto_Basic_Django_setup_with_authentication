# Django Project Generator (SETUP.ps1)

A single PowerShell script that scaffolds a full Django project: venv, dependencies,
project + app, auth (signup/login/logout/dashboard/profile), a small DRF API,
Bootstrap templates, static/media handling, `.env` config, and migrations.

## Requirements

- Windows with PowerShell
- Python 3.10+ on your PATH

## Usage

1. Create an empty folder for your project and put `SETUP.ps1` inside it.
2. Open PowerShell in that folder.
3. If scripts are blocked, allow this one for the session:
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   ```
4. Run it:
   ```powershell
   .\SETUP.ps1
   ```
   Or customize the names and behavior:
   ```powershell
   .\SETUP.ps1 -ProjectName CoreProject -AppName accounts -CreateSuperuser -RunServer
   ```

## Parameters

| Parameter          | Default     | Description                                  |
|--------------------|-------------|-----------------------------------------------|
| `-ProjectName`      | `myProject` | Django project (settings module) name         |
| `-AppName`          | `myApp`     | Django app name                                |
| `-EnvName`          | `env`       | Virtual environment folder name                |
| `-CreateSuperuser`  | off         | Prompts to create a Django admin user          |
| `-RunServer`        | off         | Starts `manage.py runserver` after setup       |

## What gets generated

See the generated project's own `README.md` after running the script — it documents
the routes, layout, and next steps for that specific project.

Re-running the script is mostly safe: it skips `startproject`/`startapp` if they
already exist, and overwrites the generated `.py`/`.html`/`.css`/`.js` files with
fresh versions, so you can tweak the script and re-run to regenerate the boilerplate.
