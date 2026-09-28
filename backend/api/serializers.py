import os

from rest_framework import serializers

from .models import Alerte, Bloc, Document, Litige, Proprietaire, Terrain, Transaction

# Types MIME autorisés pour les documents fonciers
ALLOWED_DOC_TYPES = {
    'application/pdf',
    'image/jpeg',
    'image/png',
    'image/tiff',
}
ALLOWED_DOC_EXTENSIONS = {'.pdf', '.jpg', '.jpeg', '.png', '.tif', '.tiff'}
MAX_DOC_SIZE_MB = 5  # Réduit de 10 à 5 Mo pour limiter la surface d'attaque


class ProprietaireSerializer(serializers.ModelSerializer):
    class Meta:
        model = Proprietaire
        fields = '__all__'
        read_only_fields = ['date_enregistrement']


class ProprietairePublicSerializer(serializers.ModelSerializer):
    """Champs non-sensibles uniquement — utilisé dans les contextes publics (TerrainSerializer)."""
    class Meta:
        model = Proprietaire
        fields = ['id', 'nom', 'prenom', 'email', 'date_enregistrement']
        read_only_fields = fields


class TerrainSerializer(serializers.ModelSerializer):
    proprietaire_actuel_detail = ProprietairePublicSerializer(
        source='proprietaire_actuel', read_only=True
    )

    class Meta:
        model = Terrain
        fields = '__all__'
        read_only_fields = ['id_unique', 'date_enregistrement', 'qr_code']


class DocumentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Document
        fields = '__all__'
        read_only_fields = ['date_upload', 'hash_fichier']

    def create(self, validated_data):
        import hashlib
        fichier = validated_data.get('fichier')
        if fichier:
            h = hashlib.sha256()
            fichier.seek(0)
            for chunk in fichier.chunks():
                h.update(chunk)
            fichier.seek(0)
            validated_data['hash_fichier'] = h.hexdigest()
        return super().create(validated_data)

    # Signatures binaires (magic bytes) des types autorisés
    _MAGIC_BYTES = {
        b'%PDF':                'application/pdf',
        b'\xff\xd8\xff':        'image/jpeg',
        b'\x89PNG':             'image/png',
        b'II*\x00':             'image/tiff',  # TIFF little-endian
        b'MM\x00*':             'image/tiff',  # TIFF big-endian
    }

    def validate_fichier(self, fichier):
        # Vérification de la taille
        max_bytes = MAX_DOC_SIZE_MB * 1024 * 1024
        if fichier.size > max_bytes:
            raise serializers.ValidationError(
                f"Le fichier ne doit pas dépasser {MAX_DOC_SIZE_MB} Mo."
            )
        # Vérification de l'extension
        ext = os.path.splitext(fichier.name)[1].lower()
        if ext not in ALLOWED_DOC_EXTENSIONS:
            raise serializers.ValidationError(
                f"Extension non autorisée. Formats acceptés : {', '.join(ALLOWED_DOC_EXTENSIONS)}"
            )
        # Vérification du content-type déclaré par le navigateur
        content_type = getattr(fichier, 'content_type', '')
        if content_type and content_type not in ALLOWED_DOC_TYPES:
            raise serializers.ValidationError(
                "Type de fichier non autorisé. Seuls PDF et images sont acceptés."
            )
        # Vérification des magic bytes (protection contre les fichiers déguisés)
        fichier.seek(0)
        header = fichier.read(8)
        fichier.seek(0)
        detected = None
        for magic, mime in self._MAGIC_BYTES.items():
            if header[:len(magic)] == magic:
                detected = mime
                break
        if detected is None:
            raise serializers.ValidationError(
                "Le contenu du fichier ne correspond à aucun type autorisé (PDF, JPEG, PNG, TIFF)."
            )
        if content_type and detected != content_type:
            raise serializers.ValidationError(
                "Le type réel du fichier ne correspond pas à son extension déclarée."
            )
        return fichier


class TransactionSerializer(serializers.ModelSerializer):
    terrain_detail = TerrainSerializer(source='terrain', read_only=True)
    vendeur_detail = ProprietaireSerializer(source='vendeur', read_only=True)
    acheteur_detail = ProprietaireSerializer(source='acheteur', read_only=True)

    class Meta:
        model = Transaction
        fields = '__all__'
        read_only_fields = ['date_transaction', 'signature_numerique']

    def validate(self, attrs):
        if attrs.get('vendeur') == attrs.get('acheteur'):
            raise serializers.ValidationError(
                "Le vendeur et l'acheteur ne peuvent pas être la même personne."
            )
        terrain = attrs.get('terrain')
        if terrain and terrain.statut == 'litige':
            raise serializers.ValidationError(
                "Ce terrain est en litige et ne peut pas faire l'objet d'une transaction."
            )
        montant = attrs.get('montant')
        if montant is not None and montant <= 0:
            raise serializers.ValidationError(
                {'montant': "Le montant doit être strictement positif."}
            )
        return attrs


class LitigeSerializer(serializers.ModelSerializer):
    terrain_detail = TerrainSerializer(source='terrain', read_only=True)
    declarant_detail = ProprietaireSerializer(source='declarant', read_only=True)

    class Meta:
        model = Litige
        fields = '__all__'
        read_only_fields = ['date_declaration', 'date_resolution']


class BlocSerializer(serializers.ModelSerializer):
    class Meta:
        model = Bloc
        fields = '__all__'


class AlerteSerializer(serializers.ModelSerializer):
    terrain_detail = TerrainSerializer(source='terrain', read_only=True)

    class Meta:
        model = Alerte
        fields = '__all__'
        read_only_fields = ['date']
