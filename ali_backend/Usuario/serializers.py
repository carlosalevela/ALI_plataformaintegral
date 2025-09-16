from rest_framework import serializers
from Usuario.models import Usuario, Grade

# 👇 para admins (respuesta “rica”)
class GradeSerializerMini(serializers.ModelSerializer):
    class Meta:
        model = Grade
        fields = ("id", "code", "section", "shift", "capacity", "is_active")

# 👇 para estudiantes (respuesta pública, sin capacidad/shift)
class PublicGradeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Grade
        fields = ("id", "code", "section")


class UsuarioSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True)

    # 🔵 soporte para asignar un grado existente por id
    grade_ref = GradeSerializerMini(read_only=True)  # read-only (si eres admin lo verás completo en endpoints de usuario)
    grade_ref_id = serializers.PrimaryKeyRelatedField(
        source="grade_ref",
        queryset=Grade.objects.all(),
        write_only=True,
        required=False,
        allow_null=True,
    )

    class Meta:
        model = Usuario
        fields = (
            "id", "username", "nombre", "email", "rol",
            "grado", "edad", "password",
            "grade_ref", "grade_ref_id",
        )
        extra_kwargs = {"password": {"write_only": True}}

    def validate_grado(self, value):
        if value is None:
            return value
        if value not in [9, 10, 11]:
            raise serializers.ValidationError("El grado debe ser 9, 10 o 11.")
        return value

    def validate(self, attrs):
        """
        Reglas:
        - Si viene grade_ref_id, debe referir a un Grade is_active=True.
        - Si también viene 'grado', debe coincidir con Grade.code (cuando sea numérico).
        - Un estudiante no puede forzar un grado inactivo.
        """
        request = self.context.get("request")
        grade_obj = attrs.get("grade_ref", None)
        grado_int = attrs.get("grado", None)

        if grade_obj:
            # Debe estar activo
            if not grade_obj.is_active:
                raise serializers.ValidationError({"grade_ref_id": "El grado seleccionado no está activo."})

            # Si mandan también 'grado', deben coincidir
            if grado_int is not None and str(grade_obj.code).isdigit():
                if int(grade_obj.code) != int(grado_int):
                    raise serializers.ValidationError({"grado": "No coincide con el código del grado seleccionado."})

            # Si no mandan 'grado' y el code es numérico, lo sincronizamos
            if grado_int is None and str(grade_obj.code).isdigit():
                attrs["grado"] = int(grade_obj.code)

        return attrs

    def create(self, validated_data):
        password = validated_data.pop("password")
        usuario = Usuario(**validated_data)
        usuario.set_password(password)
        usuario.save()
        return usuario

    def update(self, instance, validated_data):
        password = validated_data.pop("password", None)
        for k, v in validated_data.items():
            setattr(instance, k, v)
        if password:
            instance.set_password(password)
        instance.save()
        return instance
