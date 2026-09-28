# Script de démarrage rapide — TrustLand (développement local, SQLite)
# Usage : .\dev.ps1          -> lance le serveur
#         .\dev.ps1 migrate  -> applique les migrations
#         .\dev.ps1 admin    -> crée le compte admin

$env:DJANGO_SETTINGS_MODULE = "config.settings_dev"
$env:PYTHONUTF8 = "1"

$venv = ".\venv\Scripts\python.exe"

switch ($args[0]) {
    "migrate" {
        & $venv manage.py migrate
    }
    "admin" {
        & $venv manage.py createadmin --username=admin --email=admin@trustland.tg --password=Admin1234!
    }
    "makemigrations" {
        & $venv manage.py makemigrations
    }
    "shell" {
        & $venv manage.py shell
    }
    default {
        # Appliquer les migrations si nécessaire, puis lancer le serveur
        & $venv manage.py migrate --run-syncdb
        & $venv manage.py runserver 0.0.0.0:8000
    }
}
