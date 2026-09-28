"""
Settings de test — remplace PostgreSQL par SQLite en mémoire.
Usage : python manage.py test --settings=config.settings_test
"""

from .settings import *  # noqa: F401, F403

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': ':memory:',
    }
}

# Désactiver les throttles pour les tests (garder les rates pour éviter KeyError)
REST_FRAMEWORK['DEFAULT_THROTTLE_CLASSES'] = []  # noqa: F405
REST_FRAMEWORK['DEFAULT_THROTTLE_RATES'] = {     # noqa: F405
    'anon': '10000/minute',
    'user': '10000/minute',
    'login': '10000/minute',
    'transaction': '10000/hour',
    'auth': '10000/minute',
}

# Pas de fichiers de log en tests
LOGGING = {
    'version': 1,
    'disable_existing_loggers': True,
    'handlers': {
        'null': {'class': 'logging.NullHandler'},
    },
    'root': {'handlers': ['null']},
}

# Accélérer le hachage des mots de passe en tests
PASSWORD_HASHERS = [
    'django.contrib.auth.hashers.MD5PasswordHasher',
]

# Clé de chiffrement fixe pour les tests (ne pas utiliser en production)
FIELD_ENCRYPTION_KEY = 'ShIkKjAWFipeR2BvSro18zVKPt9lrvfhEO-bHg-KLB0='
SECRET_KEY = 'test-secret-key-non-securisee-uniquement-pour-tests'
DEBUG = True
