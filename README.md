# ClickFix App 🔧

Una aplicación móvil Flutter para conectar clientes con técnicos especializados en diferentes áreas de servicio.

## 🎯 Estado Actual del Proyecto

### ✅ **FRONTEND: 100% FUNCIONAL**
- Todas las pantallas implementadas y funcionando
- Navegación completa
- UI/UX completamente diseñada
- Sistema de roles (Cliente, Técnico, Admin)

### ⏳ **BACKEND: LISTO PARA INTEGRACIÓN**
- Código limpio de conexiones anteriores
- Servicios mock implementados
- Preparado para conectar con nuevo backend
- Documentación completa disponible

---

## 📚 Documentación

### 🚀 **INICIO RÁPIDO** → Lee primero:
1. **[INDICE_DOCUMENTACION.md](INDICE_DOCUMENTACION.md)** - Guía de navegación
2. **[LIMPIEZA_COMPLETA_RESUMEN.md](LIMPIEZA_COMPLETA_RESUMEN.md)** - Resumen ejecutivo

### 📖 **Documentos Disponibles:**
- **[RESUMEN_LIMPIEZA.md](RESUMEN_LIMPIEZA.md)** - Estado actual y cómo ejecutar
- **[GUIA_MIGRACION_BACKEND.md](GUIA_MIGRACION_BACKEND.md)** - Guía paso a paso para integración
- **[LIMPIEZA_SUPABASE_README.md](LIMPIEZA_SUPABASE_README.md)** - Documentación técnica detallada

---

## 🚀 Ejecución Rápida

```bash
# 1. Instalar dependencias
flutter pub get

# 2. Ejecutar la aplicación
flutter run
```

**Nota:** La app funciona con datos simulados (mock) hasta que se conecte con un backend real.

---

## 📱 Características

### Para Clientes 👤
- ✅ Crear solicitudes de servicio
- ✅ Ver estado de solicitudes
- ✅ Recibir cotizaciones
- ✅ Calificar servicios
- ✅ Historial completo

### Para Técnicos 🔧
- ✅ Ver solicitudes disponibles
- ✅ Enviar cotizaciones
- ✅ Gestionar servicios asignados
- ✅ Perfil profesional
- ✅ Certificados y especialidades

### Para Administradores 👨‍💼
- ✅ Panel de control
- ✅ Gestión de usuarios
- ✅ Gestión de técnicos
- ✅ Especialidades del sistema
- ✅ Estadísticas generales

---

## 🛠️ Tecnologías

- **Flutter** 3.9.2
- **Dart** ^3.9.2
- **OneSignal** - Notificaciones push
- **Geolocator** - Servicios de ubicación
- **Image Picker** - Selección de imágenes
- **Shared Preferences** - Almacenamiento local

---

## 📦 Próximos Pasos

1. **Elegir Backend:** Supabase nuevo o API personalizada
2. **Configurar Credenciales:** En archivo `.env`
3. **Seguir Guía:** [GUIA_MIGRACION_BACKEND.md](GUIA_MIGRACION_BACKEND.md)
4. **Integrar Servicios:** Paso a paso según la documentación
5. **Testing:** Verificar funcionalidad completa

**Tiempo estimado de integración:** 2-4 horas

---

## 📂 Estructura del Proyecto

```
lib/
├── main.dart                 # Punto de entrada
├── auth/                     # Autenticación y registro
│   ├── auth_service.dart     # Servicio de auth (mock)
│   └── login_screen.dart
├── services/                 # Servicios de la aplicación
│   ├── database_service.dart # Servicio de BD (mock)
│   ├── location_service.dart # Ubicación (funcional)
│   └── onesignal_service.dart # Notificaciones (funcional)
├── screens/                  # Todas las pantallas
│   ├── admin/               # Pantallas de admin
│   ├── user_profile/        # Perfil de usuario
│   ├── technician_profile/  # Perfil de técnico
│   └── ... (más pantallas)
├── widgets/                  # Widgets reutilizables
└── core/                     # Configuración y constantes
```

---

## ⚠️ Importante

- **Datos Mock:** La aplicación actualmente usa datos simulados
- **Backend Desconectado:** No hay conexión a base de datos real
- **Frontend Funcional:** Toda la interfaz está operativa
- **Listo para Producción:** Solo necesita integración de backend

---

## 🤝 Contribuir

Para integrar el nuevo backend:
1. Lee la documentación en [GUIA_MIGRACION_BACKEND.md](GUIA_MIGRACION_BACKEND.md)
2. Sigue los pasos indicados
3. Prueba cada funcionalidad
4. Documenta cambios si es necesario

---

## 📝 Licencia

Este proyecto es privado.

---

## 📞 Soporte

Para más información sobre el estado del proyecto o la integración del backend, consulta la documentación completa en la carpeta raíz del proyecto.

**Última actualización:** 29 de enero de 2026  
**Versión:** 1.0.0 (Frontend Only)  
**Estado:** ✅ Listo para Integración de Backend

