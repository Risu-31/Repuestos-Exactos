# Repuestos Exactos

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
