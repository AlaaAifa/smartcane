import pymysql
import os
from dotenv import load_dotenv

load_dotenv("backend/.env")

try:
    db = pymysql.connect(
        host=os.getenv("DB_HOST", "localhost"),
        user=os.getenv("DB_USER", "root"),
        password=os.getenv("DB_PASSWORD", ""),
        database=os.getenv("DB_NAME", "smart_cane_db")
    )
    cursor = db.cursor()
    cursor.execute("DESCRIBE utilisateur")
    columns = [col[0] for col in cursor.fetchall()]
    
    if "photo_url" not in columns:
        print("Adding photo_url column...")
        cursor.execute("ALTER TABLE utilisateur ADD COLUMN photo_url LONGTEXT NULL")
    else:
        print("Updating photo_url column to LONGTEXT...")
        cursor.execute("ALTER TABLE utilisateur MODIFY COLUMN photo_url LONGTEXT NULL")
    
    db.commit()
    print("Database updated successfully.")
        
    db.close()
except Exception as e:
    print(f"Error: {e}")
