import pymysql
import json
from datetime import datetime, date
from typing import Dict, List, Optional
from models import UserDocument, Alert, StaffUser
import os
from dotenv import load_dotenv

load_dotenv('config.env')

class MySQLDatabaseManager:
    def __init__(self):
        self.host = os.getenv("DB_HOST", "localhost")
        self.port = int(os.getenv("DB_PORT", 3306))
        self.user = os.getenv("DB_USER", "root")
        self.password = os.getenv("DB_PASSWORD", "")
        self.database = os.getenv("DB_NAME", "smart_cane_db")
        
        print(f"DEBUG: Configuration MySQL - Host: {self.host}, Port: {self.port}, User: {self.user}, DB: {self.database}")
        self.init_database()
        
    def get_connection(self):
        """Établir une connexion à la base de données MySQL"""
        try:
            connection = pymysql.connect(
                host=self.host,
                port=self.port,
                user=self.user,
                password=self.password,
                database=self.database,
                charset='utf8mb4',
                cursorclass=pymysql.cursors.DictCursor,
                autocommit=True
            )
            return connection
        except Exception as e:
            print(f"ERREUR: Connexion MySQL échouée: {e}")
            raise
    
    def test_connection(self):
        """Tester la connexion à la base de données"""
        try:
            conn = self.get_connection()
            with conn.cursor() as cursor:
                cursor.execute("SELECT 1")
                cursor.fetchone()
            conn.close()
            print("SUCCÈS: Connexion MySQL établie")
            return True
        except Exception as e:
            print(f"ERREUR: Test de connexion MySQL: {e}")
            return False
            
    def init_database(self):
        """Initialiser la base de données et les tables si elles n'existent pas"""
        try:
            # D'abord se connecter sans base de données pour la créer si besoin
            conn = pymysql.connect(
                host=self.host,
                port=self.port,
                user=self.user,
                password=self.password,
                charset='utf8mb4',
                autocommit=True
            )
            with conn.cursor() as cursor:
                cursor.execute(f"CREATE DATABASE IF NOT EXISTS {self.database}")
            conn.close()
            
            # Maintenant se connecter à la base de données
            conn = self.get_connection()
            with conn.cursor() as cursor:
                # Table Admin
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS admin (
                        cin VARCHAR(50) PRIMARY KEY,
                        nom VARCHAR(100) NOT NULL,
                        email VARCHAR(100) UNIQUE NOT NULL,
                        mot_de_passe VARCHAR(255) NOT NULL
                    )
                """)
                
                # Table Staff
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS staff (
                        cin VARCHAR(50) PRIMARY KEY,
                        nom VARCHAR(100) NOT NULL,
                        email VARCHAR(100) UNIQUE NOT NULL,
                        mot_de_passe VARCHAR(255) NOT NULL,
                        role VARCHAR(50) DEFAULT 'staff',
                        poste_periode_travail VARCHAR(50),
                        numero_de_telephone VARCHAR(50),
                        adresse TEXT,
                        cree_le TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                """)
                
                # Table Utilisateur
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS utilisateur (
                        cin VARCHAR(50) PRIMARY KEY,
                        nom VARCHAR(100) NOT NULL,
                        prenom VARCHAR(100),
                        age INT,
                        adresse TEXT,
                        email VARCHAR(100) UNIQUE NOT NULL,
                        numero_de_telephone VARCHAR(50),
                        contact_familial VARCHAR(50),
                        etat_de_sante TEXT,
                        sim_de_la_canne VARCHAR(50),
                        cree_le TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                """)
                
                # Table Canne
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS canne (
                        sim_de_la_canne VARCHAR(50) PRIMARY KEY,
                        version VARCHAR(100),
                        statut VARCHAR(50) DEFAULT 'disponible',
                        type VARCHAR(50)
                    )
                """)
                
                # Table Location
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS location (
                        sim_de_la_canne VARCHAR(50),
                        cin_utilisateur VARCHAR(50),
                        date_de_location DATE,
                        date_de_retour DATE,
                        PRIMARY KEY (sim_de_la_canne, cin_utilisateur, date_de_location)
                    )
                """)
                
                # Table Abonnement
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS abonnement (
                        sim_de_la_canne VARCHAR(50),
                        cin_utilisateur VARCHAR(50),
                        type_d_abonnement VARCHAR(100),
                        date_de_debut DATE,
                        date_de_fin DATE,
                        PRIMARY KEY (sim_de_la_canne, cin_utilisateur, date_de_debut)
                    )
                """)
                
                # Table Reset Codes
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS reset_codes (
                        email VARCHAR(100) PRIMARY KEY,
                        code VARCHAR(10) NOT NULL,
                        expires_at DATETIME NOT NULL
                    )
                """)

                # Table Alerts
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS alerts (
                        alert_id VARCHAR(50) PRIMARY KEY,
                        user_id VARCHAR(50) NOT NULL,
                        type VARCHAR(20) NOT NULL,
                        latitude DOUBLE NOT NULL,
                        longitude DOUBLE NOT NULL,
                        timestamp VARCHAR(50) NOT NULL,
                        status VARCHAR(20) DEFAULT 'active',
                        resolved_by VARCHAR(50),
                        resolved_by_name VARCHAR(100),
                        resolved_at VARCHAR(50),
                        taken_by VARCHAR(50),
                        taken_by_name VARCHAR(100),
                        reactivated_by VARCHAR(50),
                        reactivated_by_name VARCHAR(100),
                        reactivated_at VARCHAR(50)
                    )
                """)
            conn.close()
            # On ne lance pas seed_default_data ici pour garder le flux séparé
        except Exception as e:
            print(f"ERREUR lors de l'initialisation de la base MySQL: {e}")
    
    def seed_default_data(self):
        """Insérer les données par défaut si les tables sont vides"""
        try:
            conn = self.get_connection()
            with conn.cursor() as cursor:
                # Vérifier si la table admin existe et est vide
                try:
                    cursor.execute("SELECT COUNT(*) as count FROM admin")
                    admin_count = cursor.fetchone()['count']
                    
                    if admin_count == 0:
                        # Insérer admin par défaut
                        cursor.execute("""
                            INSERT INTO admin (cin, nom, email, mot_de_passe) 
                            VALUES (%s, %s, %s, %s)
                        """, ("ADMIN001", "Admin Principal", "aifaalaa97@gmail.com", "123456"))
                        print("Admin par défaut inséré")
                except Exception as e:
                    print(f"Table admin non trouvée ou erreur: {e}")
                
                # Vérifier si la table staff est vide
                try:
                    cursor.execute("SELECT COUNT(*) as count FROM staff")
                    staff_count = cursor.fetchone()['count']
                    
                    if staff_count == 0:
                        # Insérer staff par défaut
                        cursor.execute("""
                            INSERT INTO staff (cin, nom, email, mot_de_passe, role, poste_periode_travail) 
                            VALUES (%s, %s, %s, %s, %s, %s)
                        """, ("STAFF001", "Mohamed Ben Ali", "staff@smartcane.com", "staff123", "staff", "matin"))
                        print("Staff par défaut inséré")
                except Exception as e:
                    print(f"Table staff non trouvée ou erreur: {e}")
                
                # Vérifier si la table utilisateur est vide
                try:
                    cursor.execute("SELECT COUNT(*) as count FROM utilisateur")
                    user_count = cursor.fetchone()['count']
                    
                    if user_count == 0:
                        # Insérer utilisateurs par défaut
                        demo_users = [
                            ("USER001", "Ben Slama", 62, "Tunis", "m.benslama@example.com", "+216 20 123 456", "+216 55 987 654", "Bon état de santé"),
                            ("USER002", "Trabelsi", 57, "Sfax", "f.trabelsi@example.com", "+216 22 333 444", "+216 55 111 222", "Hypertension"),
                            ("USER003", "Bouazizi", 81, "Sousse", "a.bouazizi@example.com", "+216 25 555 666", "+216 98 777 888", "Diabète")
                        ]
                        
                        cursor.executemany("""
                            INSERT INTO utilisateur (cin, nom, age, adresse, email, numero_de_telephone, contact_familial, etat_de_sante) 
                            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                        """, demo_users)
                        print("Utilisateurs par défaut insérés")
                except Exception as e:
                    print(f"Table utilisateur non trouvée ou erreur: {e}")
                
                # Vérifier si la table canne est vide
                try:
                    cursor.execute("SELECT COUNT(*) as count FROM canne")
                    cane_count = cursor.fetchone()['count']
                    
                    if cane_count == 0:
                        # Insérer cannes par défaut
                        demo_cannes = [
                            ("SIM001", "Smart Lite", "disponible", "location"),
                            ("SIM002", "Smart Pro V2", "disponible", "abonnement"),
                            ("SIM003", "Smart Pro V3", "disponible", "location")
                        ]
                        
                        cursor.executemany("""
                            INSERT INTO canne (sim_de_la_canne, version, statut, type) 
                            VALUES (%s, %s, %s, %s)
                        """, demo_cannes)
                        print("Cannes par défaut insérées")
                except Exception as e:
                    print(f"Table canne non trouvée ou erreur: {e}")
            
            conn.close()
            print("Données par défaut insérées avec succès")
            
        except Exception as e:
            print(f"ERREUR lors de l'insertion des données par défaut: {e}")
    
    # Staff operations
    def get_all_staff(self) -> List[StaffUser]:
        try:
            conn = self.get_connection()
            with conn.cursor() as cursor:
                cursor.execute("SELECT * FROM staff")
                rows = cursor.fetchall()
            
            conn.close()
            
            staff_list = []
            for row in rows:
                staff = StaffUser(
                    staff_id=row['cin'],
                    name=row['nom'],
                    email=row['email'],
                    password=row['mot_de_passe'],
                    role=row['role'],
                    shift=row['poste_periode_travail'] or 'matin',
                    phone=row['numero_de_telephone'],
                    address=row['adresse']
                )
                staff_list.append(staff)
            
            return staff_list
            
        except Exception as e:
            print(f"ERREUR get_all_staff: {e}")
            return []
    
    def get_staff_by_email(self, email: str) -> Optional[StaffUser]:
        try:
            conn = self.get_connection()
            with conn.cursor() as cursor:
                # D'abord chercher dans la table staff
                cursor.execute("SELECT * FROM staff WHERE email = %s", (email.lower(),))
                row = cursor.fetchone()
                
                # Si pas trouvé dans staff, chercher dans admin
                if not row:
                    cursor.execute("SELECT * FROM admin WHERE email = %s", (email.lower(),))
                    row = cursor.fetchone()
                    if row:
                        # Convertir admin en StaffUser
                        return StaffUser(
                            staff_id=row['cin'],
                            name=row['nom'],
                            email=row['email'],
                            password=row['mot_de_passe'],
                            role='admin',
                            shift='matin',
                            phone=None,
                            address=None
                        )
            
            conn.close()
            
            if row:
                return StaffUser(
                    staff_id=row['cin'],
                    name=row['nom'],
                    email=row['email'],
                    password=row['mot_de_passe'],
                    role=row['role'],
                    shift=row['poste_periode_travail'] or 'matin',
                    phone=row['numero_de_telephone'],
                    address=row['adresse']
                )
            return None
            
        except Exception as e:
            print(f"ERREUR get_staff_by_email: {e}")
            return None
    
    def create_staff(self, staff: StaffUser) -> StaffUser:
        try:
            conn = self.get_connection()
            with conn.cursor() as cursor:
                cursor.execute("""
                    INSERT INTO staff (cin, nom, email, mot_de_passe, role, poste_periode_travail, numero_de_telephone, adresse) 
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                """, (staff.staff_id, staff.name, staff.email, staff.password, staff.role, staff.shift, staff.phone, staff.address))
            
            conn.close()
            return staff
            
        except Exception as e:
            print(f"ERREUR create_staff: {e}")
            raise
    
    def update_staff(self, staff_id: str, staff: StaffUser) -> Optional[StaffUser]:
        try:
            conn = self.get_connection()
            with conn.cursor() as cursor:
                cursor.execute("""
                    UPDATE staff SET nom=%s, email=%s, mot_de_passe=%s, role=%s, poste_periode_travail=%s, numero_de_telephone=%s, adresse=%s
                    WHERE cin=%s
                """, (staff.name, staff.email, staff.password, staff.role, staff.shift, staff.phone, staff.address, staff_id))
            
            conn.close()
            return staff
            
        except Exception as e:
            print(f"ERREUR update_staff: {e}")
            return None
    
    # User operations (adaptées pour la structure MySQL)
    def get_all_users(self) -> List[Dict]:
        try:
            conn = self.get_connection()
            with conn.cursor() as cursor:
                cursor.execute("""
                    SELECT u.*, c.sim_de_la_canne, c.version, c.statut as cane_statut, c.type as cane_type
                    FROM utilisateur u 
                    LEFT JOIN canne c ON u.sim_de_la_canne = c.sim_de_la_canne
                """)
                rows = cursor.fetchall()
            
            conn.close()
            
            # Mapping pour compatibilité front-end (identique à SQLite)
            result_rows = []
            for row in rows:
                d = dict(row)
                d['user_id'] = d.get('cin')
                d['address'] = d.get('adresse')
                d['phone_number_malvoyant'] = d.get('numero_de_telephone')
                d['phone_number_famille'] = d.get('contact_familial')
                d['health_notes'] = d.get('etat_de_sante')
                d['is_online'] = True
                d['status'] = 'normal'
                result_rows.append(d)
                
            return result_rows
            
        except Exception as e:
            print(f"ERREUR get_all_users: {e}")
            return []
    
    def get_user(self, user_id: str) -> Optional[Dict]:
        try:
            conn = self.get_connection()
            with conn.cursor() as cursor:
                cursor.execute("""
                    SELECT u.*, c.sim_de_la_canne, c.version, c.statut as cane_statut, c.type as cane_type
                    FROM utilisateur u 
                    LEFT JOIN canne c ON u.sim_de_la_canne = c.sim_de_la_canne
                    WHERE u.cin = %s
                """, (user_id,))
                row = cursor.fetchone()
            
            conn.close()
            return row
            
        except Exception as e:
            print(f"ERREUR get_user: {e}")
            return None
    
    def create_user(self, user_data: Dict) -> Dict:
        try:
            conn = self.get_connection()
            with conn.cursor() as cursor:
                cursor.execute("""
                    INSERT INTO utilisateur (cin, nom, age, adresse, email, numero_de_telephone, contact_familial, etat_de_sante, sim_de_la_canne) 
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                """, (
                    user_data.get('cin'),
                    user_data.get('nom'),
                    user_data.get('age'),
                    user_data.get('adresse'),
                    user_data.get('email'),
                    user_data.get('numero_de_telephone'),
                    user_data.get('contact_familial'),
                    user_data.get('etat_de_sante'),
                    user_data.get('sim_de_la_canne')
                ))
            
            conn.close()
            return user_data
            
        except Exception as e:
            print(f"ERREUR create_user: {e}")
            raise
    
    def update_user(self, user_data: Dict) -> Dict:
        try:
            conn = self.get_connection()
            with conn.cursor() as cursor:
                cursor.execute("""
                    UPDATE utilisateur SET nom=%s, age=%s, adresse=%s, email=%s, numero_de_telephone=%s, contact_familial=%s, etat_de_sante=%s, sim_de_la_canne=%s
                    WHERE cin=%s
                """, (
                    user_data.get('nom'),
                    user_data.get('age'),
                    user_data.get('adresse'),
                    user_data.get('email'),
                    user_data.get('numero_de_telephone'),
                    user_data.get('contact_familial'),
                    user_data.get('etat_de_sante'),
                    user_data.get('sim_de_la_canne'),
                    user_data.get('cin')
                ))
            
            conn.close()
            return user_data
            
        except Exception as e:
            print(f"ERREUR update_user: {e}")
            raise
    
    def delete_user(self, user_id: str) -> Dict:
        try:
            conn = self.get_connection()
            with conn.cursor() as cursor:
                cursor.execute("DELETE FROM utilisateur WHERE cin = %s", (user_id,))
            
            conn.close()
            return {"status": "success", "message": f"Utilisateur {user_id} supprimé"}
            
        except Exception as e:
            print(f"ERREUR delete_user: {e}")
            raise
    
    # Cane operations
    def get_all_cannes(self) -> List[Dict]:
        try:
            conn = self.get_connection()
            with conn.cursor() as cursor:
                cursor.execute("""
                    SELECT c.*, u.nom as utilisateur_nom, u.cin as utilisateur_cin
                    FROM canne c 
                    LEFT JOIN utilisateur u ON c.sim_de_la_canne = u.sim_de_la_canne
                """)
                rows = cursor.fetchall()
            
            conn.close()
            return rows if rows else []
            
        except Exception as e:
            print(f"ERREUR get_all_cannes: {e}")
            return []
    
    def create_canne(self, cane_data: Dict) -> Dict:
        try:
            conn = self.get_connection()
            with conn.cursor() as cursor:
                cursor.execute("""
                    INSERT INTO canne (sim_de_la_canne, version, statut, type) 
                    VALUES (%s, %s, %s, %s)
                """, (
                    cane_data.get('sim_de_la_canne'),
                    cane_data.get('version'),
                    cane_data.get('statut', 'disponible'),
                    cane_data.get('type')
                ))
            
            conn.close()
            return cane_data
            
        except Exception as e:
            print(f"ERREUR create_canne: {e}")
            raise
    
    def update_canne(self, cane_data: Dict) -> Dict:
        try:
            conn = self.get_connection()
            with conn.cursor() as cursor:
                cursor.execute("""
                    UPDATE canne SET version=%s, statut=%s, type=%s
                    WHERE sim_de_la_canne=%s
                """, (
                    cane_data.get('version'),
                    cane_data.get('statut'),
                    cane_data.get('type'),
                    cane_data.get('sim_de_la_canne')
                ))
            
            conn.close()
            return cane_data
            
        except Exception as e:
            print(f"ERREUR update_canne: {e}")
            raise
    
    def delete_canne(self, cane_id: str) -> Dict:
        try:
            conn = self.get_connection()
            with conn.cursor() as cursor:
                cursor.execute("DELETE FROM canne WHERE sim_de_la_canne = %s", (cane_id,))
            
            conn.close()
            return {"status": "success", "message": f"Canne {cane_id} supprimée"}
            
        except Exception as e:
            print(f"ERREUR delete_canne: {e}")
            raise
    
    # Location operations
    def get_all_locations(self) -> List[Dict]:
        try:
            conn = self.get_connection()
            with conn.cursor() as cursor:
                cursor.execute("""
                    SELECT l.*, u.nom as utilisateur_nom, c.version as canne_version
                    FROM location l
                    JOIN utilisateur u ON l.cin_utilisateur = u.cin
                    JOIN canne c ON l.sim_de_la_canne = c.sim_de_la_canne
                """)
                rows = cursor.fetchall()
            
            conn.close()
            return rows if rows else []
            
        except Exception as e:
            print(f"ERREUR get_all_locations: {e}")
            return []
    
    def create_location(self, location_data: Dict) -> Dict:
        try:
            conn = self.get_connection()
            with conn.cursor() as cursor:
                cursor.execute("""
                    INSERT INTO location (sim_de_la_canne, cin_utilisateur, date_de_location, date_de_retour) 
                    VALUES (%s, %s, %s, %s)
                """, (
                    location_data.get('sim_de_la_canne'),
                    location_data.get('cin_utilisateur'),
                    location_data.get('date_de_location'),
                    location_data.get('date_de_retour')
                ))
            
            conn.close()
            return location_data
            
        except Exception as e:
            print(f"ERREUR create_location: {e}")
            raise
    
    def update_location(self, location_data: Dict) -> Dict:
        try:
            conn = self.get_connection()
            with conn.cursor() as cursor:
                cursor.execute("""
                    UPDATE location SET date_de_retour=%s
                    WHERE sim_de_la_canne=%s AND cin_utilisateur=%s AND date_de_location=%s
                """, (
                    location_data.get('date_de_retour'),
                    location_data.get('sim_de_la_canne'),
                    location_data.get('cin_utilisateur'),
                    location_data.get('date_de_location')
                ))
            
            conn.close()
            return location_data
            
        except Exception as e:
            print(f"ERREUR update_location: {e}")
            raise
    
    def delete_location(self, sim_canne: str, cin_user: str, date_loc: str) -> Dict:
        try:
            conn = self.get_connection()
            with conn.cursor() as cursor:
                cursor.execute("""
                    DELETE FROM location 
                    WHERE sim_de_la_canne=%s AND cin_utilisateur=%s AND date_de_location=%s
                """, (sim_canne, cin_user, date_loc))
            
            conn.close()
            return {"status": "success", "message": "Location supprimée"}
            
        except Exception as e:
            print(f"ERREUR delete_location: {e}")
            raise
    
    # Abonnement operations
    def get_all_abonnements(self) -> List[Dict]:
        try:
            conn = self.get_connection()
            with conn.cursor() as cursor:
                cursor.execute("""
                    SELECT a.*, u.nom as utilisateur_nom, c.version as canne_version
                    FROM abonnement a
                    JOIN utilisateur u ON a.cin_utilisateur = u.cin
                    JOIN canne c ON a.sim_de_la_canne = c.sim_de_la_canne
                """)
                rows = cursor.fetchall()
            
            conn.close()
            return rows if rows else []
            
        except Exception as e:
            print(f"ERREUR get_all_abonnements: {e}")
            return []
    
    def create_abonnement(self, abonnement_data: Dict) -> Dict:
        try:
            conn = self.get_connection()
            with conn.cursor() as cursor:
                cursor.execute("""
                    INSERT INTO abonnement (sim_de_la_canne, cin_utilisateur, type_d_abonnement, date_de_debut, date_de_fin) 
                    VALUES (%s, %s, %s, %s, %s)
                """, (
                    abonnement_data.get('sim_de_la_canne'),
                    abonnement_data.get('cin_utilisateur'),
                    abonnement_data.get('type_d_abonnement'),
                    abonnement_data.get('date_de_debut'),
                    abonnement_data.get('date_de_fin')
                ))
            
            conn.close()
            return abonnement_data
            
        except Exception as e:
            print(f"ERREUR create_abonnement: {e}")
            raise
    
    def update_abonnement(self, abonnement_data: Dict) -> Dict:
        try:
            conn = self.get_connection()
            with conn.cursor() as cursor:
                cursor.execute("""
                    UPDATE abonnement SET type_d_abonnement=%s, date_de_fin=%s
                    WHERE sim_de_la_canne=%s AND cin_utilisateur=%s AND date_de_debut=%s
                """, (
                    abonnement_data.get('type_d_abonnement'),
                    abonnement_data.get('date_de_fin'),
                    abonnement_data.get('sim_de_la_canne'),
                    abonnement_data.get('cin_utilisateur'),
                    abonnement_data.get('date_de_debut')
                ))
            
            conn.close()
            return abonnement_data
            
        except Exception as e:
            print(f"ERREUR update_abonnement: {e}")
            raise
    
    def delete_abonnement(self, sim_canne: str, cin_user: str, date_debut: str) -> Dict:
        try:
            conn = self.get_connection()
            with conn.cursor() as cursor:
                cursor.execute("""
                    DELETE FROM abonnement 
                    WHERE sim_de_la_canne=%s AND cin_utilisateur=%s AND date_de_debut=%s
                """, (sim_canne, cin_user, date_debut))
            
            conn.close()
            return {"status": "success", "message": "Abonnement supprimé"}
            
        except Exception as e:
            print(f"ERREUR delete_abonnement: {e}")
            raise

    # Password Reset operations
    def save_reset_code(self, email: str, code: str, expires_at: datetime):
        try:
            conn = self.get_connection()
            with conn.cursor() as cursor:
                cursor.execute("""
                    INSERT INTO reset_codes (email, code, expires_at) 
                    VALUES (%s, %s, %s)
                    ON DUPLICATE KEY UPDATE code=%s, expires_at=%s
                """, (email, code, expires_at, code, expires_at))
            conn.close()
        except Exception as e:
            print(f"ERREUR save_reset_code: {e}")

    def get_reset_code(self, email: str) -> Optional[Dict]:
        try:
            conn = self.get_connection()
            with conn.cursor() as cursor:
                cursor.execute("SELECT code, expires_at FROM reset_codes WHERE email = %s", (email,))
                row = cursor.fetchone()
            conn.close()
            if row:
                return {"code": row['code'], "expires_at": row['expires_at']}
            return None
        except Exception as e:
            print(f"ERREUR get_reset_code: {e}")
            return None

    def delete_reset_code(self, email: str):
        try:
            conn = self.get_connection()
            with conn.cursor() as cursor:
                cursor.execute("DELETE FROM reset_codes WHERE email = %s", (email,))
            conn.close()
        except Exception as e:
            print(f"ERREUR delete_reset_code: {e}")

    # Alert operations
    def get_all_alerts(self) -> List[Alert]:
        try:
            conn = self.get_connection()
            with conn.cursor() as cursor:
                cursor.execute("SELECT * FROM alerts ORDER BY timestamp DESC")
                rows = cursor.fetchall()
            conn.close()
            return [Alert(
                alert_id=row['alert_id'], 
                user_id=row['user_id'], 
                type=row['type'],
                latitude=row['latitude'], 
                longitude=row['longitude'], 
                timestamp=row['timestamp'],
                status=row['status'], 
                resolved_by=row['resolved_by'],
                resolved_by_name=row['resolved_by_name'],
                resolved_at=row['resolved_at'],
                taken_by=row['taken_by'],
                taken_by_name=row['taken_by_name']
            ) for row in rows]
        except Exception as e:
            print(f"ERREUR get_all_alerts: {e}")
            return []

    def resolve_alert(self, alert_id: str, staff_id: str, staff_name: str) -> bool:
        try:
            conn = self.get_connection()
            with conn.cursor() as cursor:
                cursor.execute("""
                    UPDATE alerts 
                    SET status='resolved', resolved_by=%s, resolved_by_name=%s, resolved_at=%s
                    WHERE alert_id=%s
                """, (staff_id, staff_name, datetime.now().isoformat(), alert_id))
                success = cursor.rowcount > 0
            conn.close()
            return success
        except Exception as e:
            print(f"ERREUR resolve_alert: {e}")
            return False

    def take_alert(self, alert_id: str, staff_id: str, staff_name: str) -> bool:
        try:
            conn = self.get_connection()
            with conn.cursor() as cursor:
                cursor.execute("""
                    UPDATE alerts 
                    SET status='taken', taken_by=%s, taken_by_name=%s
                    WHERE alert_id=%s
                """, (staff_id, staff_name, alert_id))
                success = cursor.rowcount > 0
            conn.close()
            return success
        except Exception as e:
            print(f"ERREUR take_alert: {e}")
            return False

    def release_alert(self, alert_id: str) -> bool:
        try:
            conn = self.get_connection()
            with conn.cursor() as cursor:
                cursor.execute("""
                    UPDATE alerts 
                    SET status='active', taken_by=NULL, taken_by_name=NULL
                    WHERE alert_id=%s
                """, (alert_id,))
                success = cursor.rowcount > 0
            conn.close()
            return success
        except Exception as e:
            print(f"ERREUR release_alert: {e}")
            return False

    def reactivate_alert(self, alert_id: str, staff_id: str, staff_name: str) -> bool:
        try:
            conn = self.get_connection()
            with conn.cursor() as cursor:
                cursor.execute("""
                    UPDATE alerts 
                    SET status='active', reactivated_by=%s, reactivated_by_name=%s, reactivated_at=%s
                    WHERE alert_id=%s
                """, (staff_id, staff_name, datetime.now().isoformat(), alert_id))
                success = cursor.rowcount > 0
            conn.close()
            return success
        except Exception as e:
            print(f"ERREUR reactivate_alert: {e}")
            return False

    def delete_alert(self, alert_id: str) -> bool:
        try:
            conn = self.get_connection()
            with conn.cursor() as cursor:
                cursor.execute("DELETE FROM alerts WHERE alert_id=%s", (alert_id,))
                success = cursor.rowcount > 0
            conn.close()
            return success
        except Exception as e:
            print(f"ERREUR delete_alert: {e}")
            return False

    def clear_alert_history(self) -> bool:
        try:
            conn = self.get_connection()
            with conn.cursor() as cursor:
                cursor.execute("DELETE FROM alerts WHERE status='resolved'")
                success = cursor.rowcount > 0
            conn.close()
            return success
        except Exception as e:
            print(f"ERREUR clear_alert_history: {e}")
            return False

# Instance globale de la base de données
db = MySQLDatabaseManager()

# Test de connexion au démarrage
if not db.test_connection():
    print("AVERTISSEMENT: Impossible de se connecter à la base de données MySQL")
    # On n'appelle pas seed ici car la connexion a échoué
else:
    # Insérer les données par défaut si nécessaire
    db.seed_default_data()
