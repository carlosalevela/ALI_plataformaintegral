from rest_framework import viewsets, status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import TestGrado9
from .serializers import TestGrado9Serializer

class TestGrado9ViewSet(viewsets.ModelViewSet):
    """
    API para gestionar los tests de grado 9.
    """
    queryset = TestGrado9.objects.all()
    serializer_class = TestGrado9Serializer
    permission_classes = [IsAuthenticated]  # Solo usuarios autenticados pueden acceder

    def perform_create(self, serializer):
        """
        Asigna automáticamente el usuario autenticado al test.
        """
        serializer.save(usuario=self.request.user)

    def get_queryset(self):
        """
        Devuelve solo los tests del usuario autenticado.
        Si es admin, devuelve todos los tests.
        """
        user = self.request.user
        if user.rol == "admin":
            return TestGrado9.objects.all()
        return TestGrado9.objects.filter(usuario=user)

    def update(self, request, *args, **kwargs):
        """
        Evita que los usuarios actualicen manualmente los resultados.
        """
        test = self.get_object()
        data = request.data.copy()
        if "resultado" in data:
            data.pop("resultado")  # Bloquea cambios en resultado
        serializer = self.get_serializer(test, data=data, partial=True)
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)
        return Response(serializer.data, status=status.HTTP_200_OK)
