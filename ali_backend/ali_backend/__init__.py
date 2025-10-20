# ali_backend/__init__.py
import os

# Solo importa Celery si NO está desactivado por env var
if os.environ.get("DISABLE_CELERY_IMPORT", "0") not in ("1", "true", "True"):
    from .celery import app as celery_app  # noqa
