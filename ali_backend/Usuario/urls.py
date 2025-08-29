from django.urls import path
from .views import (
    LoginAPI,
    UsuarioAPI,
    UsuarioDetailAPI,
    GradesAPI,
    GradeDetailAPI,
)

urlpatterns = [
    # ===== AUTH (JWT) =====
    # POST -> /Alipsicoorientadora/usuarios/login/
    path('usuarios/login/', LoginAPI.as_view(), name='login'),

    # ===== USUARIOS =====
    # GET  (solo admin)  -> /Alipsicoorientadora/usuarios/usuarios/
    # POST (registro)    -> /Alipsicoorientadora/usuarios/usuarios/
    path('usuarios/usuarios/', UsuarioAPI.as_view(), name='usuarios'),

    # GET/PUT/DELETE -> /Alipsicoorientadora/usuarios/usuarios/<id>/
    path('usuarios/usuarios/<int:pkid>/', UsuarioDetailAPI.as_view(), name='usuario-detail'),

    # ===== GRADOS =====
    # GET (auth) / POST (admin) -> /Alipsicoorientadora/grados/
    path('grados/', GradesAPI.as_view(), name='grados'),

    # GET (auth) / PUT/DELETE (admin) -> /Alipsicoorientadora/grados/<id>/
    path('grados/<int:pkid>/', GradeDetailAPI.as_view(), name='grado-detail'),
]
