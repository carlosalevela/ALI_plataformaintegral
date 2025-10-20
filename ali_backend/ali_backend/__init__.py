import os

if not os.environ.get('DISABLE_CELERY_IMPORT'):
    try:
        from .celery import app as celery_app  # noqa
    except Exception:
        # Evita tumbar la web si Celery no está en el contenedor
        celery_app = None
