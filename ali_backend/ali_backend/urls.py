"""
URL configuration for ali_backend project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.1/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path, include
from Usuario import urls as urls_usuarios
from test_grado9 import urls as urls_tests_grado9
from test_grado_10_11 import urls as urls_tests_grado10_11  

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/usuarios/', include(urls_usuarios)),
    path('api/tests-grado9/', include(urls_tests_grado9)),
    path('api/tests-grado10-11/', include(urls_tests_grado10_11)),  


]
