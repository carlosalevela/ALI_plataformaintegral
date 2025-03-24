from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import TestGrado10_11ViewSet

router = DefaultRouter()
router.register(r'', TestGrado10_11ViewSet, basename='testgrado10_11')

urlpatterns = [
    path('', include(router.urls)),  # Incluye las rutas generadas por el router
]
