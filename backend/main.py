from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from backend.controllers.abonnements_controller import router as abonnements_router
from backend.controllers.alerts_controller import router as alerts_router
from backend.controllers.auth_controller import router as auth_router
from backend.controllers.cannes_controller import router as cannes_router
from backend.controllers.locations_controller import router as locations_router
from backend.controllers.utilisateurs_controller import router as utilisateurs_router
from backend.controllers.messages_controller import router as messages_router
from backend.database import engine, Base
from backend.models import Abonnement, Alert, Canne, Location, Utilisateur, ResetCode


try:
    Base.metadata.create_all(bind=engine)
    print("SUCCES: Tables creees ou deja existantes dans MySQL")
except Exception as exc:
    print(f"ERREUR lors de la creation des tables: {exc}")

app = FastAPI(title="Smart Cane API", version="4.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/", tags=["General"])
def read_root():
    return {"message": "Backend Smart Cane structure avec models, services et controllers"}


app.include_router(utilisateurs_router)
app.include_router(cannes_router)
app.include_router(locations_router)
app.include_router(abonnements_router)
app.include_router(alerts_router)
app.include_router(auth_router)
app.include_router(messages_router)


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("backend.main:app", host="0.0.0.0", port=8000, reload=True)
