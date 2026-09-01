[README.md](https://github.com/user-attachments/files/31671549/README.md)
# Repuestos Exactos

## Descripción del Proyecto
Repuestos Exactos es una solución de software móvil orientada al sector automotriz, diseñada para optimizar el flujo de trabajo en talleres mecánicos. La plataforma integra diagnóstico automotriz en tiempo real mediante escáneres OBD-II y un motor de cotización multifuente. Su objetivo principal es resolver la asimetría de información en la adquisición de repuestos, traduciendo códigos de falla técnicos (DTC) en un análisis comercial estructurado y eficiente para la toma de decisiones informada.

## Público Objetivo
El sistema está diseñado específicamente para mecánicos profesionales y administradores de talleres automotrices que utilizan herramientas de diagnóstico OBD-II y requieren optimizar los tiempos y recursos financieros en la adquisición de componentes vehiculares.

## Características Principales

* **Integración Diagnóstica (OBD-II):** Módulo de comunicación vía Bluetooth con dispositivos de escaneo automotriz para la extracción e interpretación de códigos de falla (DTC) de manera universal.
* **Identificación Vehicular Automatizada:** Sistema de lectura del número de identificación vehicular (VIN) a través del protocolo OBD-II, con respaldo de ingreso manual de parámetros (Marca, Modelo, Año, Motor).
* **Motor de Cotización Multifuente:** Integración mediante API RESTful con plataformas de comercio electrónico consolidadas e índices locales de precios. Categoriza repuestos compatibles y entrega cotizaciones precisas en moneda local (CLP).
* **Algoritmo de Clasificación de Componentes:** Sistema analítico que evalúa y recomienda repuestos basados en tres perfiles predefinidos:
    * **Perfil Económico:** Menor costo inicial, advirtiendo sobre posibles limitaciones de vida útil o riesgos asociados.
    * **Perfil Práctico:** Relación precio-calidad óptima basada en rendimiento comprobado en el sector.
    * **Perfil Óptimo:** Componentes OEM (Original Equipment Manufacturer) o calidad equivalente para garantizar máxima durabilidad.
* **Interfaz de Usuario (UI/UX):** Diseño de interfaz móvil formal que traduce datos técnicos automotrices a reportes comprensibles, presentando matrices comparativas de costos, garantías y practicidad.

## Arquitectura del Sistema

El desarrollo de la plataforma se estructura utilizando el modelo de arquitectura C4 (Niveles 1 y 2), asegurando un diseño escalable y modular:

* **Frontend:** Aplicación móvil multiplataforma.
* **Backend:** Arquitectura orientada a servicios basada en API RESTful. Ideal para implementaciones robustas utilizando lenguajes tipados (como Java) que manejen algoritmos complejos y múltiples peticiones asíncronas de manera segura.
* **Base de Datos:** Modelo relacional optimizado para la gestión de inventarios locales y perfiles vehiculares.

## Documentación de API
La arquitectura incluye la documentación técnica mediante Swagger/OpenAPI de los endpoints críticos del sistema, detallando sus respectivos Payloads (formato JSON) y esquemas de respuesta para módulos de autenticación, diagnóstico y recomendación.

## Equipo de Desarrollo
* Javier Chandía
* Adrián Perugini
* Matías Daza
* Victoria Escobar

## Contexto Académico
Universidad Mayor
Asignatura: Arquitectura de desarrollo Web y Móvil
Profesor: Carlos Muñoz
Fecha: Agosto 2026
