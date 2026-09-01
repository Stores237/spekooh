from .base import *

DEBUG = True
# "*" so a real phone on the same Wi-Fi/LAN as this dev machine can reach the
# API by its LAN IP (Django checks the incoming Host header against this
# list) — safe here since DEBUG is already True and this settings module is
# never used outside local dev.
ALLOWED_HOSTS = ["*"]

EMAIL_BACKEND = "django.core.mail.backends.console.EmailBackend"
