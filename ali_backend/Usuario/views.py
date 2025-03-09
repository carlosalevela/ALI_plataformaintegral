from django.shortcuts import render
from django.shortcuts import get_object_or_404
from rest_framework.permissions import IsAuthenticated
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
import json
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from Usuario.models import Usuario
from Usuario.serializers import UsuarioSerializer


# Create your views here.
class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token['rol'] = user.rol  # Agregar campo extra al token
        return token

class LoginAPI(TokenObtainPairView):
    serializer_class = CustomTokenObtainPairSerializer


class UsuarioAPI(APIView):
    permission_classes = [permissions.IsAuthenticated]  # 🔒 Requiere autenticación

    # 📌 OBTENER TODOS LOS USUARIOS (Solo Admins)
    def get(self, request, *args, **kwargs):
        if request.user.rol != "admin":
            return Response({"error": "Acceso denegado"}, status=status.HTTP_403_FORBIDDEN)

        usuarios = Usuario.objects.all()
        serializador = UsuarioSerializer(usuarios, many=True)
        return Response(serializador.data, status=status.HTTP_200_OK)

    # 📌 REGISTRO DE USUARIOS (Estudiantes y Admins)
    permission_classes = [permissions.AllowAny]  # 🔓 Registro sin autenticación
    def post(self, request, *args, **kwargs):
        data = {
            'username': request.data.get('username'),
            'nombre': request.data.get('nombre'),
            'email': request.data.get('email'),
            'rol': request.data.get('rol', 'estudiante'),
            'grado': request.data.get('grado'),
            'edad': request.data.get('edad'),
            'password': request.data.get('password'),
        }

        serializador = UsuarioSerializer(data=data)
        if serializador.is_valid():
            usuario = serializador.save()
            usuario.set_password(data['password'])
            usuario.save()
            return Response(serializador.data, status=status.HTTP_201_CREATED)
        return Response(serializador.errors, status=status.HTTP_400_BAD_REQUEST)


class UsuarioDetailAPI(APIView):
    permission_classes = [IsAuthenticated]  # 🔒 Requiere autenticación

    # 📌 OBTENER DETALLES DE UN USUARIO POR ID
    def get(self, request, pkid, *args, **kwargs):
        usuario = get_object_or_404(Usuario, id=pkid)
        serializador = UsuarioSerializer(usuario)
        return Response(serializador.data, status=status.HTTP_200_OK)

    # 📌 EDITAR UN USUARIO (Solo Admins o el Propietario)
    def put(self, request, pkid):
        usuario = get_object_or_404(Usuario, id=pkid)

        if request.user.rol != "admin" and request.user.id != usuario.id:
            return Response({"error": "No tienes permiso para editar este usuario"}, status=status.HTTP_403_FORBIDDEN)

        serializador = UsuarioSerializer(usuario, data=request.data, partial=True)
        if serializador.is_valid():
            serializador.save()
            return Response(serializador.data, status=status.HTTP_200_OK)
        return Response(serializador.errors, status=status.HTTP_400_BAD_REQUEST)

    # 📌 ELIMINAR UN USUARIO (Solo Admins)
    def delete(self, request, pkid):
        usuario = get_object_or_404(Usuario, id=pkid)

        if request.user.rol != "admin":
            return Response({"error": "No tienes permiso para eliminar usuarios"}, status=status.HTTP_403_FORBIDDEN)

        usuario.delete()
        return Response({"message": "Usuario eliminado"}, status=status.HTTP_200_OK)