# CashFlow (Finanzas Personales y Compartidas)

## Descripción del Proyecto
Esta es una aplicación móvil desarrollada en Flutter orientada a la gestión de finanzas personales, con la capacidad de extenderse para manejar finanzas compartidas en pareja. La aplicación ayuda a los usuarios a llevar un control estricto de su presupuesto, ingresos, gastos y metas financieras. Cuenta con un diseño amigable de estilo pastel y un asistente impulsado por inteligencia artificial (Gemini) para brindar resúmenes y consejos personalizados.

## Características Principales

*   **Autenticación Sencilla:** Sistema de inicio de sesión fácil que automáticamente mapea nombres de usuarios genéricos.
*   **Panel de Control (Dashboard):** Vista panorámica de las finanzas. Gráficos de dona para el control del presupuesto e ingresos contra egresos mensuales.
*   **Gestión de Transacciones:** Registro de ingresos y gastos diarios organizados por categorías. Incluye la opción de marcar si un gasto fue pagado de forma individual o compartida.
*   **Presupuesto Mensual:** Definición y seguimiento de topes de gastos fijos y variables.
*   **Metas de Ahorro:** Seguimiento interactivo para objetivos a largo plazo (ej. "Casa", "Viaje"), indicando si se encuentran "en buen ritmo" o "atrasados".
*   **Asesor Financiero IA (Gemini):** Integración con Google Generative AI para leer el estado de cuenta y proporcionar consejos dinámicos o emitir alertas ante posibles desvíos del presupuesto.

## Arquitectura y Tecnologías
El proyecto está estructurado de manera modular para garantizar escalabilidad y facilidad de mantenimiento.

*   **Frontend:** Flutter (Dart).
*   **Gestión de Estado:** Riverpod.
*   **Backend & Base de Datos:** Firebase (Authentication, Cloud Firestore).
*   **Inteligencia Artificial:** `google_generative_ai` (Gemini API).
*   **Gráficos:** `fl_chart`.
*   **Notificaciones Locales:** `flutter_local_notifications`.

## Justificación Técnica
La elección de Flutter como framework principal permite construir un producto de alta calidad en múltiples plataformas utilizando una única base de código. La utilización de Firebase proporciona almacenamiento y sincronización de datos en tiempo real, vital para una app financiera que se usa a diario. 

## Capturas de Pantalla
A continuación se muestran algunas de las vistas clave de la aplicación:

(Revisa la carpeta `capturas/` para adjuntar las imágenes de la aplicación funcionando).
