"""
Settings de développement local — SQLite, pas de PostgreSQL requis.
Usage :
    python manage.py runserver  --settings=config.settings_dev
    python manage.py migrate    --settings=config.settings_dev
    python manage.py makemigrations --settings=config.settings_dev

Ou bien, définir la variable d'environnement une seule fois dans le terminal :
    $env:DJANGO_SETTINGS_MODULE = "config.settings_dev"   # PowerShell
    set DJANGO_SETTINGS_MODULE=config.settings_dev         # cmd.exe
"""

from .settings import *  # noqa: F401, F403
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db_dev.sqlite3',
    }
}

DEBUG = True

# En développement SQLite, les throttles ralentissent les tests manuels
REST_FRAMEWORK['DEFAULT_THROTTLE_RATES'] = {  # noqa: F405
    'anon':        '1000/minute',
    'user':        '1000/minute',
    'login':       '1000/minute',
    'transaction': '1000/hour',
    'auth':        '1000/minute',
}

# Logs en console uniquement (pas de fichier tournant)
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
            'formatter': 'verbose',
        },
    },
    'formatters': {
        'verbose': {
            'format': '%(asctime)s [%(levelname)s] %(name)s: %(message)s',
        },
    },
    'loggers': {
        'trustland.security': {
            'handlers': ['console'],
            'level': 'INFO',
            'propagate': False,
        },
    },
}
