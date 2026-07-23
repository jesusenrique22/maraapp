# Farma Express — accesos demo

Archivo listo para abrir en Excel / Google Sheets: `ACCESOS-FARMA-EXPRESS.csv`

## Cuentas por rol

| Rol | Email | Clave | Nombre |
|-----|-------|-------|--------|
| **ADMIN** (Super Admin) | `admin@farmaexpress.com` | `Admin123!` | Administrador Farma Express |
| **DOCTOR** | `doctor@farmaexpress.com` | `Doctor123!` | Dr. Juan Pérez |
| **DOCTOR** | `doctor2@farmaexpress.com` | `Doctor123!` | Dra. María González |
| **DOCTOR** | `doctor3@farmaexpress.com` | `Doctor123!` | Dr. Roberto Silva |
| **CUSTOMER** (paciente / tienda) | `patient@farmaexpress.com` | `Patient123!` | Carlos Mendoza |

## Dónde entrar

| Rol | Entrada en la app |
|-----|-------------------|
| ADMIN | Login staff → panel `/admin` |
| DOCTOR | Login staff → dashboard `/doctor` |
| CUSTOMER | Login tienda o Medic Express → home / citas |

Rutas útiles (Flutter web):
- Tienda: `/#/home`
- Login tienda: `/#/login/store`
- Login Medic Express: `/#/login/medic-plus`
- Login staff (admin/doctor): `/#/login/staff`
- Medic Express (paciente): `/#/medic-plus`
- Super Admin: `/#/admin`

## Local vs producción

| Entorno | API | App |
|---------|-----|-----|
| Local | `http://127.0.0.1:3010` | `flutter run -d chrome` |
| Render (si está desplegado) | `https://farmaexpress-api.onrender.com` | `https://farmaexpress.onrender.com` |

## Variables que pide Render (API)

No son “usuarios”, pero las necesitas al desplegar:

| Variable | Ejemplo / valor |
|----------|-----------------|
| `DATABASE_URL` | Neon → Connect → Pooled |
| `DIRECT_URL` | Neon → Connect → Direct |
| `ADMIN_EMAIL` | `admin@farmaexpress.com` |
| `ADMIN_PASSWORD` | `Admin123!` |
| `GEMINI_API_KEY` | opcional |
| `GEMINI_SCAN_API_KEY` | opcional |

## Sedes activas (retiro)

1. Farma Express C-2 (principal) — Circunvalación 2, San Miguel  
2. La 72 — Calle 72 con Av. 12-10  
3. El Milagro — Av. 2 El Milagro (CC Caribe Zulia)  
4. La Limpia — Av. La Limpia  
5. Delicias — Av. Delicias  
6. Fuerzas Armadas — Av. Fuerzas Armadas  
7. Ciudad Chinita — Centro de la ciudad  

---

Solo para demos / desarrollo. Cambia las claves en producción real.
