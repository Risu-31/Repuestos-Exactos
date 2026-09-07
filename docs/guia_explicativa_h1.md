# Guía Explicativa del Prototipo - Repuestos Exactos (Para no programadores)

Este documento explica de forma sencilla y directa cómo funciona la aplicación que hemos creado para el **Hito 1**, qué hace cada pantalla y por qué se diseñó de esta manera. Todo está pensado para que cualquier persona, sin importar su conocimiento técnico, pueda entender el valor de este producto.

---

## 1. ¿Qué es este Prototipo?
Piensa en este prototipo como la "maqueta de una casa" antes de construirla de verdad. Tiene las puertas, las luces, los colores y las habitaciones, pero aún no tiene las tuberías conectadas al agua (eso será el Hito 2). Su objetivo es demostrar visualmente **cómo el mecánico usará la aplicación** para diagnosticar un auto y cotizar repuestos sin perder tiempo.

---

## 2. Explicación de cada Pantalla (El Recorrido del Usuario)

### A. Menú Principal (La Pantalla de Inicio)
**¿Qué es?** Es lo primero que ve el mecánico al abrir la app.
**¿Para qué sirve?**
- Funciona como un tablero de control. Tiene un botón gigante que dice **"Iniciar Escaneo OBD2"** porque sabemos que en un taller hay ruido, el mecánico puede tener guantes y necesita ir directo al grano.
- Además, le muestra un resumen rápido: cuántos autos ha escaneado hoy y cuántas búsquedas ha hecho.

### B. Diagnóstico y Cotización en Tiempo Real (El Corazón de la App)
**¿Qué es?** Es la pantalla que simula estar conectada al escáner físico (OBD2) del vehículo.
**¿Para qué sirve y cómo funciona?**
1. **La Simulación (El Radar):** Cuando el mecánico toca "Escanear", la pantalla muestra un radar y dice "Conectando...". En la vida real, aquí la app está hablando por Bluetooth con el escáner del auto. Para este prototipo, programamos una pausa intencional de 3 segundos para que la experiencia se sienta real.
2. **El Código de Error:** Luego de escanear, la app muestra un código (por ejemplo, **P0171**). Esto significa que el auto tiene una "Mezcla pobre de combustible". El mecánico ya no tiene que buscar en Google qué significa, la app se lo dice directamente.
3. **La Matriz Mágica de Cotización:** Aquí está el valor del proyecto. Debajo del error, la app muestra automáticamente 3 opciones de repuestos para solucionar ese problema:
   - **Una opción Genuina (Original):** Cara, pero dura 80,000 km y no tiene riesgo.
   - **Una opción OEM (Alternativa de alta calidad):** Precio intermedio, dura 60,000 km, riesgo bajo.
   - **Una opción Genérica (Barata):** Muy barata, dura poco y la app la marca en color **Rojo** alertando un riesgo "Alto" de que falle rápido.
   *Con esto, el mecánico puede decirle a su cliente: "Mira, te ofrezco estas 3 opciones, tú decides cuánto quieres gastar".*

### C. Búsqueda Manual (Para cuando no hay Escáner)
**¿Qué es?** Un formulario para buscar piezas a mano.
**¿Para qué sirve?** Si el mecánico sabe cuál es la pieza que está fallando y no necesita usar el escáner, puede entrar aquí, escribir el número de chasis (VIN) del auto, o seleccionar la Marca (Toyota), el Modelo (Hilux) y el Año, y buscar el repuesto exacto que necesita.

### D. Historial
**¿Qué es?** Una agenda automática.
**¿Para qué sirve?** Guarda un registro de todos los autos que el mecánico ha revisado. Si un cliente vuelve a los 3 días preguntando por la cotización de su *Ford Ranger*, el mecánico solo entra aquí, ve el registro con un ticket verde o reloj naranja (Pendiente) y recupera los precios al instante.

### E. Ajustes y Modo Oscuro
**¿Qué es?** Las preferencias de la aplicación.
**¿Para qué sirve?** Permite cambiar el tema de la aplicación de "Modo Claro" (Blanco) a "Modo Oscuro" (Tonos oscuros y azules).
*¿Por qué es importante?* Un taller mecánico suele ser un lugar con poca luz o luz artificial muy fuerte. El modo oscuro está diseñado para no cansar la vista del mecánico, consumir menos batería en su celular y darle un aspecto "Industrial" y Premium a la herramienta.

---

## 3. ¿Por qué el Diseño se ve así? (Filosofía Premium)
La aplicación no usa colores aburridos ni botones genéricos. Hemos diseñado una "Arquitectura Limpia" también en lo visual:
- Usamos **Glassmorphism** (Efecto de cristal translúcido) en algunos botones para que se vea como software del año 2026.
- Las **Micro-animaciones** (como cuando el escáner está buscando) están ahí porque en el diseño de productos, el usuario necesita saber que la app "está pensando" y no se ha quedado pegada. 

Con esto, demostramos en los 5 minutos de presentación que este producto no es un experimento, sino una solución comercial lista para salir al mercado.

---

## 4. Guía de Ejecución Rápida para Integrantes del Equipo

Para que cualquier integrante del grupo pueda probar la app en su máquina sin complicaciones:

1. **Instalar dependencias**:
   ```bash
   flutter pub get
   ```
2. **Lanzar la app en el servidor local**:
   ```bash
   flutter run -d web-server --web-port 8080 --web-hostname localhost
   ```
3. **Abrir en el navegador**:
   Entrar a `http://localhost:8080` desde Edge o Chrome.
4. **Modo Celular (Recomendado)**:
   Presionar `F12` y luego `Ctrl + Shift + M`. Seleccionar un modelo como iPhone 14 Pro o Pixel 7 para interactuar en formato vertical idéntico a un teléfono móvil.

