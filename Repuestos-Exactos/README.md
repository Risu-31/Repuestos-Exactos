# Repuestos Exactos

> **Integración actual:** login con RE-api, sesión Bearer, datos reales del taller en Inicio y Ajustes e historial de diagnósticos con filtros y paginación, además de búsqueda real de catálogo y compatibilidad. Guía: [Conexión con la API](docs/conexion_api.md). La captura de diagnósticos conserva su alcance de prototipo. Guía de búsqueda: [Búsqueda conectada](docs/busqueda.md).

> **"Para mecánicos de talleres automotrices que sufren de falta de información al cotizar repuestos, Repuestos Exactos interpreta el diagnóstico OBD2 y entrega una matriz comparativa instantánea basada en coste, durabilidad y riesgos, optimizando el tiempo y la decisión de compra."**

---

## 🏛️ Contexto Académico
- **Institución**: Universidad Mayor
- **Asignatura**: Arquitectura de Desarrollo Web y Móvil
- **Profesor**: Carlos Muñoz
- **Fecha**: Agosto / Septiembre 2026

## 👥 Equipo de Desarrollo
* **Javier Chandía**
* **Adrián Perugini**
* **Matías Daza**
* **Victoria Escobar**

---

## 📋 Descripción del Proyecto
Repuestos Exactos es una solución de software móvil orientada al sector automotriz, diseñada para optimizar el flujo de trabajo en talleres mecánicos. La plataforma integra diagnóstico automotriz en tiempo real mediante escáneres OBD-II y un motor de cotización multifuente. Su objetivo principal es resolver la asimetría de información en la adquisición de repuestos, traduciendo códigos de falla técnicos (DTC) en un análisis comercial estructurado y eficiente para la toma de decisiones informada.

### Público Objetivo
Mecánicos profesionales y administradores de talleres automotrices que utilizan herramientas de diagnóstico OBD-II y requieren optimizar tiempos y recursos financieros en la adquisición de componentes vehiculares.

---

## ⚙️ Características Principales

* **Integración Diagnóstica (OBD-II):** Módulo de comunicación vía Bluetooth con dispositivos de escaneo automotriz para la extracción e interpretación de códigos de falla (DTC).
* **Identificación Vehicular Automatizada:** Lectura del número de identificación vehicular (VIN) a través del protocolo OBD-II, con respaldo de ingreso manual (Marca, Modelo, Año, Motor).
* **Motor de Cotización Multifuente:** Integración mediante API RESTful con plataformas de comercio electrónico consolidadas e índices locales de precios en moneda local (CLP).
* **Matriz Comparativa de Componentes (3 Perfiles):**
    * 🔴 **Perfil Económico (Genérico):** Menor costo inicial, advirtiendo sobre posibles limitaciones de vida útil y mayor riesgo de falla prematura.
    * 🟡 **Perfil Práctico (OEM):** Relación precio-calidad óptima basada en rendimiento comprobado en el sector.
    * 🟢 **Perfil Óptimo (Genuino):** Componentes originales de fabricante para garantizar máxima durabilidad y garantía.
* **Interfaz de Usuario (UI/UX) Moderna:** Diseño de interfaz móvil con soporte de Modo Oscuro / Modo Claro, animaciones interactivas y visualización de datos comprensibles.

---

## 🏗️ Arquitectura del Sistema
El desarrollo de la plataforma se estructura utilizando principios de Clean Architecture y el modelo C4 (Niveles 1 y 2):
* **Frontend:** Aplicación móvil en Flutter con separación por capas (`core`, `features`, `data`, `presentation`).
* **Backend:** Arquitectura orientada a servicios basada en API RESTful (planificada para Hito 2).
* **Base de Datos:** Modelo relacional optimizado en carpeta `/db`.

---

## 📌 Entregables del Hito 1 (Front-End y Arquitectura)
- **Prototipo Navegable**: Implementado en Flutter con 5 pantallas conectadas y simulación de flujo real.
- **Documentación Completa**: Localizada en [`/docs`](docs/guia_explicativa_h1.md) (Guía para no programadores y desglose técnico de pantallas).
- **Estructura de Arquitectura Limpia**:
  - `lib/core/`: Sistema de temas (`AppTheme`, `ThemeProvider`) y enrutador declarativo (`appRouter` con `go_router`).
  - `lib/features/`: Módulos independientes por funcionalidad (`home`, `diagnostic`, `search`, `history`, `settings`).
  - `lib/data/`: Modelos de datos y repositorios simulados para pruebas de dominio automotriz.
  - `db/`: Carpeta con esquemas para base de datos relacional.

### Pantallas del Prototipo
1. **Inicio (`/`)**: Dashboard con accesos rápidos, métricas de escaneo del día y botón directo al diagnóstico.
2. **Diagnóstico OBD2 en Vivo (`/diagnostic`)**: Radar de búsqueda Bluetooth interactivo y despliegue de matriz comparativa (Genuino vs. OEM vs. Genérico).
3. **Búsqueda Manual (`/search`)**: Formulario por VIN o Marca/Modelo/Año con catálogo interactivo.
4. **Historial de Escaneos (`/history`)**: Registro de vehículos atendidos con filtros por estado.
5. **Configuración (`/settings`)**: Selector de Modo Claro / Modo Oscuro y preferencias de taller.

---

## 🚀 Guía Paso a Paso para Integrantes del Grupo (Cómo probar la app en 3 minutos)

Para cualquier integrante del equipo que clone este repositorio y quiera probarlo en su computadora:

### Paso 1: Prerrequisitos
- Tener instalado **Flutter** en el sistema ([flutter.dev](https://docs.flutter.dev/get-started/install)).
- Navegador web (Microsoft Edge, Google Chrome, etc.).

### Paso 2: Descargar dependencias
Abre una terminal en la carpeta del proyecto y ejecuta:
```bash
flutter pub get
```

### Paso 3: Iniciar el servidor local
```bash
flutter run -d web-server --web-port 8080 --web-hostname localhost
```

### Paso 4: Abrir en el navegador
Abre tu navegador y entra a:
👉 **`http://localhost:8080`**

### Paso 5: Vista de Celular Móvil 📲
1. Presiona **`F12`** en la ventana del navegador.
2. Presiona **`Ctrl` + `Shift` + `M`** (Modo Dispositivo).
3. Selecciona **iPhone 14 Pro Max** o **Pixel 7** en la parte superior y pon el zoom al **100%**.
**********************************************************************
** Visual Studio 2026 Developer PowerShell v18.10.3
** Copyright (c) 2026 Microsoft Corporation
**********************************************************************
PS C:\Repuestos_Exactos> ls


    Directorio: C:\Repuestos_Exactos


Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d-----        18-10-2026     19:02                .postman
d-----        18-10-2026     19:58                .vs
d-----        18-10-2026     19:50                Backend_Repuestos_Exactos
d-----        18-10-2026     19:02                postman
d-----        11-10-2026     11:32                RE-db
d-----        18-10-2026     15:20                Repuestos-Exactos


PS C:\Repuestos_Exactos> cd .\Repuestos-Exactos\
PS C:\Repuestos_Exactos\Repuestos-Exactos> flutter pub get flutter run -d windows
Could not find an option or flag "-d".

Usage: dart pub get
-h, --help                Print this usage information.
    --[no-]offline        Use cached packages instead of accessing the network.
-n, --dry-run             Report what dependencies would change but don't change any.
    --enforce-lockfile    Enforce pubspec.lock. Fail `pub get` if the current `pubspec.lock` does not exactly specify a valid resolution of
                          `pubspec.yaml` or if any content hash of a hosted package has changed.
                          Useful for CI or deploying to production.
    --[no-]precompile     Build executables in immediate dependencies.
    --[no-]example        Also run in `example/` (if it exists).
                          (defaults to on)
-C, --directory=<dir>     Run this in the directory <dir>.

Run "dart help" to see global options.
See https://dart.dev/tools/pub/cmd/pub-get for detailed documentation.
Failed to update packages.
PS C:\Repuestos_Exactos\Repuestos-Exactos> flutter pub get
Resolving dependencies...
Downloading packages...
  code_assets 1.2.1 (2.1.0 available)
  cupertino_icons 1.0.9 (2.0.0 available)
  cupertino_ui 1.0.2 (1.1.3 available)
  go_router 18.0.1 (18.1.0 available)
  google_fonts 8.2.1 (9.0.0 available)
  hooks 2.0.2 (2.2.0 available)
  jni 1.0.3 (1.1.0 available)
  jni_flutter 1.0.3 (1.0.4+1 available)
  material_color_utilities 0.13.0 (0.13.1 available)
  material_ui 1.1.1 (1.7.0 available)
  meta 1.18.3 (1.19.0 available)
  objective_c 9.5.0 (9.6.2 available)
  record_use 0.6.0 (1.1.1 available)
  test_api 0.7.12 (0.7.15 available)
  vector_math 2.4.0 (2.4.3 available)
  vm_service 15.3.0 (15.4.0 available)
Got dependencies!
16 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
PS C:\Repuestos_Exactos\Repuestos-Exactos> flutter pub get flutter run -d windows
Could not find an option or flag "-d".

Usage: dart pub get
-h, --help                Print this usage information.
    --[no-]offline        Use cached packages instead of accessing the network.
-n, --dry-run             Report what dependencies would change but don't change any.
    --enforce-lockfile    Enforce pubspec.lock. Fail `pub get` if the current `pubspec.lock` does not exactly specify a valid resolution of
                          `pubspec.yaml` or if any content hash of a hosted package has changed.
                          Useful for CI or deploying to production.
    --[no-]precompile     Build executables in immediate dependencies.
    --[no-]example        Also run in `example/` (if it exists).
                          (defaults to on)
-C, --directory=<dir>     Run this in the directory <dir>.

Run "dart help" to see global options.
See https://dart.dev/tools/pub/cmd/pub-get for detailed documentation.
Failed to update packages.
PS C:\Repuestos_Exactos\Repuestos-Exactos> flutter run -d web-server --web-port 8080 --web-hostname localhost
Resolving dependencies...
Downloading packages...
  code_assets 1.2.1 (2.1.0 available)
  cupertino_icons 1.0.9 (2.0.0 available)
  cupertino_ui 1.0.2 (1.1.3 available)
  go_router 18.0.1 (18.1.0 available)
  google_fonts 8.2.1 (9.0.0 available)
  hooks 2.0.2 (2.2.0 available)
  jni 1.0.3 (1.1.0 available)
  jni_flutter 1.0.3 (1.0.4+1 available)
  material_color_utilities 0.13.0 (0.13.1 available)
  material_ui 1.1.1 (1.7.0 available)
  meta 1.18.3 (1.19.0 available)
  objective_c 9.5.0 (9.6.2 available)
  record_use 0.6.0 (1.1.1 available)
  test_api 0.7.12 (0.7.15 available)
  vector_math 2.4.0 (2.4.3 available)
  vm_service 15.3.0 (15.4.0 available)
Got dependencies!
16 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
Launching lib\main.dart on Web Server in debug mode...
Failed to bind web development server:
SocketException: Failed to create server socket (OS Error: Solo se permite un uso de cada dirección de socket (protocolo/dirección de
red/puerto), errno = 10048), address = localhost, port = 8080
#0      _NativeSocket.bind (dart:io-patch/socket_patch.dart:1248:7)
<asynchronous suspension>
#1      _RawServerSocket.bind.<anonymous closure> (dart:io-patch/socket_patch.dart:2195:12)
<asynchronous suspension>
#2      _ServerSocket.bind.<anonymous closure> (dart:io-patch/socket_patch.dart:2515:12)
<asynchronous suspension>
#3      _HttpServer.bind.<anonymous closure> (dart:_http/http_impl.dart:3479:24)
<asynchronous suspension>
#4      WebAssetServer.start (package:flutter_tools/src/isolated/web_asset_server.dart:243:24)
<asynchronous suspension>
#5      WebDevFS.create (package:flutter_tools/src/isolated/devfs_web.dart:217:22)
<asynchronous suspension>
#6      ResidentWebRunner.run.<anonymous closure> (package:flutter_tools/src/isolated/resident_web_runner.dart:330:19)
<asynchronous suspension>
#7      asyncGuard.<anonymous closure> (package:flutter_tools/src/base/async_guard.dart:108:24)
<asynchronous suspension>

Failed to bind web development server:
SocketException: Failed to create server socket (OS Error: Solo se permite un uso de cada dirección de socket (protocolo/dirección de
red/puerto), errno = 10048), address = localhost, port = 8080
PS C:\Repuestos_Exactos\Repuestos-Exactos> flutter run -d web-server --web-port 8080 --web-hostname localhost
Resolving dependencies...
Downloading packages...
  code_assets 1.2.1 (2.1.0 available)
  cupertino_icons 1.0.9 (2.0.0 available)
  cupertino_ui 1.0.2 (1.1.3 available)
  go_router 18.0.1 (18.1.0 available)
  google_fonts 8.2.1 (9.0.0 available)
  hooks 2.0.2 (2.2.0 available)
  jni 1.0.3 (1.1.0 available)
  jni_flutter 1.0.3 (1.0.4+1 available)
  material_color_utilities 0.13.0 (0.13.1 available)
  material_ui 1.1.1 (1.7.0 available)
  meta 1.18.3 (1.19.0 available)
  objective_c 9.5.0 (9.6.2 available)
  record_use 0.6.0 (1.1.1 available)
  test_api 0.7.12 (0.7.15 available)
  vector_math 2.4.0 (2.4.3 available)
  vm_service 15.3.0 (15.4.0 available)
Got dependencies!
16 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
Launching lib\main.dart on Web Server in debug mode...
Waiting for connection from debug service on Web Server...         67,3s
lib\main.dart is being served at http://localhost:8080
The web-server device requires the Dart Debug Chrome extension for debugging. Consider using the Chrome or Edge devices for an improved
development workflow.

Flutter run key commands.
r Hot reload.
R Hot restart.
h List all available interactive commands.
d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).

Debug service listening on ws://127.0.0.1:55851/9Fxt67EMT9Y=/ws
A Dart VM Service on Web Server is available at: http://127.0.0.1:55851/9Fxt67EMT9Y=
The Flutter DevTools debugger and profiler on Web Server is available at:
http://127.0.0.1:55851/9Fxt67EMT9Y=/devtools/?uri=ws://127.0.0.1:55851/9Fxt67EMT9Y=/ws
¿Desea terminar el trabajo por lotes (S/N)? n
PS C:\Repuestos_Exactos\Repuestos-Exactos>