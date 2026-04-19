import sqlite3
import json
from datetime import datetime, date, timedelta
from typing import Dict, List, Optional
from models import UserDocument, Alert, StaffUser
import os

class SQLiteDatabaseManager:
    def __init__(self, db_path: str = "smart_cane_v2.db"):
        # Make sure the path is relative to the backend directory or absolute
        if not os.path.isabs(db_path) and "backend" not in os.getcwd():
            self.db_path = os.path.join("backend", db_path)
        else:
            self.db_path = db_path
            
        print(f"DEBUG: Configuration SQLite - Path: {self.db_path}")
        self.init_database()
        
    def get_connection(self):
        """Établir une connexion à la base de données SQLite"""
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row  # Pour avoir des dictionnaires
        return conn
    
    def test_connection(self):
        """Tester la connexion à la base de données"""
        try:
            conn = self.get_connection()
            conn.execute("SELECT 1")
            conn.close()
            print("SUCCÈS: Connexion SQLite établie")
            return True
        except Exception as e:
            print(f"ERREUR: Test de connexion SQLite: {e}")
            return False
            
    def init_database(self):
        """Initialiser les tables si elles n'existent pas"""
        conn = self.get_connection()
        cursor = conn.cursor()
        
        # Table Admin
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS admin (
                cin TEXT PRIMARY KEY,
                nom TEXT NOT NULL,
                email TEXT UNIQUE NOT NULL,
                mot_de_passe TEXT NOT NULL
            )
        """)
        
        # Table Staff
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS staff (
                cin TEXT PRIMARY KEY,
                nom TEXT NOT NULL,
                email TEXT UNIQUE NOT NULL,
                mot_de_passe TEXT NOT NULL,
                role TEXT DEFAULT 'staff',
                poste_periode_travail TEXT,
                numero_de_telephone TEXT,
                adresse TEXT,
                cree_le TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        # Table Utilisateur
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS utilisateur (
                cin TEXT PRIMARY KEY,
                nom TEXT NOT NULL,
                prenom TEXT,
                age INTEGER,
                adresse TEXT,
                email TEXT UNIQUE NOT NULL,
                numero_de_telephone TEXT,
                contact_familial TEXT,
                etat_de_sante TEXT,
                sim_de_la_canne TEXT,
                cree_le TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        # Table Canne
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS canne (
                sim_de_la_canne TEXT PRIMARY KEY,
                version TEXT,
                statut TEXT DEFAULT 'disponible',
                type TEXT
            )
        """)
        
        # Table Location
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS location (
                sim_de_la_canne TEXT,
                cin_utilisateur TEXT,
                date_de_location TEXT,
                date_de_retour TEXT,
                PRIMARY KEY (sim_de_la_canne, cin_utilisateur, date_de_location)
            )
        """)
        
        # Table Abonnement
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS abonnement (
                sim_de_la_canne TEXT,
                cin_utilisateur TEXT,
                type_d_abonnement TEXT,
                date_de_debut TEXT,
                date_de_fin TEXT,
                PRIMARY KEY (sim_de_la_canne, cin_utilisateur, date_de_debut)
            )
        """)
        
        # Table Reset Codes
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS reset_codes (
                email TEXT PRIMARY KEY,
                code TEXT NOT NULL,
                expires_at TEXT NOT NULL
            )
        """)

        # Table Alerts (Enhanced with full field support)
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS alerts (
                alert_id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                type TEXT NOT NULL,
                latitude REAL NOT NULL,
                longitude REAL NOT NULL,
                timestamp TEXT NOT NULL,
                status TEXT DEFAULT 'active',
                resolved_by TEXT,
                resolved_by_name TEXT,
                resolved_at TEXT,
                taken_by TEXT,
                taken_by_name TEXT,
                reactivated_by TEXT,
                reactivated_by_name TEXT,
                reactivated_at TEXT
            )
        """)
        
        conn.commit()
        conn.close()
        self.seed_default_data()

    def seed_default_data(self):
        """Insérer les données par défaut si les tables sont vides"""
        conn = self.get_connection()
        cursor = conn.cursor()
        
        # Admin
        cursor.execute("SELECT COUNT(*) FROM admin")
        if cursor.fetchone()[0] == 0:
            cursor.execute("""
                INSERT INTO admin (cin, nom, email, mot_de_passe) 
                VALUES (?, ?, ?, ?)
            """, ("ADMIN001", "Admin Principal", "aifaalaa97@gmail.com", "123456789"))
            print("Admin par défaut inséré")
            
        # Staff
        cursor.execute("SELECT COUNT(*) FROM staff")
        if cursor.fetchone()[0] == 0:
            staff_data = [
                ("STAFF001", "Mohamed Ben Ali", "staff@smartcane.com", "staff123", "staff", "matin", "+216 20 111 222", "Tunis"),
                ("STAFF002", "Sami Mansour", "sami@smartcane.com", "staff123", "staff", "soir", "+216 22 333 444", "Sfax")
            ]
            cursor.executemany("""
                INSERT INTO staff (cin, nom, email, mot_de_passe, role, poste_periode_travail, numero_de_telephone, adresse) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """, staff_data)
            print("Staff par défaut (Matin & Soir) insérés")

        # Demo Users
        cursor.execute("SELECT COUNT(*) FROM utilisateur")
        if cursor.fetchone()[0] == 0:
            demo_users = [
                ("USER456", "Curie", "Marie", 57, "Paris - Tunis", "marie@email.com", "+216 98 765 432", "+216 50 111 222", "En bonne santé", "SIM002"),
                ("USER789", "Edison", "Thomas", 84, "Sfax", "thomas@email.com", "+216 23 000 000", "+216 54 111 222", "Diabète", "SIM003"),
                ("USER001", "Dupont", "Jean", 62, "Tunis", "jean@email.com", "+216 22 123 456", "+216 55 123 456", "Normal", "SIM001")
            ]
            cursor.executemany("INSERT INTO utilisateur (cin, nom, prenom, age, adresse, email, numero_de_telephone, contact_familial, etat_de_sante, sim_de_la_canne) VALUES (?,?,?,?,?,?,?,?,?,?)", demo_users)
            print("Utilisateurs (Marie, Thomas, Jean) insérés")
            
        # Demo Cannes
        cursor.execute("SELECT COUNT(*) FROM canne")
        if cursor.fetchone()[0] == 0:
            demo_cannes = [
                ("SIM001", "Smart Lite", "louee", "location"),
                ("SIM002", "Smart Pro V2", "louee", "abonnement"),
                ("SIM003", "Smart Pro V3", "louee", "location")
            ]
            cursor.executemany("INSERT INTO canne (sim_de_la_canne, version, statut, type) VALUES (?,?,?,?)", demo_cannes)

        # Alerts
        cursor.execute("SELECT COUNT(*) FROM alerts")
        if cursor.fetchone()[0] == 0:
            now = datetime.now()
            demo_alerts = [
                ("ALERT001", "USER456", "SOS", 36.8065, 10.1815, (now - timedelta(minutes=5)).isoformat(), "active", None, None, None, None, None),
                ("ALERT002", "USER789", "HELP", 36.8100, 10.1900, (now - timedelta(minutes=15)).isoformat(), "taken", None, None, None, "STAFF001", "Mohamed Ben Ali"),
                ("ALERT003", "USER001", "SOS", 36.7900, 10.1700, (now - timedelta(hours=2)).isoformat(), "resolved", "STAFF002", "Sami Mansour", (now - timedelta(hours=1)).isoformat(), None, None),
            ]
            cursor.executemany("""
                INSERT INTO alerts (alert_id, user_id, type, latitude, longitude, timestamp, status, resolved_by, resolved_by_name, resolved_at, taken_by, taken_by_name)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, demo_alerts)
            print("Alertes de démonstration insérées")

        conn.commit()
        conn.close()

    # --- API Implementation ---

    def get_staff_by_email(self, email: str) -> Optional[StaffUser]:
        conn = self.get_connection()
        cursor = conn.cursor()
        # Search in staff
        cursor.execute("SELECT * FROM staff WHERE email = ?", (email.lower(),))
        row = cursor.fetchone()
        
        if not row:
            # Search in admin
            cursor.execute("SELECT * FROM admin WHERE email = ?", (email.lower(),))
            row = cursor.fetchone()
            if row:
                conn.close()
                return StaffUser(
                    staff_id=row['cin'], name=row['nom'], email=row['email'],
                    password=row['mot_de_passe'], role='admin', shift='matin', phone=None, address=None
                )
        
        conn.close()
        if row:
            return StaffUser(
                staff_id=row['cin'], name=row['nom'], email=row['email'],
                password=row['mot_de_passe'], role=row['role'], 
                shift=row['poste_periode_travail'] or 'matin',
                phone=row['numero_de_telephone'], address=row['adresse']
            )
        return None

    def get_all_staff(self) -> List[StaffUser]:
        conn = self.get_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM staff")
        rows = cursor.fetchall()
        conn.close()
        return [StaffUser(
            staff_id=row['cin'], name=row['nom'], email=row['email'],
            password=row['mot_de_passe'], role=row['role'],
            shift=row['poste_periode_travail'] or 'matin',
            phone=row['numero_de_telephone'], address=row['adresse']
        ) for row in rows]

    def create_staff(self, staff: StaffUser) -> StaffUser:
        conn = self.get_connection()
        cursor = conn.cursor()
        cursor.execute("""
            INSERT INTO staff (cin, nom, email, mot_de_passe, role, poste_periode_travail, numero_de_telephone, adresse) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, (staff.staff_id, staff.name, staff.email, staff.password, staff.role, staff.shift, staff.phone, staff.address))
        conn.commit()
        conn.close()
        return staff

    def update_staff(self, staff_id: str, staff: StaffUser) -> Optional[StaffUser]:
        conn = self.get_connection()
        cursor = conn.cursor()
        
        # Check if it's an admin first
        cursor.execute("SELECT cin FROM admin WHERE cin = ?", (staff_id,))
        if cursor.fetchone():
            cursor.execute("""
                UPDATE admin SET nom=?, email=?, mot_de_passe=?
                WHERE cin=?
            """, (staff.name, staff.email, staff.password, staff_id))
        else:
            # Otherwise update staff table
            cursor.execute("""
                UPDATE staff SET nom=?, email=?, mot_de_passe=?, role=?, poste_periode_travail=?, numero_de_telephone=?, adresse=?
                WHERE cin=?
            """, (staff.name, staff.email, staff.password, staff.role, staff.shift, staff.phone, staff.address, staff_id))
            
        conn.commit()
        conn.close()
        return staff

    def get_all_users(self) -> List[Dict]:
        conn = self.get_connection()
        cursor = conn.cursor()
        cursor.execute("""
            SELECT u.*, u.cin as user_id, c.version as cane_version, c.statut as cane_statut, c.type as cane_type
            FROM utilisateur u 
            LEFT JOIN canne c ON u.sim_de_la_canne = c.sim_de_la_canne
        """)
        rows = []
        for row in cursor.fetchall():
            d = dict(row)
            # Ensure keys match mock expectations and frontend UI
            d['user_id'] = d.get('cin')
            d['address'] = d.get('adresse')
            d['phone_number_malvoyant'] = d.get('numero_de_telephone')
            d['phone_number_famille'] = d.get('contact_familial')
            d['health_notes'] = d.get('etat_de_sante')
            d['is_online'] = True
            d['status'] = 'normal'
            rows.append(d)
        conn.close()
        return rows

    def get_user(self, user_id: str) -> Optional[Dict]:
        conn = self.get_connection()
        cursor = conn.cursor()
        cursor.execute("""
            SELECT u.*, c.version as cane_version, c.statut as cane_statut, c.type as cane_type
            FROM utilisateur u 
            LEFT JOIN canne c ON u.sim_de_la_canne = c.sim_de_la_canne
            WHERE u.cin = ?
        """, (user_id,))
        row = cursor.fetchone()
        conn.close()
        return dict(row) if row else None

    def create_user(self, user_data: Dict) -> Dict:
        conn = self.get_connection()
        cursor = conn.cursor()
        cursor.execute("""
            INSERT INTO utilisateur (cin, nom, age, adresse, email, numero_de_telephone, contact_familial, etat_de_sante, sim_de_la_canne) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            user_data.get('cin'), user_data.get('nom'), user_data.get('age'),
            user_data.get('adresse'), user_data.get('email'), user_data.get('numero_de_telephone'),
            user_data.get('contact_familial'), user_data.get('etat_de_sante'), user_data.get('sim_de_la_canne')
        ))
        conn.commit()
        conn.close()
        return user_data

    def update_user(self, user_data: Dict) -> Dict:
        conn = self.get_connection()
        cursor = conn.cursor()
        cursor.execute("""
            UPDATE utilisateur SET nom=?, age=?, adresse=?, email=?, numero_de_telephone=?, contact_familial=?, etat_de_sante=?, sim_de_la_canne=?
            WHERE cin=?
        """, (
            user_data.get('nom'), user_data.get('age'), user_data.get('adresse'),
            user_data.get('email'), user_data.get('numero_de_telephone'), user_data.get('contact_familial'),
            user_data.get('etat_de_sante'), user_data.get('sim_de_la_canne'), user_data.get('cin')
        ))
        conn.commit()
        conn.close()
        return user_data

    def delete_user(self, user_id: str) -> Dict:
        conn = self.get_connection()
        cursor = conn.cursor()
        cursor.execute("DELETE FROM utilisateur WHERE cin = ?", (user_id,))
        conn.commit()
        conn.close()
        return {"status": "success", "message": f"Utilisateur {user_id} supprimé"}

    def get_all_cannes(self) -> List[Dict]:
        conn = self.get_connection()
        cursor = conn.cursor()
        cursor.execute("""
            SELECT c.*, u.nom as utilisateur_nom, u.cin as utilisateur_cin
            FROM canne c 
            LEFT JOIN utilisateur u ON c.sim_de_la_canne = u.sim_de_la_canne
        """)
        rows = [dict(row) for row in cursor.fetchall()]
        conn.close()
        return rows

    def create_canne(self, cane_data: Dict) -> Dict:
        conn = self.get_connection()
        cursor = conn.cursor()
        cursor.execute("INSERT INTO canne (sim_de_la_canne, version, statut, type) VALUES (?, ?, ?, ?)",
                    (cane_data.get('sim_de_la_canne'), cane_data.get('version'), cane_data.get('statut', 'disponible'), cane_data.get('type')))
        conn.commit()
        conn.close()
        return cane_data

    def update_canne(self, cane_data: Dict) -> Dict:
        conn = self.get_connection()
        cursor = conn.cursor()
        cursor.execute("UPDATE canne SET version=?, statut=?, type=? WHERE sim_de_la_canne=?",
                    (cane_data.get('version'), cane_data.get('statut'), cane_data.get('type'), cane_data.get('sim_de_la_canne')))
        conn.commit()
        conn.close()
        return cane_data

    def delete_canne(self, cane_id: str) -> Dict:
        conn = self.get_connection()
        cursor = conn.cursor()
        cursor.execute("DELETE FROM canne WHERE sim_de_la_canne = ?", (cane_id,))
        conn.commit()
        conn.close()
        return {"status": "success", "message": f"Canne {cane_id} supprimée"}

    def get_all_locations(self) -> List[Dict]:
        conn = self.get_connection()
        cursor = conn.cursor()
        cursor.execute("""
            SELECT l.*, u.nom as utilisateur_nom, c.version as canne_version
            FROM location l
            LEFT JOIN utilisateur u ON l.cin_utilisateur = u.cin
            LEFT JOIN canne c ON l.sim_de_la_canne = c.sim_de_la_canne
        """)
        rows = [dict(row) for row in cursor.fetchall()]
        conn.close()
        return rows

    def create_location(self, location_data: Dict) -> Dict:
        conn = self.get_connection()
        cursor = conn.cursor()
        
        # Ensure the canne exists in the canne table first
        cursor.execute("INSERT OR IGNORE INTO canne (sim_de_la_canne, version, statut) VALUES (?, ?, ?)",
                    (location_data.get('sim_de_la_canne'), 'Smart Pro V2', 'louee'))

        cursor.execute("INSERT INTO location (sim_de_la_canne, cin_utilisateur, date_de_location, date_de_retour) VALUES (?, ?, ?, ?)",
                    (location_data.get('sim_de_la_canne'), location_data.get('cin_utilisateur'), location_data.get('date_de_location'), location_data.get('date_de_retour')))
        conn.commit()
        conn.close()
        return location_data

    def update_location(self, location_data: Dict) -> Dict:
        conn = self.get_connection()
        cursor = conn.cursor()
        cursor.execute("UPDATE location SET date_de_retour=? WHERE sim_de_la_canne=? AND cin_utilisateur=? AND date_de_location=?",
                    (location_data.get('date_de_retour'), location_data.get('sim_de_la_canne'), location_data.get('cin_utilisateur'), location_data.get('date_de_location')))
        conn.commit()
        conn.close()
        return location_data

    def delete_location(self, sim_canne: str, cin_user: str, date_loc: str) -> Dict:
        conn = self.get_connection()
        cursor = conn.cursor()
        cursor.execute("DELETE FROM location WHERE sim_de_la_canne=? AND cin_utilisateur=? AND date_de_location=?", (sim_canne, cin_user, date_loc))
        conn.commit()
        conn.close()
        return {"status": "success", "message": "Location supprimée"}

    def get_all_abonnements(self) -> List[Dict]:
        conn = self.get_connection()
        cursor = conn.cursor()
        cursor.execute("""
            SELECT a.*, u.nom as utilisateur_nom, c.version as canne_version
            FROM abonnement a
            LEFT JOIN utilisateur u ON a.cin_utilisateur = u.cin
            LEFT JOIN canne c ON a.sim_de_la_canne = c.sim_de_la_canne
        """)
        rows = [dict(row) for row in cursor.fetchall()]
        conn.close()
        return rows

    def create_abonnement(self, abonnement_data: Dict) -> Dict:
        conn = self.get_connection()
        cursor = conn.cursor()
        cursor.execute("INSERT INTO abonnement (sim_de_la_canne, cin_utilisateur, type_d_abonnement, date_de_debut, date_de_fin) VALUES (?, ?, ?, ?, ?)",
                    (abonnement_data.get('sim_de_la_canne'), abonnement_data.get('cin_utilisateur'), abonnement_data.get('type_d_abonnement'), abonnement_data.get('date_de_debut'), abonnement_data.get('date_de_fin')))
        conn.commit()
        conn.close()
        return abonnement_data

    def update_abonnement(self, abonnement_data: Dict) -> Dict:
        conn = self.get_connection()
        cursor = conn.cursor()
        cursor.execute("UPDATE abonnement SET type_d_abonnement=?, date_de_fin=? WHERE sim_de_la_canne=? AND cin_utilisateur=? AND date_de_debut=?",
                    (abonnement_data.get('type_d_abonnement'), abonnement_data.get('date_de_fin'), abonnement_data.get('sim_de_la_canne'), abonnement_data.get('cin_utilisateur'), abonnement_data.get('date_de_debut')))
        conn.commit()
        conn.close()
        return abonnement_data

    def delete_abonnement(self, sim_canne: str, cin_user: str, date_debut: str) -> Dict:
        conn = self.get_connection()
        cursor = conn.cursor()
        cursor.execute("DELETE FROM abonnement WHERE sim_de_la_canne=? AND cin_utilisateur=? AND date_de_debut=?", (sim_canne, cin_user, date_debut))
        conn.commit()
        conn.close()
        return {"status": "success", "message": "Abonnement supprimé"}

    def save_reset_code(self, email: str, code: str, expires_at: datetime):
        conn = self.get_connection()
        cursor = conn.cursor()
        cursor.execute("INSERT OR REPLACE INTO reset_codes (email, code, expires_at) VALUES (?, ?, ?)",
                    (email, code, expires_at.isoformat()))
        conn.commit()
        conn.close()

    def get_reset_code(self, email: str) -> Optional[Dict]:
        conn = self.get_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT code, expires_at FROM reset_codes WHERE email = ?", (email,))
        row = cursor.fetchone()
        conn.close()
        if row:
            return {"code": row['code'], "expires_at": datetime.fromisoformat(row['expires_at'])}
        return None

    def delete_reset_code(self, email: str):
        conn = self.get_connection()
        cursor = conn.cursor()
        cursor.execute("DELETE FROM reset_codes WHERE email = ?", (email,))
        conn.commit()
        conn.close()

    def get_all_alerts(self) -> List[Alert]:
        conn = self.get_connection()
        cursor = conn.cursor()
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

    def resolve_alert(self, alert_id: str, staff_id: str, staff_name: str) -> bool:
        conn = self.get_connection()
        cursor = conn.cursor()
        cursor.execute("""
            UPDATE alerts 
            SET status='resolved', resolved_by=?, resolved_by_name=?, resolved_at=?
            WHERE alert_id=?
        """, (staff_id, staff_name, datetime.now().isoformat(), alert_id))
        conn.commit()
        success = cursor.rowcount > 0
        conn.close()
        return success

    def take_alert(self, alert_id: str, staff_id: str, staff_name: str) -> bool:
        conn = self.get_connection()
        cursor = conn.cursor()
        cursor.execute("""
            UPDATE alerts 
            SET status='taken', taken_by=?, taken_by_name=?
            WHERE alert_id=?
        """, (staff_id, staff_name, alert_id))
        conn.commit()
        success = cursor.rowcount > 0
        conn.close()
        return success

    def release_alert(self, alert_id: str) -> bool:
        conn = self.get_connection()
        cursor = conn.cursor()
        cursor.execute("""
            UPDATE alerts 
            SET status='active', taken_by=NULL, taken_by_name=NULL
            WHERE alert_id=?
        """, (alert_id,))
        conn.commit()
        success = cursor.rowcount > 0
        conn.close()
        return success

    def reactivate_alert(self, alert_id: str, staff_id: str, staff_name: str) -> bool:
        conn = self.get_connection()
        cursor = conn.cursor()
        cursor.execute("""
            UPDATE alerts 
            SET status='active', reactivated_by=?, reactivated_by_name=?, reactivated_at=?
            WHERE alert_id=?
        """, (staff_id, staff_name, datetime.now().isoformat(), alert_id))
        conn.commit()
        success = cursor.rowcount > 0
        conn.close()
        return success

    def delete_alert(self, alert_id: str) -> bool:
        conn = self.get_connection()
        cursor = conn.cursor()
        cursor.execute("DELETE FROM alerts WHERE alert_id=?", (alert_id,))
        conn.commit()
        success = cursor.rowcount > 0
        conn.close()
        return success

    def clear_alert_history(self) -> bool:
        conn = self.get_connection()
        cursor = conn.cursor()
        cursor.execute("DELETE FROM alerts WHERE status='resolved'")
        conn.commit()
        success = cursor.rowcount > 0
        conn.close()
        return success

# Instance globale
db = SQLiteDatabaseManager()
