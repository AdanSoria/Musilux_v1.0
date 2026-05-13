# Content for README.md
Musilux es una plataforma móvil desarrollada en Flutter diseñada para revolucionar la comercialización de instrumentos musicales, equipos de iluminación y vinilos. Combina la experiencia de una tienda física con herramientas digitales avanzadas como preescucha de audio y asistencia mediante IA.

## 🚀 Características Principales

* **Catálogo Dinámico:** Visualización técnica de equipos y curaduría de vinilos.
* **Integración con Spotify:** Preescucha de álbumes y tracks de demostración directamente en la App.
* **Pagos Seguros con Stripe:** Procesamiento de pagos robusto para la compra de instrumentos y accesorios.
* **Asistente Chatbot:** Soporte técnico y recomendaciones personalizadas mediante IA.
* **Experiencia Híbrida:** Enfoque en fidelidad sonora y especificaciones para profesionales.

---

## 🛠️ Requisitos Previos

Antes de comenzar, asegúrate de tener instalado lo siguiente:

* [Flutter SDK](https://docs.flutter.dev/get-started/install) (Versión estable más reciente).
* [Dart SDK](https://dart.dev/get-started/sdk).
* Un IDE compatible (VS Code, Android Studio o IntelliJ).
* CocoaPods (solo para usuarios de macOS/iOS).
* Cuentas de desarrollador en:
    * [Stripe Dashboard](https://dashboard.stripe.com/) (para llaves de API).
    * [Spotify Developer Dashboard](https://developer.spotify.com/dashboard/) (para Client ID y Secret).
    * [OpenAI / Google Cloud](https://platform.openai.com/) (para el Chatbot).

---

## ⚙️ Configuración del Proyecto

### 1. Clonar el Repositorio
```bash
git clone https://github.com/AlmaMR/Musilux_v1.0.git
cd Musilux_v1.0
```

### 2. Instalar dependencias
#### 2.2 Dart
Abrir una terminal en el proyecto y acceder al backend
```bash
cd backend
composer install
php artisan key:generate
php artisan migrate
php artisan migrate:fresh
php artisan migrate:fresh --seed
```
#### 2.2 Dart
Abrir una nueva terminal en el proyecto y acceder al frontend
```bash
cd musilux
flutter pub get
```

### 3. 

### 4. Ejecutar en emulador o dispositivo
#### 4.1. Backend
Pega en la consola del backend uno de los siguientes comandos:
```bash
php -S 0.0.0.0:8080 -t public
```
```bash
php artisan serve
```
#### 4.2. Frontend
Pega en la consola del frontend el siguiente comando:
```bash
flutter run
```
---

## 🛠️ Especificaciones Técnicas e Integraciones

### Arquitectura
El sistema utiliza una **Arquitectura de Capas** para separar la interfaz de usuario de la lógica de negocio y el consumo de datos, facilitando el mantenimiento.

### Integraciones de APIs
*   **Spotify API:** Curaduría de vinilos con preescucha de fragmentos y metadatos de álbumes.
*   **Stripe API:** Pasarela de pago segura para la compra de equipo técnico.
*   **Chatbot AI:** Asistente inteligente para dudas técnicas sobre vataje y alcance de iluminación.
*   **JWT (JSON Web Tokens):** Seguridad para el manejo de sesiones entre Flutter y Laravel.

### Estructura de Directorios (Frontend)
*   `lib/core`: Configuraciones, temas y clientes de API.
*   `lib/features`: Módulos de funcionalidad (Tienda, Reproductor, Chat).
*   `lib/services`: Lógica de comunicación con el backend Laravel y APIs externas.

---

## 📈 Metodología de Trabajo
Este proyecto se desarrolla bajo el marco **Scrum**, con entregas incrementales enfocadas en mejorar la conversión de visitantes a clientes mediante demos gratuitas de calidad.