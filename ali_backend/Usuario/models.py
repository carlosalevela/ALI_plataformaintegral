# models.py
from django.db import models
from django.contrib.auth.models import AbstractUser, BaseUserManager, Group, Permission

class UsuarioManager(BaseUserManager):
    def create_user(self, email, username, password=None, **extra_fields):
        if not email:
            raise ValueError("El email es obligatorio")
        email = self.normalize_email(email)
        extra_fields.setdefault("rol", "estudiante")
        user = self.model(email=email, username=username, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, username, password=None, **extra_fields):
        extra_fields.setdefault("rol", "admin")
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)
        return self.create_user(email, username, password, **extra_fields)

class Grade(models.Model):
    code = models.CharField(max_length=10)       # "9","10","11"
    section = models.CharField(max_length=20)    # "A","B","11-3"
    shift = models.CharField(max_length=20, blank=True, default="")
    capacity = models.PositiveIntegerField(default=0)
    is_active = models.BooleanField(default=True)

    class Meta:
        unique_together = ("code", "section")
        ordering = ["code", "section"]

    def __str__(self):
        sec = f"-{self.section}" if self.section else ""
        return f"{self.code}{sec}"

class Usuario(AbstractUser):
    nombre = models.CharField(max_length=100)
    email = models.EmailField(unique=True)
    rol = models.CharField(
        max_length=20,
        choices=[("admin", "Admin"), ("estudiante", "Estudiante")],
        default="estudiante"
    )
    # 🔵 Tu lógica actual (la mantenemos): 9 / 10 / 11
    grado = models.IntegerField(null=True, blank=True)

    # 🟣 NUEVO opcional (no rompe nada): link “rico” al grado administrable
    grade_ref = models.ForeignKey(
        Grade, null=True, blank=True, on_delete=models.SET_NULL, related_name="usuarios"
    )

    edad = models.IntegerField(null=True, blank=True)

    groups = models.ManyToManyField(Group, related_name="usuario_groups", blank=True)
    user_permissions = models.ManyToManyField(Permission, related_name="usuario_permissions", blank=True)

    objects = UsuarioManager()

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["username"]

    def __str__(self):
        return self.email
