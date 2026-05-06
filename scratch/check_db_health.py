from backend.database import engine, Base
from sqlalchemy import inspect

def check_db():
    inspector = inspect(engine)
    tables = inspector.get_table_names()
    print(f"Tables found in DB: {tables}")
    
    required_tables = ["utilisateurs", "cannes", "locations", "abonnements", "alerts"]
    for table in required_tables:
        if table in tables:
            print(f"✅ Table '{table}' exists.")
        else:
            print(f"❌ Table '{table}' is MISSING!")

if __name__ == "__main__":
    check_db()
