from django.urls import path
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from .views import UsuarioAPI, UsuarioDetailAPI, LoginAPI

urlpatterns = [
    # 📌 Registrar usuario
    path('registro/', UsuarioAPI.as_view(), name='registro'),

    # 📌 Login (obtener token JWT)
    path('login/', LoginAPI.as_view(), name='login'),

    # 📌 Refrescar token
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),

    # 📌 Obtener todos los usuarios (Solo Admins)
    path('usuarios/', UsuarioAPI.as_view(), name='lista_usuarios'),

    # 📌 Obtener, editar o eliminar un usuario por ID
    path('usuarios/<int:pkid>/', UsuarioDetailAPI.as_view(), name='detalle_usuario'),
]