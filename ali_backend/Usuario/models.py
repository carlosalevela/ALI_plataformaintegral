from django.db import models
from django.contrib.auth.models import AbstractUser, BaseUserManager, Group, Permission

# Manager personalizado para el modelo Usuario
class UsuarioManager(BaseUserManager):
    def create_user(self, email, username, password=None, **extra_fields):
        if not email:
            raise ValueError("El email es obligatorio")
        email = self.normalize_email(email)
        extra_fields.setdefault("rol", "estudiante")  # Valor por defecto: estudiante
        user = self.model(email=email, username=username, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, username, password=None, **extra_fields):
        extra_fields.setdefault("rol", "admin")  # 🚀 Superusuarios serán admin
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)

        return self.create_user(email, username, password, **extra_fields)

# Modelo de Usuario personalizado
class Usuario(AbstractUser):
    nombre = models.CharField(max_length=100)
    email = models.EmailField(unique=True)
    rol = models.CharField(
        max_length=20,
        choices=[("admin", "Admin"), ("estudiante", "Estudiante")],
        default="estudiante"
    )
    grado = models.IntegerField(null=True, blank=True)
    edad = models.IntegerField(null=True, blank=True)

    groups = models.ManyToManyField(Group, related_name="usuario_groups", blank=True)
    user_permissions = models.ManyToManyField(Permission, related_name="usuario_permissions", blank=True)

    objects = UsuarioManager()  # Usar el nuevo manager

    USERNAME_FIELD = "email"  # Usar email en lugar de username para autenticación
    REQUIRED_FIELDS = ["username"]  # username sigue siendo obligatorio

    def __str__(self):
        return self.email
