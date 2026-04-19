# Smart Cane API Documentation

This document outlines the REST API endpoints available in the Smart Cane Backend.
Base URL: `http://localhost:8000` (or your active production/staging host).

> [!TIP]
> The backend relies heavily on `FastAPI`. You can navigate to `http://localhost:8000/docs` while the server is running to view the interactive Swagger/OpenAPI UI.

---

## 1. Users (`/users`)
Manage `Client` and `Staff` user accounts dynamically using the role structure.

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/users` | Create a new user (Client or Staff). |
| `GET` | `/users` | Retrieve a list of all users. |
| `GET` | `/users/{cin}` | Retrieve a specific user by their CIN. |
| `PUT` | `/users/{cin}` | Update a user's details. |
| `DELETE` | `/users/{cin}` | Delete a user from the system. |

### Payload Examples (POST `/users`)

**Creating a Client:**
```json
{
  "cin": "12345678",
  "nom": "John Doe",
  "age": 30,
  "adresse": "123 Main St",
  "email": "client@example.com",
  "numero_de_telephone": "555-0100",
  "role": "client",
  "contact_familial": "555-0101",
  "etat_de_sante": "Stable",
  "sim_de_la_canne": "SIM-123"
}
```

**Creating a Staff Member:**
```json
{
  "cin": "87654321",
  "nom": "Admin User",
  "email": "admin@example.com",
  "role": "staff",
  "password_login": "securepassword123"
}
```

---

## 2. Cannes (`/cannes`)
Manage the physical Smart Canes.

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/cannes` | Register a new cane. |
| `GET` | `/cannes` | Retrieve all registered canes. |
| `GET` | `/cannes/{sim_de_la_canne}` | Get specifics for a single cane. |
| `PUT` | `/cannes/{sim_de_la_canne}` | Update cane version, status, or type. |
| `DELETE` | `/cannes/{sim_de_la_canne}` | Delete a cane from the system. |

### Payload Example (POST `/cannes`)
```json
{
  "sim_de_la_canne": "SIM-123",
  "version": "v1.0",
  "statut": "disponible",
  "type": "standard"
}
```

---

## 3. Locations (`/locations`)
Manage cane rentals strictly between clients and specific canes.

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/locations` | Create a new rental agreement. |
| `GET` | `/locations` | List all rentals. |
| `GET` | `/locations/{location_id}` | Retrieve details of a specific rental. |
| `PUT` | `/locations/{location_id}` | Update rental attributes (like `date_de_retour`). |
| `DELETE` | `/locations/{location_id}` | Remove a rental record. |

### Payload Example (POST `/locations`)
```json
{
  "sim_de_la_canne": "SIM-123",
  "cin_utilisateur": "12345678",
  "date_de_retour": "2026-12-31"
}
```

---

## 4. Abonnements (`/abonnements`)
Track active subscriptions tying Users to their Cannes.

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/abonnements` | Register a new subscription. |
| `GET` | `/abonnements` | View all active/inactive subscriptions. |
| `GET` | `/abonnements/{abonnement_id}`| View a specific subscription mapping. |
| `PUT` | `/abonnements/{abonnement_id}`| Update abonnement dates or type. |
| `DELETE` | `/abonnements/{abonnement_id}`| Terminate and delete the subscription record. |

### Payload Example (POST `/abonnements`)
```json
{
  "sim_de_la_canne": "SIM-123",
  "cin_utilisateur": "12345678",
  "type_d_abonnement": "premium",
  "date_de_fin": "2027-01-01"
}
```

---

## 5. Alerts (`/alerts`)
Handle real-time distress or health alerts transmitted by the canes.

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/alerts` | Trigger a new alert. |
| `GET` | `/alerts` | Get the entire alert history. |
| `GET` | `/alerts/{alert_id}` | Fetch data regarding a specific alert. |
| `PUT` | `/alerts/{alert_id}` | Update alert state (e.g. mark as `resolved`). |
| `DELETE` | `/alerts/{alert_id}` | Discard the alert record. |

> [!NOTE]
> If a frontend user updates an alert's `status` to `"resolved"` via the `PUT` endpoint, the backend automatically flags the `resolved_at` property with a UTC Database timestamp!

### Payload Example (POST `/alerts`)
```json
{
  "alert_id": "ALT-999",
  "user_id": "12345678",
  "type": "fall_detected",
  "latitude": 36.8065,
  "longitude": 10.1815
}
```
