from django.urls import path
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
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
    path('login/', LoginAPI.as_view(), name='login'),

    path('registro/', UsuarioAPI.as_view(), name='registro'),

    # 📌 Refrescar token
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),

    # 📌 Obtener todos los usuarios (Solo Admins)
    path('usuarios/', UsuarioAPI.as_view(), name='lista_usuarios'),

    # 📌 Obtener, editar o eliminar un usuario por ID
    path('usuarios/<int:pkid>/', UsuarioDetailAPI.as_view(), name='detalle_usuario'),

    # ===== GRADOS =====
    # GET (auth) / POST (admin) -> /Alipsicoorientadora/grados/
    path('grados/', GradesAPI.as_view(), name='grados'),

    # GET (auth) / PUT/DELETE (admin) -> /Alipsicoorientadora/grados/<id>/
    path('grados/<int:pkid>/', GradeDetailAPI.as_view(), name='grado-detail'),
]
