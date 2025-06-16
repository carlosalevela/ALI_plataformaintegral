from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import TestGrado9ViewSet,ResultadoTest9PorIDView,TestsDeUsuarioPorAdminView


router = DefaultRouter()
router.register(r'', TestGrado9ViewSet, basename='test_grado9')

urlpatterns = [
    path('', include(router.urls)),  
    path('resultado/<int:test_id>/', ResultadoTest9PorIDView.as_view(), name='resultado_test_9'),
    path('usuario/<int:user_id>/', TestsDeUsuarioPorAdminView.as_view(), name='tests_por_usuario_admin'),
]
