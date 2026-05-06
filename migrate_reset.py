import sys
print("Starting migration...")
import os
from sqlalchemy import text
from backend.database import engine, Base
from backend.models import reset_code

try:
    with engine.connect() as conn:
        print("Dropping reset_codes table...")
        conn.execute(text("DROP TABLE IF EXISTS reset_codes"))
        conn.commit()
        print("Recreating reset_codes table...")
    Base.metadata.create_all(bind=engine, tables=[reset_code.ResetCode.__table__])
    print("Migration successful.")
except Exception as e:
    print(f"Error during migration: {e}")
    sys.exit(1)
