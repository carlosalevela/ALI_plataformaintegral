from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import TestGrado9ViewSet

router = DefaultRouter()
router.register(r'', TestGrado9ViewSet, basename='test_grado9')

urlpatterns = [
    path('', include(router.urls)),  
]
