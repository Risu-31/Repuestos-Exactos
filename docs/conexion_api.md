# Conexión de Flutter con RE-api

## Ejecutar en web

Primero iniciar la API desde su carpeta:

```powershell
cd C:\Users\felip\source\repos\RE-api
dart pub get
dart pub global run dart_frog_cli:dart_frog dev --port 8081
```

En otra terminal:

```powershell
cd C:\Users\felip\source\repos\Repuestos-Exactos
flutter pub get
flutter run -d web-server --web-port 8080 --web-hostname localhost
```

Abrir http://localhost:8080. La app comienza en el login. Usar un usuario existente; las semillas incluyen admin@losaromos.example, admin@nuble.example y cuentas de mecánico/auditor. La contraseña de esos usuarios es CLAVE_DEMO del .env de RE-db. APP_BACKEND_PASSWORD corresponde a la conexión de la API con PostgreSQL, no al login.

Si la API estaba ejecutándose antes de agregar CORS, reiniciarla.

## Dirección de la API

Se configura con --dart-define=API_BASE_URL=http://localhost:8081. Por defecto web y escritorio usan localhost:8081; Android usa 10.0.2.2:8081 (emulador). Un dispositivo físico necesita una dirección accesible del servidor y su configuración de red. La conexión del dispositivo con la base siempre pasa por la API.

En RE-api, CORS_ALLOWED_ORIGINS admite una lista separada por comas de orígenes exactos. Los valores locales por defecto son http://localhost:8080 y http://127.0.0.1:8080. Si se cambia el puerto del frontend, ajustar esa lista y reiniciar la API. No se usan comodines.

Android declara permiso de Internet y permite HTTP solo en el manifiesto de depuración para desarrollo local. Las configuraciones móviles de producción deben usar HTTPS. La validación de esta etapa se realiza en web y pruebas de Dart/Flutter; no se afirma una prueba en dispositivos Android/iOS físicos.

## Flujo implementado

1. El formulario valida campos y envía POST /auth/login mediante el repositorio y Dio.
2. El token se conserva únicamente en memoria y se adjunta a las peticiones protegidas.
3. GET /auth/me verifica la sesión; GET /settings carga el taller real.
4. Inicio muestra el nombre autenticado y el taller. Ajustes muestra perfil, moneda y margen del taller, con carga, error y reintento.
5. Una respuesta 401 de la sesión actual o su vencimiento devuelve al login y borra la identidad y el taller. Una respuesta tardía de una sesión anterior no elimina la sesión nueva.
6. Cerrar sesión llama a POST /auth/logout y elimina los datos locales. Si la red falla, se informa que el cierre solo pudo confirmarse en el dispositivo.

Al recargar/cerrar la app hay que iniciar sesión nuevamente. Reiniciar la API invalida sus sesiones. El tema claro/oscuro se mantiene como preferencia de la sesión local; no se guarda mediante la API, que actualmente solo ofrece GET /settings. Historial consulta datos reales del taller mediante GET /sessions. Búsqueda consulta el catálogo real; la captura de diagnóstico conserva el alcance de prototipo de la etapa anterior.

## Organización

- core/network: configuración, cliente Dio y lectura validada de JSON.
- features/auth/domain: entidad y contrato de autenticación.
- features/auth/data: serialización y consumo de rutas.
- features/auth/presentation: controlador de sesión y pantalla de acceso.
- features/settings/domain y data: contrato, entidad y lectura del taller.
- features/history: entidades, contrato, DTO, repositorio API, controlador y pantalla de historial.
- core/routing: navegación con acceso condicionado a la sesión.

No se registran contraseñas ni tokens en logs; no se usa almacenamiento del navegador para conservarlos.

## Pruebas

```powershell
flutter analyze
flutter test
```

La prueba real de repositorios se activa con TEST_API_URL y TEST_DEMO_PASSWORD en el entorno de pruebas. No guardar la contraseña en archivos versionados ni introducirla como argumento del proceso. Las pruebas de widgets usan repositorios simulados; las pruebas de red verifican cabeceras, errores 401 y respuestas tardías.

## Historial de diagnósticos

La pantalla Historial ahora consume GET /sessions con filtros y paginación. Guía: [historial.md](historial.md). La búsqueda ya está integrada; la captura real de diagnósticos sigue pendiente.

## Búsqueda y compatibilidad

La pantalla Búsqueda consume marcas, modelos, códigos DTC, repuestos y VIN local según el rol. Guía: [busqueda.md](busqueda.md).
