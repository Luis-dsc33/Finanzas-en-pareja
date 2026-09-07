# CashFlow 💸

> Aplicación móvil de gestión de finanzas personales y compartidas, construida con Flutter y potenciada por Inteligencia Artificial.

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)

---

## 📖 Acerca del Proyecto

**CashFlow** es una herramienta integral diseñada para ayudar a los usuarios a llevar un control estricto de su presupuesto, ingresos, gastos y metas financieras. Su arquitectura escalable permite su uso tanto de forma individual como compartida (en pareja).

Cuenta con un diseño moderno, amigable (estilo pastel glassmorphism) y un asistente virtual impulsado por **Google Gemini** para brindar resúmenes analíticos y consejos financieros personalizados basados en los hábitos del usuario.

## ✨ Características Principales

- **🧑‍🤝‍🧑 Cuentas Compartidas:** Sistema de inicio de sesión que permite registrar transacciones indicando quién realizó el pago ("Yo" o "Mi pareja") para un balance transparente.
- **📊 Dashboard Analítico:** Vista panorámica del estado financiero mensual mediante gráficos interactivos (donas y barras) que contrastan el presupuesto vs. gastos.
- **📝 Gestión de Transacciones:** Registro ágil de ingresos y egresos categorizados.
- **🎯 Metas de Ahorro:** Módulo de seguimiento para objetivos a largo plazo, indicando el ritmo de ahorro y el progreso en tiempo real.
- **🤖 Asesor IA (Gemini):** Integración con LLMs para leer el estado de cuenta y emitir consejos, proyecciones y alertas ante desvíos del presupuesto.

## 🛠️ Stack Tecnológico

- **Frontend:** Flutter (Dart)
- **Gestión de Estado:** Riverpod
- **Backend (BaaS):** Firebase (Authentication & Cloud Firestore)
- **Inteligencia Artificial:** `google_generative_ai` (Gemini API)
- **Gráficos:** `fl_chart`

## 📱 Capturas de Pantalla

*(Las capturas del proyecto en funcionamiento se encuentran en el directorio `docs/capturas/`)*

## 🚀 Instalación y Ejecución Local

Para correr este proyecto de manera local, asegúrate de tener instalado el [Flutter SDK](https://docs.flutter.dev/get-started/install).

1. Clona el repositorio:
   ```bash
   git clone https://github.com/Luis-dsc33/Finanzas-en-pareja.git
   ```
2. Navega al directorio del proyecto:
   ```bash
   cd Finanzas-en-pareja
   ```
3. Instala las dependencias:
   ```bash
   flutter pub get
   ```
4. Ejecuta la aplicación (en tu emulador o dispositivo físico):
   ```bash
   flutter run
   ```

*Nota: La configuración de Firebase actual requiere de un entorno móvil (Android/iOS) para ejecutarse completamente debido a la inicialización de los servicios.*

---
**Desarrollado para Portafolio Profesional.**
