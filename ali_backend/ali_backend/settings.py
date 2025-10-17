"""
Django settings for ali_backend project.
"""

from pathlib import Path
from datetime import timedelta
import os
from decouple import config
import dj_database_url

# ========= Paths =========
BASE_DIR = Path(__file__).resolve().parent.parent

# ========= Core =========
SECRET_KEY = config('SECRET_KEY', default='dev-secret-please-change')
DEBUG = config('DEBUG', default=False, cast=bool)

ALLOWED_HOSTS = [
    "localhost",
    "127.0.0.1",
    "testserver",
    "ali-deabhkdga2beawgc.brazilsouth-01.azurewebsites.net",
    ".azurewebsites.net",
]

CSRF_TRUSTED_ORIGINS = [
    "https://ali-deabhkdga2beawgc.brazilsouth-01.azurewebsites.net",
    "https://*.azurewebsites.net",
]

# ========= Apps =========
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',

    # Terceros
    'rest_framework',
    'rest_framework.authtoken',
    'rest_framework_simplejwt',
    'django_extensions',
    'django_celery_beat',
    'corsheaders',

    # Propios
    'Usuario',
    'test_grado9',
    'test_grado_10_11',
]
AUTH_USER_MODEL = 'Usuario.Usuario'

# ========= DRF / JWT =========
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ),
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
}
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(days=1),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
}

# ========= Middleware =========
MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',

    # CORS y estáticos deben ir arriba
    'corsheaders.middleware.CorsMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',

    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

CORS_ALLOW_ALL_ORIGINS = True  # en prod ideal: lista explícita

ROOT_URLCONF = 'ali_backend.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'ali_backend.wsgi.application'

# ========= Database =========
# 1) Producción por DATABASE_URL (recomendado)
#    Formato: postgres://USER:PASSWORD@ali-server-f.postgres.database.azure.com:5432/DB?sslmode=require
db_from_url = dj_database_url.config(
    env="DATABASE_URL",
    default=None,
    conn_max_age=600,
    ssl_require=True,
)

if db_from_url:
    DATABASES = {'default': db_from_url}
else:
    # 2) Alternativa: variables separadas (útil si no quieres DATABASE_URL)
    DB_NAME = config('DB_NAME', default='bd_ali')
    DB_USER = config('DB_USER', default='postgres')  # en Azure suele ser "usuario@ali-server-f"
    DB_PASSWORD = config('DB_PASSWORD', default='')
    DB_HOST = config('DB_HOST', default='ali-server-f.postgres.database.azure.com')
    DB_PORT = config('DB_PORT', default='5432')

    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.postgresql',
            'NAME': DB_NAME,
            'USER': DB_USER,
            'PASSWORD': DB_PASSWORD,
            'HOST': DB_HOST,
            'PORT': DB_PORT,
            'OPTIONS': {
                'sslmode': 'require',
            },
        }
    }

# ========= Passwords =========
AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

# ========= I18N / TZ =========
LANGUAGE_CODE = 'es-co'
TIME_ZONE = 'America/Bogota'
USE_I18N = True
USE_TZ = True

# ========= Static / WhiteNoise =========
STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'
WHITENOISE_MAX_AGE = 31536000  # cache largo para assets con hash

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# ========= Celery =========
CELERY_BROKER_URL = config('CELERY_BROKER_URL', default='redis://localhost:6379')
CELERY_ACCEPT_CONTENT = ['json']
CELERY_TASK_SERIALIZER = 'json'

# ========= Email / Reset =========
EMAIL_BACKEND = config('EMAIL_BACKEND', default='django.core.mail.backends.smtp.EmailBackend')
EMAIL_HOST = config('EMAIL_HOST', default='smtp.gmail.com')
EMAIL_PORT = config('EMAIL_PORT', default=587, cast=int)
EMAIL_USE_TLS = config('EMAIL_USE_TLS', default=True, cast=bool)
EMAIL_USE_SSL = False
EMAIL_HOST_USER = config('EMAIL_HOST_USER', default='aliorientadora@gmail.com')
EMAIL_HOST_PASSWORD = config('EMAIL_HOST_PASSWORD', default='')
DEFAULT_FROM_EMAIL = config('DEFAULT_FROM_EMAIL', default='ALI Soporte <no-reply@tu-dominio.com>')

SITE_DOMAIN = config('SITE_DOMAIN', default='ali-deabhkdga2beawgc.brazilsouth-01.azurewebsites.net')
FRONTEND_RESET_URL = config('FRONTEND_RESET_URL', default='')
PASSWORD_RESET_TIMEOUT = config('PASSWORD_RESET_TIMEOUT', default=86400, cast=int)
FRONTEND_RESET_PATH = "/recuperacion/contrasena-confirmada"

# ========= Proxy/HTTPS (Azure) =========
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
USE_X_FORWARDED_HOST = True

# ========= Extras (opcional) =========
GROQ_API_KEY = config('GROQ_API_KEY', default='')
