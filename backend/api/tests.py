"""
Tests unitaires et d'intégration — TrustLand (QuadraTech)
==========================================================
Couverture : modèles, blockchain, détection de fraude,
             authentification, endpoints REST, permissions RBAC,
             magic bytes documents, validation métier.
"""

import io
from datetime import timedelta

from django.contrib.auth import get_user_model
from django.test import TestCase
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APIClient

from api.blockchain import ajouter_bloc, calculer_hash, verifier_chaine
from api.models import (
    Alerte,
    Bloc,
    Document,
    JournalAudit,
    Litige,
    Proprietaire,
    PushToken,
    Terrain,
    Transaction,
)

Utilisateur = get_user_model()

# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────

def creer_utilisateur(username, role='agent', password='TestPass123!'):
    return Utilisateur.objects.create_user(
        username=username,
        email=f'{username}@test.tg',
        password=password,
        role=role,
    )


def creer_proprietaire(suffix='1'):
    return Proprietaire.objects.create(
        nom=f'Dupont{suffix}',
        prenom=f'Jean{suffix}',
        email=f'jean{suffix}@test.tg',
        telephone=f'+22890000{suffix.zfill(3)}',
        numero_identite=f'TG-{suffix.zfill(6)}',
    )


def creer_terrain(proprietaire, adresse='Lomé, Togo'):
    return Terrain.objects.create(
        superficie='500.00',
        coordonnees_gps='6.1375,1.2123',
        adresse=adresse,
        proprietaire_actuel=proprietaire,
    )


def _client_avec_token(user):
    """Retourne un APIClient authentifié via Bearer token."""
    from rest_framework_simplejwt.tokens import RefreshToken
    client = APIClient()
    refresh = RefreshToken.for_user(user)
    client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
    return client


def _fichier_factice(nom='test.pdf', magic=b'%PDF-1.4 fake content', content_type='application/pdf'):
    """Crée un fichier en mémoire simulant un vrai fichier (magic bytes corrects)."""
    f = io.BytesIO(magic + b'\n' * 100)
    f.name = nom
    f.content_type = content_type
    f.size = len(magic) + 100
    return f


# ─────────────────────────────────────────────────────────────────────────────
# 1. Tests des modèles
# ─────────────────────────────────────────────────────────────────────────────

class TestModeleProprietaire(TestCase):
    def setUp(self):
        self.prop = creer_proprietaire('A')

    def test_creation(self):
        self.assertEqual(Proprietaire.objects.count(), 1)

    def test_str(self):
        self.assertEqual(str(self.prop), 'JeanA DupontA')

    def test_champ_email_unique(self):
        from django.db import IntegrityError
        with self.assertRaises(IntegrityError):
            Proprietaire.objects.create(
                nom='Autre', prenom='Autre',
                email='jeanA@test.tg',
                telephone='+228999', numero_identite='TG-999',
            )


class TestModeleUtilisateur(TestCase):
    def test_role_defaut(self):
        u = Utilisateur.objects.create_user(username='test', password='pass123!!')
        self.assertEqual(u.role, 'agent')

    def test_roles_disponibles(self):
        roles = [c[0] for c in Utilisateur.Role.choices]
        self.assertIn('admin', roles)
        self.assertIn('agent', roles)
        self.assertIn('proprietaire', roles)

    def test_str_utilisateur(self):
        u = creer_utilisateur('alice', role='admin')
        self.assertIn('alice', str(u))
        self.assertIn('Administrateur', str(u))


class TestModeleTransaction(TestCase):
    def setUp(self):
        self.prop1 = creer_proprietaire('1')
        self.prop2 = creer_proprietaire('2')
        self.terrain = creer_terrain(self.prop1)

    def test_signature_auto_generee(self):
        tx = Transaction.objects.create(
            terrain=self.terrain,
            vendeur=self.prop1,
            acheteur=self.prop2,
            montant='150000.00',
        )
        self.assertIsNotNone(tx.signature_numerique)
        self.assertEqual(len(tx.signature_numerique), 64)

    def test_signature_unique(self):
        tx1 = Transaction.objects.create(
            terrain=self.terrain, vendeur=self.prop1,
            acheteur=self.prop2, montant='100.00',
        )
        prop3 = creer_proprietaire('3')
        terrain2 = creer_terrain(prop3, adresse='Kara, Togo')
        tx2 = Transaction.objects.create(
            terrain=terrain2, vendeur=prop3,
            acheteur=self.prop2, montant='200.00',
        )
        self.assertNotEqual(tx1.signature_numerique, tx2.signature_numerique)


class TestModeleBloc(TestCase):
    def test_str_bloc(self):
        bloc = Bloc.objects.create(
            index=0, timestamp=timezone.now(),
            data={'test': True}, hash='a' * 64,
            previous_hash='0' * 64,
        )
        self.assertIn('Bloc #0', str(bloc))


# ─────────────────────────────────────────────────────────────────────────────
# 2. Tests de la blockchain
# ─────────────────────────────────────────────────────────────────────────────

class TestBlockchain(TestCase):
    def test_calculer_hash_deterministe(self):
        ts = timezone.now()
        h1 = calculer_hash(0, ts, {'a': 1}, '0' * 64)
        h2 = calculer_hash(0, ts, {'a': 1}, '0' * 64)
        self.assertEqual(h1, h2)
        self.assertEqual(len(h1), 64)

    def test_calculer_hash_sensible_aux_donnees(self):
        ts = timezone.now()
        h1 = calculer_hash(0, ts, {'val': 'A'}, '0' * 64)
        h2 = calculer_hash(0, ts, {'val': 'B'}, '0' * 64)
        self.assertNotEqual(h1, h2)

    def test_chaine_vide_valide(self):
        self.assertTrue(verifier_chaine())

    def test_ajouter_bloc_genesis(self):
        bloc = ajouter_bloc({'test': 'genesis'})
        self.assertEqual(bloc.index, 0)
        self.assertEqual(bloc.previous_hash, '0' * 64)
        self.assertIsNotNone(bloc.hash)

    def test_ajouter_bloc_suivant(self):
        b0 = ajouter_bloc({'type': 'genesis'})
        b1 = ajouter_bloc({'type': 'second'})
        self.assertEqual(b1.index, 1)
        self.assertEqual(b1.previous_hash, b0.hash)

    def test_verifier_chaine_valide(self):
        ajouter_bloc({'op': 'a'})
        ajouter_bloc({'op': 'b'})
        ajouter_bloc({'op': 'c'})
        self.assertTrue(verifier_chaine())

    def test_tamper_invalide_chaine(self):
        """Modifier un bloc doit invalider la chaîne."""
        ajouter_bloc({'op': 'test'})
        bloc = Bloc.objects.first()
        bloc.data = {'op': 'falsifie'}
        bloc.save(update_fields=['data'])
        self.assertFalse(verifier_chaine())

    def test_tamper_hash_invalide(self):
        """Changer le hash stocké doit invalider la chaîne."""
        ajouter_bloc({'op': 'original'})
        bloc = Bloc.objects.first()
        bloc.hash = 'f' * 64
        bloc.save(update_fields=['hash'])
        self.assertFalse(verifier_chaine())


# ─────────────────────────────────────────────────────────────────────────────
# 3. Tests du chiffrement des champs sensibles
# ─────────────────────────────────────────────────────────────────────────────

class TestChiffrementChamps(TestCase):
    def test_telephone_chiffre_en_base(self):
        prop = creer_proprietaire('X')
        from django.db import connection
        with connection.cursor() as cur:
            cur.execute(
                'SELECT telephone FROM api_proprietaire WHERE id = %s', [prop.id]
            )
            valeur_brute = cur.fetchone()[0]
        self.assertTrue(
            valeur_brute.startswith('$ENC$'),
            f"La valeur en base devrait être chiffrée, reçu: {valeur_brute[:30]}",
        )

    def test_telephone_dechiffre_a_la_lecture(self):
        telephone = '+22890123456'
        prop = Proprietaire.objects.create(
            nom='Test', prenom='Chiffre',
            email='chiffre@test.tg',
            telephone=telephone,
            numero_identite='TG-CHF001',
        )
        prop_lu = Proprietaire.objects.get(pk=prop.pk)
        self.assertEqual(prop_lu.telephone, telephone)

    def test_numero_identite_chiffre(self):
        numero = 'TG-SECRET-123'
        prop = Proprietaire.objects.create(
            nom='Sec', prenom='Ret',
            email='secret@test.tg',
            telephone='+22800000000',
            numero_identite=numero,
        )
        from django.db import connection
        with connection.cursor() as cur:
            cur.execute(
                'SELECT numero_identite FROM api_proprietaire WHERE id = %s', [prop.id]
            )
            valeur_brute = cur.fetchone()[0]
        self.assertTrue(valeur_brute.startswith('$ENC$'))
        prop_lu = Proprietaire.objects.get(pk=prop.pk)
        self.assertEqual(prop_lu.numero_identite, numero)


# ─────────────────────────────────────────────────────────────────────────────
# 4. Tests de détection de fraude
# ─────────────────────────────────────────────────────────────────────────────

class TestDetectionFraude(TestCase):
    def setUp(self):
        self.prop1 = creer_proprietaire('F1')
        self.prop2 = creer_proprietaire('F2')
        self.prop3 = creer_proprietaire('F3')
        self.terrain = creer_terrain(self.prop1)

    def _creer_transaction(self, terrain=None, vendeur=None, acheteur=None, montant='10000.00'):
        from api.fraude import analyser_transaction
        t = terrain or self.terrain
        v = vendeur or self.prop1
        a = acheteur or self.prop2
        tx = Transaction.objects.create(terrain=t, vendeur=v, acheteur=a, montant=montant)
        analyser_transaction(tx)
        return tx

    def test_pas_alerte_premiere_transaction(self):
        self._creer_transaction()
        self.assertEqual(Alerte.objects.count(), 0)

    def test_double_transaction_meme_jour(self):
        """Deux transactions le même jour sur le même terrain → alerte critique."""
        self._creer_transaction()
        self._creer_transaction()
        alertes = Alerte.objects.filter(type_alerte='double_transaction')
        self.assertGreaterEqual(alertes.count(), 1)
        self.assertEqual(alertes.first().niveau, 'critique')

    def test_transaction_repetee_30_jours(self):
        """≥ 2 transactions en 30 jours → alerte."""
        self._creer_transaction()
        self._creer_transaction()
        self.assertGreater(Alerte.objects.filter(terrain=self.terrain).count(), 0)

    def test_vendeur_suspect_7_jours(self):
        """Même vendeur : ≥ 4 transactions total en 7 jours (nb_7j >= 3) → alerte critique."""
        terrain2 = creer_terrain(self.prop1, adresse='Adidogomé, Togo')
        terrain3 = creer_terrain(self.prop1, adresse='Bè, Togo')
        terrain4 = creer_terrain(self.prop1, adresse='Tsévié, Togo')
        self._creer_transaction(terrain=self.terrain)
        self._creer_transaction(terrain=terrain2, vendeur=self.prop1, acheteur=self.prop2)
        self._creer_transaction(terrain=terrain3, vendeur=self.prop1, acheteur=self.prop3)
        self._creer_transaction(terrain=terrain4, vendeur=self.prop1, acheteur=self.prop2)
        alertes = Alerte.objects.filter(type_alerte='vendeur_suspect', niveau='critique')
        self.assertGreaterEqual(alertes.count(), 1)


# ─────────────────────────────────────────────────────────────────────────────
# 5. Tests d'authentification (CORRECTION : RegisterSerializer)
# ─────────────────────────────────────────────────────────────────────────────

class TestAuthentification(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = creer_utilisateur('testuser', role='agent')

    def test_login_succes(self):
        response = self.client.post('/api/token/', {
            'username': 'testuser', 'password': 'TestPass123!',
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('access', response.data)
        self.assertIn('refresh', response.data)

    def test_login_mauvais_mot_de_passe(self):
        response = self.client.post('/api/token/', {
            'username': 'testuser', 'password': 'mauvais',
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_endpoint_protege_sans_token(self):
        response = self.client.get('/api/stats/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_endpoint_protege_avec_token_valide(self):
        client = _client_avec_token(self.user)
        response = client.get('/api/stats/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_register_force_role_proprietaire(self):
        """L'inscription crée toujours un proprietaire, quel que soit le payload."""
        response = self.client.post('/api/users/register/', {
            'username': 'newuser',
            'email': 'newuser@test.tg',
            'password': 'NewPass123!',
            'password2': 'NewPass123!',
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        u = Utilisateur.objects.get(username='newuser')
        self.assertEqual(u.role, 'proprietaire')

    def test_register_password2_requis(self):
        """Sans password2, l'inscription est refusée."""
        response = self.client.post('/api/users/register/', {
            'username': 'user_sans_confirm',
            'email': 'noconfirm@test.tg',
            'password': 'Pass123!',
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_register_passwords_incompatibles(self):
        """password != password2 → 400."""
        response = self.client.post('/api/users/register/', {
            'username': 'user_mismatch',
            'email': 'mismatch@test.tg',
            'password': 'Pass123!',
            'password2': 'AutrePass456!',
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('password2', response.data)

    def test_register_role_injecte_ignore(self):
        """Tenter d'injecter role=agent via le payload public ne doit pas fonctionner."""
        response = self.client.post('/api/users/register/', {
            'username': 'tentative_agent',
            'email': 'agent_tentative@test.tg',
            'password': 'AgentPass123!',
            'password2': 'AgentPass123!',
            'role': 'agent',
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        u = Utilisateur.objects.get(username='tentative_agent')
        self.assertEqual(u.role, 'proprietaire', "Le rôle injecté ne doit pas être pris en compte.")

    def test_me_retourne_profil(self):
        client = _client_avec_token(self.user)
        response = client.get('/api/users/me/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['username'], 'testuser')

    def test_me_ne_peut_pas_changer_role(self):
        """Le rôle ne peut pas être changé via PATCH /me/."""
        client = _client_avec_token(self.user)
        client.patch('/api/users/me/', {'role': 'admin'}, format='json')
        self.user.refresh_from_db()
        self.assertEqual(self.user.role, 'agent')


# ─────────────────────────────────────────────────────────────────────────────
# 6. Tests des permissions RBAC (+ correction suppression terrain)
# ─────────────────────────────────────────────────────────────────────────────

class TestPermissionsRBAC(TestCase):
    def setUp(self):
        self.admin = creer_utilisateur('admin_u', role='admin')
        self.agent = creer_utilisateur('agent_u', role='agent')
        self.prop_user = creer_utilisateur('prop_u', role='proprietaire')
        self.prop = creer_proprietaire('R')
        self.terrain = creer_terrain(self.prop)

    def test_agent_peut_lire_proprietaires(self):
        client = _client_avec_token(self.agent)
        self.assertEqual(client.get('/api/proprietaires/').status_code, 200)

    def test_proprietaire_ne_peut_pas_lire_proprietaires(self):
        client = _client_avec_token(self.prop_user)
        self.assertEqual(client.get('/api/proprietaires/').status_code, 403)

    def test_agent_peut_creer_terrain(self):
        client = _client_avec_token(self.agent)
        response = client.post('/api/terrains/', {
            'superficie': '300.00',
            'coordonnees_gps': '6.1,1.2',
            'adresse': 'Agoé, Togo',
            'proprietaire_actuel': self.prop.pk,
        }, format='json')
        self.assertEqual(response.status_code, 201)

    def test_proprietaire_ne_peut_pas_creer_terrain(self):
        client = _client_avec_token(self.prop_user)
        response = client.post('/api/terrains/', {
            'superficie': '200.00', 'coordonnees_gps': '6.1,1.2',
            'adresse': 'Test, Togo', 'proprietaire_actuel': self.prop.pk,
        }, format='json')
        self.assertEqual(response.status_code, 403)

    def test_seul_admin_peut_lister_utilisateurs(self):
        self.assertEqual(_client_avec_token(self.admin).get('/api/users/utilisateurs/').status_code, 200)
        self.assertEqual(_client_avec_token(self.agent).get('/api/users/utilisateurs/').status_code, 403)

    def test_seul_admin_peut_voir_alertes(self):
        self.assertEqual(_client_avec_token(self.prop_user).get('/api/alertes/').status_code, 403)

    def test_admin_ne_peut_pas_changer_son_propre_role(self):
        client = _client_avec_token(self.admin)
        response = client.patch(f'/api/users/utilisateurs/{self.admin.pk}/',
                                {'role': 'agent'}, format='json')
        self.assertEqual(response.status_code, 400)

    def test_admin_ne_peut_pas_se_supprimer(self):
        client = _client_avec_token(self.admin)
        self.assertEqual(client.delete(f'/api/users/utilisateurs/{self.admin.pk}/').status_code, 400)

    # ── CORRECTION : suppression de terrain ───────────────────────────────────

    def test_admin_peut_supprimer_terrain(self):
        """Admin peut supprimer un terrain (matrice des permissions)."""
        client = _client_avec_token(self.admin)
        response = client.delete(f'/api/terrains/{self.terrain.pk}/')
        self.assertEqual(response.status_code, 204)
        self.assertFalse(Terrain.objects.filter(pk=self.terrain.pk).exists())

    def test_agent_ne_peut_pas_supprimer_terrain(self):
        """Agent ne peut pas supprimer un terrain (matrice des permissions)."""
        client = _client_avec_token(self.agent)
        response = client.delete(f'/api/terrains/{self.terrain.pk}/')
        self.assertEqual(response.status_code, 403)
        self.assertTrue(Terrain.objects.filter(pk=self.terrain.pk).exists())


# ─────────────────────────────────────────────────────────────────────────────
# 7. Tests des endpoints métier
# ─────────────────────────────────────────────────────────────────────────────

class TestEndpointsMetier(TestCase):
    def setUp(self):
        self.agent = creer_utilisateur('agent_m', role='agent')
        self.admin = creer_utilisateur('admin_m', role='admin')
        self.prop1 = creer_proprietaire('M1')
        self.prop2 = creer_proprietaire('M2')
        self.terrain = creer_terrain(self.prop1)
        self.client_agent = _client_avec_token(self.agent)
        self.client_admin = _client_avec_token(self.admin)

    def test_stats_retourne_structure_correcte(self):
        response = self.client_agent.get('/api/stats/')
        self.assertEqual(response.status_code, 200)
        for cle in ['terrains_total', 'transactions_total', 'litiges_ouverts', 'alertes_actives']:
            self.assertIn(cle, response.data)

    def test_lister_terrains(self):
        response = self.client_agent.get('/api/terrains/')
        self.assertEqual(response.status_code, 200)
        self.assertGreaterEqual(len(response.data['results']), 1)

    def test_creer_proprietaire(self):
        response = self.client_agent.post('/api/proprietaires/', {
            'nom': 'Kofi', 'prenom': 'Ama', 'email': 'ama.kofi@test.tg',
            'telephone': '+22891000001', 'numero_identite': 'TG-NEW-001',
        }, format='json')
        self.assertEqual(response.status_code, 201)
        self.assertTrue(Proprietaire.objects.filter(email='ama.kofi@test.tg').exists())

    def test_creer_transaction_cree_bloc(self):
        initial_blocs = Bloc.objects.count()
        response = self.client_agent.post('/api/transactions/', {
            'terrain': self.terrain.pk,
            'vendeur': self.prop1.pk,
            'acheteur': self.prop2.pk,
            'montant': '500000.00',
        }, format='json')
        self.assertEqual(response.status_code, 201)
        self.assertEqual(Bloc.objects.count(), initial_blocs + 1)

    def test_transaction_change_statut_terrain(self):
        self.client_agent.post('/api/transactions/', {
            'terrain': self.terrain.pk,
            'vendeur': self.prop1.pk,
            'acheteur': self.prop2.pk,
            'montant': '250000.00',
        }, format='json')
        self.terrain.refresh_from_db()
        self.assertEqual(self.terrain.statut, Terrain.Statut.EN_TRANSACTION)

    def test_creer_litige(self):
        response = self.client_agent.post('/api/litiges/', {
            'terrain': self.terrain.pk,
            'declarant': self.prop1.pk,
            'description': 'Litige de frontière.',
        }, format='json')
        self.assertEqual(response.status_code, 201)
        self.terrain.refresh_from_db()
        self.assertEqual(self.terrain.statut, Terrain.Statut.LITIGE)

    def test_resoudre_litige(self):
        self.client_agent.post('/api/litiges/', {
            'terrain': self.terrain.pk, 'declarant': self.prop1.pk,
            'description': 'Litige test.',
        }, format='json')
        litige = Litige.objects.first()
        response = self.client_admin.patch(
            f'/api/litiges/{litige.pk}/resoudre/',
            {'resolution': 'Résolu par arbitrage.'}, format='json',
        )
        self.assertEqual(response.status_code, 200)
        litige.refresh_from_db()
        self.assertEqual(litige.statut, Litige.Statut.RESOLU)

    def test_blockchain_liste_blocs(self):
        ajouter_bloc({'test': True})
        response = self.client_agent.get('/api/blockchain/')
        self.assertEqual(response.status_code, 200)
        self.assertGreaterEqual(len(response.data), 1)

    def test_blockchain_verifier_admin_seulement(self):
        self.assertEqual(self.client_agent.get('/api/blockchain/verifier/').status_code, 403)
        response_admin = self.client_admin.get('/api/blockchain/verifier/')
        self.assertEqual(response_admin.status_code, 200)
        self.assertTrue(response_admin.data['valide'])

    def test_historique_terrain(self):
        response = self.client_agent.get(f'/api/terrains/{self.terrain.pk}/historique/')
        self.assertEqual(response.status_code, 200)
        self.assertIsInstance(response.data, list)

    def test_terrain_litiges(self):
        Litige.objects.create(terrain=self.terrain, declarant=self.prop1, description='Test')
        response = self.client_agent.get(f'/api/terrains/{self.terrain.pk}/litiges/')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 1)


# ─────────────────────────────────────────────────────────────────────────────
# 8. Tests de validation métier (AMÉLIORATION)
# ─────────────────────────────────────────────────────────────────────────────

class TestValidationMetier(TestCase):
    """Tests des règles de validation dans les serializers."""

    def setUp(self):
        self.agent = creer_utilisateur('agent_v', role='agent')
        self.prop1 = creer_proprietaire('V1')
        self.prop2 = creer_proprietaire('V2')
        self.terrain = creer_terrain(self.prop1)
        self.client = _client_avec_token(self.agent)

    def test_vendeur_acheteur_identiques_refuse(self):
        """Vendeur == Acheteur → 400."""
        response = self.client.post('/api/transactions/', {
            'terrain': self.terrain.pk,
            'vendeur': self.prop1.pk,
            'acheteur': self.prop1.pk,
            'montant': '100000.00',
        }, format='json')
        self.assertEqual(response.status_code, 400)

    def test_montant_nul_refuse(self):
        """Montant = 0 → 400 (AMÉLIORATION)."""
        response = self.client.post('/api/transactions/', {
            'terrain': self.terrain.pk,
            'vendeur': self.prop1.pk,
            'acheteur': self.prop2.pk,
            'montant': '0.00',
        }, format='json')
        self.assertEqual(response.status_code, 400)
        self.assertIn('montant', response.data)

    def test_montant_negatif_refuse(self):
        """Montant négatif → 400 (AMÉLIORATION)."""
        response = self.client.post('/api/transactions/', {
            'terrain': self.terrain.pk,
            'vendeur': self.prop1.pk,
            'acheteur': self.prop2.pk,
            'montant': '-5000.00',
        }, format='json')
        self.assertEqual(response.status_code, 400)
        self.assertIn('montant', response.data)

    def test_transaction_terrain_en_litige_refuse(self):
        """Transaction sur terrain en litige → 400."""
        self.terrain.statut = Terrain.Statut.LITIGE
        self.terrain.save()
        response = self.client.post('/api/transactions/', {
            'terrain': self.terrain.pk,
            'vendeur': self.prop1.pk,
            'acheteur': self.prop2.pk,
            'montant': '100000.00',
        }, format='json')
        self.assertEqual(response.status_code, 400)

    def test_montant_positif_accepte(self):
        """Montant positif → 201."""
        response = self.client.post('/api/transactions/', {
            'terrain': self.terrain.pk,
            'vendeur': self.prop1.pk,
            'acheteur': self.prop2.pk,
            'montant': '1.00',
        }, format='json')
        self.assertEqual(response.status_code, 201)


# ─────────────────────────────────────────────────────────────────────────────
# 9. Tests de validation des documents par magic bytes (AMÉLIORATION)
# ─────────────────────────────────────────────────────────────────────────────

class TestValidationDocuments(TestCase):
    """Vérifie la validation des magic bytes pour les documents uploadés."""

    def setUp(self):
        self.agent = creer_utilisateur('agent_doc', role='agent')
        self.prop = creer_proprietaire('DOC')
        self.terrain = creer_terrain(self.prop)
        self.client = _client_avec_token(self.agent)

    def _upload(self, contenu, nom, content_type):
        f = io.BytesIO(contenu)
        f.name = nom
        return self.client.post('/api/documents/', {
            'terrain': self.terrain.pk,
            'fichier': f,
            'type_document': 'autre',
        }, format='multipart', CONTENT_TYPE_OVERRIDE=content_type)

    def test_pdf_valide_accepte(self):
        f = io.BytesIO(b'%PDF-1.4 fake content here for testing')
        f.name = 'doc.pdf'
        response = self.client.post('/api/documents/', {
            'terrain': self.terrain.pk,
            'fichier': f,
            'type_document': 'titre_foncier',
        }, format='multipart')
        self.assertEqual(response.status_code, 201)

    def test_fichier_deguise_refuse(self):
        """Fichier .pdf dont le contenu est du HTML → refusé par magic bytes."""
        f = io.BytesIO(b'<html>je suis un fichier malveillant</html>')
        f.name = 'malveillant.pdf'
        response = self.client.post('/api/documents/', {
            'terrain': self.terrain.pk,
            'fichier': f,
            'type_document': 'autre',
        }, format='multipart')
        self.assertEqual(response.status_code, 400)

    def test_fichier_trop_grand_refuse(self):
        """Fichier > 5 Mo → refusé."""
        from unittest.mock import patch, MagicMock
        from django.core.files.uploadedfile import SimpleUploadedFile
        gros = b'%PDF' + b'X' * (5 * 1024 * 1024 + 1)
        f = SimpleUploadedFile('gros.pdf', gros, content_type='application/pdf')
        response = self.client.post('/api/documents/', {
            'terrain': self.terrain.pk,
            'fichier': f,
            'type_document': 'autre',
        }, format='multipart')
        self.assertEqual(response.status_code, 400)

    def test_extension_non_autorisee_refuse(self):
        """Extension .exe → refusée."""
        f = io.BytesIO(b'MZ malware')
        f.name = 'malware.exe'
        response = self.client.post('/api/documents/', {
            'terrain': self.terrain.pk,
            'fichier': f,
            'type_document': 'autre',
        }, format='multipart')
        self.assertEqual(response.status_code, 400)

    def test_png_valide_accepte(self):
        """Fichier PNG valide (magic bytes corrects) → accepté."""
        png_magic = b'\x89PNG\r\n\x1a\n' + b'\x00' * 100
        f = io.BytesIO(png_magic)
        f.name = 'image.png'
        response = self.client.post('/api/documents/', {
            'terrain': self.terrain.pk,
            'fichier': f,
            'type_document': 'autre',
        }, format='multipart')
        self.assertEqual(response.status_code, 201)


# ─────────────────────────────────────────────────────────────────────────────
# 10. Tests de la gestion des utilisateurs (admin)
# ─────────────────────────────────────────────────────────────────────────────

class TestGestionUtilisateurs(TestCase):
    def setUp(self):
        self.admin = creer_utilisateur('superadmin', role='admin')
        self.client_admin = _client_avec_token(self.admin)

    def test_lister_utilisateurs(self):
        creer_utilisateur('user1', role='agent')
        response = self.client_admin.get('/api/users/utilisateurs/')
        self.assertEqual(response.status_code, 200)
        self.assertGreaterEqual(len(response.data), 2)

    def test_creer_utilisateur_agent(self):
        response = self.client_admin.post('/api/users/utilisateurs/', {
            'username': 'nouvel_agent', 'email': 'nouvel@test.tg',
            'password': 'AgentPass123!', 'role': 'agent',
        }, format='json')
        self.assertEqual(response.status_code, 201)
        self.assertEqual(Utilisateur.objects.get(username='nouvel_agent').role, 'agent')

    def test_supprimer_utilisateur(self):
        user = creer_utilisateur('a_supprimer', role='agent')
        response = self.client_admin.delete(f'/api/users/utilisateurs/{user.pk}/')
        self.assertEqual(response.status_code, 204)
        self.assertFalse(Utilisateur.objects.filter(pk=user.pk).exists())

    def test_modifier_role_utilisateur(self):
        user = creer_utilisateur('role_change', role='agent')
        response = self.client_admin.patch(
            f'/api/users/utilisateurs/{user.pk}/', {'role': 'proprietaire'}, format='json'
        )
        self.assertEqual(response.status_code, 200)
        user.refresh_from_db()
        self.assertEqual(user.role, 'proprietaire')


# ─────────────────────────────────────────────────────────────────────────────
# 11. Tests des push tokens
# ─────────────────────────────────────────────────────────────────────────────

class TestPushTokens(TestCase):
    def setUp(self):
        self.user = creer_utilisateur('mobile_user', role='agent')
        self.client = _client_avec_token(self.user)
        self.token_valide = 'ExponentPushToken[xxxxxxxxxxxxxxxxxxxxxx]'

    def test_enregistrer_token_valide(self):
        response = self.client.post('/api/push-token/', {'token': self.token_valide}, format='json')
        self.assertEqual(response.status_code, 200)
        self.assertTrue(PushToken.objects.filter(token=self.token_valide).exists())

    def test_format_token_invalide(self):
        response = self.client.post('/api/push-token/', {'token': 'invalid-token'}, format='json')
        self.assertEqual(response.status_code, 400)

    def test_supprimer_token(self):
        PushToken.objects.create(utilisateur=self.user, token=self.token_valide)
        response = self.client.delete('/api/push-token/', {'token': self.token_valide}, format='json')
        self.assertEqual(response.status_code, 204)
        self.assertFalse(PushToken.objects.filter(token=self.token_valide).exists())

    def test_token_sans_auth_refuse(self):
        anon = APIClient()
        self.assertEqual(
            anon.post('/api/push-token/', {'token': self.token_valide}, format='json').status_code, 401
        )


# ─────────────────────────────────────────────────────────────────────────────
# 12. Tests du journal d'audit
# ─────────────────────────────────────────────────────────────────────────────

class TestJournalAudit(TestCase):
    def setUp(self):
        self.agent = creer_utilisateur('audit_agent', role='agent')
        self.prop = creer_proprietaire('AU')
        self.client = _client_avec_token(self.agent)

    def test_post_cree_entree_journal(self):
        avant = JournalAudit.objects.count()
        self.client.post('/api/proprietaires/', {
            'nom': 'Audit', 'prenom': 'Test', 'email': 'audit@test.tg',
            'telephone': '+22800000001', 'numero_identite': 'TG-AUD001',
        }, format='json')
        self.assertGreater(JournalAudit.objects.count(), avant)

    def test_get_ne_cree_pas_entree_journal(self):
        avant = JournalAudit.objects.count()
        self.client.get('/api/terrains/')
        self.assertEqual(JournalAudit.objects.count(), avant)
