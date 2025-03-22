from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import TestGrado9ViewSet

router = DefaultRouter()
router.register(r'tests', TestGrado9ViewSet, basename='test-grado9')

urlpatterns = [
    path('', include(router.urls)),  # Incluye las rutas generadas por el router
]
