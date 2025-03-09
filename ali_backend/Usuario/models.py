from django.db import models
from django.contrib.auth.models import AbstractUser, Group, Permission

#Clase de usuario el cual separa estudiante y administrativo.
class Usuario(AbstractUser):
    nombre = models.CharField(max_length=100)
    email = models.EmailField(unique=True)
    rol = models.CharField(max_length=20, choices=[("admin", "Admin"), ("estudiante", "Estudiante")], default="estudiante")
    grado = models.IntegerField(null=True, blank=True)
    edad = models.IntegerField(null=True, blank=True)

    groups = models.ManyToManyField(Group, related_name="usuario_groups", blank=True)
    user_permissions = models.ManyToManyField(Permission, related_name="usuario_permissions", blank=True)

    def __str__(self):
        return self.username
