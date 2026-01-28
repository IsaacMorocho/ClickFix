# 🔧 SOLUCIÓN: Datos no se muestran en la aplicación

## Problema Identificado

Los datos existen en Supabase pero no se muestran en las interfaces de la aplicación. Esto es causado por:

### 1. ❌ **Variables de entorno incorrectas**
**Solución:** Ya corregido en `.env`:
- Removidos espacios alrededor del `=`
- Agregada la clave anon completa de Supabase

### 2. ❌ **Políticas RLS (Row Level Security) faltantes**
**Problema principal:** Supabase tiene RLS habilitado pero sin políticas, lo que bloquea TODO el acceso.

---

## 📋 Pasos para Solucionar

### **PASO 1: Verificar archivo .env**

El archivo `.env` debe tener exactamente este formato (sin espacios):

```env
SUPABASE_URL=https://wtbhxgjlbjhessmdzwnn.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind0Ymh4Z2psYmpoZXNzbWR6d25uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzc0ODU4MDMsImV4cCI6MjA1MzA2MTgwM30.O36Hh3EGl8SXqYI3ITNdTQk-vJmJI7qYo1RYRBpQoYw
```

✅ **Ya corregido**

---

### **PASO 2: Aplicar Políticas RLS en Supabase**

1. **Abre Supabase Dashboard:**
   - Ve a: https://supabase.com/dashboard/project/wtbhxgjlbjhessmdzwnn

2. **Ve a SQL Editor:**
   - En el menú lateral: `SQL Editor` → `New query`

3. **Ejecuta el script de políticas:**
   - Abre el archivo `SUPABASE_POLITICAS_RLS.sql` que está en la raíz del proyecto
   - Copia TODO el contenido
   - Pégalo en el SQL Editor de Supabase
   - Click en `Run` o presiona `Ctrl + Enter`

4. **Verifica que se aplicaron:**
   ```sql
   SELECT tablename, policyname 
   FROM pg_policies 
   WHERE schemaname = 'public';
   ```

---

### **PASO 3: Verificar estructura de tablas**

Asegúrate de que estas tablas existan con las columnas correctas:

#### **users**
```sql
CREATE TABLE public.users (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  rol text CHECK (rol IN ('admin', 'cliente', 'tecnico')),
  estado text DEFAULT 'activo',
  created_at timestamptz DEFAULT now()
);
```

#### **technicians**
```sql
CREATE TABLE public.technicians (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  anios_experiencia integer DEFAULT 0,
  descripcion_profesional text,
  tarifa_base decimal(10,2) DEFAULT 0,
  zona_cobertura text,
  rating_promedio decimal(3,2) DEFAULT 0,
  verificado_por uuid REFERENCES auth.users(id),
  fecha_verificacion timestamptz,
  created_at timestamptz DEFAULT now()
);
```

#### **specialties**
```sql
CREATE TABLE public.specialties (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre text NOT NULL,
  descripcion text,
  icono text,
  created_at timestamptz DEFAULT now()
);
```

---

### **PASO 4: Verificar foreign keys**

Las foreign keys deben tener estos nombres exactos para las consultas:

```sql
-- En tabla technicians
ALTER TABLE public.technicians 
  DROP CONSTRAINT IF EXISTS technicians_user_id_fkey;
  
ALTER TABLE public.technicians 
  ADD CONSTRAINT technicians_user_id_fkey 
  FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- En tabla technician_specialties
ALTER TABLE public.technician_specialties
  DROP CONSTRAINT IF EXISTS technician_specialties_specialty_id_fkey;
  
ALTER TABLE public.technician_specialties
  ADD CONSTRAINT technician_specialties_specialty_id_fkey
  FOREIGN KEY (specialty_id) REFERENCES public.specialties(id) ON DELETE CASCADE;

-- En tabla service_requests
ALTER TABLE public.service_requests
  DROP CONSTRAINT IF EXISTS service_requests_cliente_id_fkey;
  
ALTER TABLE public.service_requests
  ADD CONSTRAINT service_requests_cliente_id_fkey
  FOREIGN KEY (cliente_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- En tabla reviews
ALTER TABLE public.reviews
  DROP CONSTRAINT IF EXISTS reviews_autor_id_fkey;
  
ALTER TABLE public.reviews
  ADD CONSTRAINT reviews_autor_id_fkey
  FOREIGN KEY (autor_id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE public.reviews
  DROP CONSTRAINT IF EXISTS reviews_receptor_id_fkey;
  
ALTER TABLE public.reviews
  ADD CONSTRAINT reviews_receptor_id_fkey
  FOREIGN KEY (receptor_id) REFERENCES auth.users(id) ON DELETE CASCADE;
```

---

### **PASO 5: Insertar datos de prueba**

Si no tienes datos, ejecuta esto para crear registros de prueba:

```sql
-- Insertar especialidades
INSERT INTO public.specialties (nombre, descripcion) VALUES
  ('Plomería', 'Reparación e instalación de sistemas de agua'),
  ('Electricidad', 'Instalación y reparación eléctrica'),
  ('Carpintería', 'Trabajos en madera y muebles'),
  ('Pintura', 'Pintura de interiores y exteriores'),
  ('Albañilería', 'Construcción y reparación'),
  ('Cerrajería', 'Instalación y reparación de cerraduras'),
  ('Aire Acondicionado', 'Instalación y mantenimiento de A/C'),
  ('Electrodomésticos', 'Reparación de electrodomésticos');
```

---

### **PASO 6: Reiniciar la aplicación**

1. **Detén la app** si está corriendo:
   ```bash
   # En la terminal de Flutter, presiona 'q' o Ctrl+C
   ```

2. **Hot Restart completo:**
   ```bash
   cd C:/Users/ADM-DGIP/Videos/CLICKFIX-APP-main/CLICKFIX-APP-main
   flutter clean
   flutter pub get
   flutter run
   ```

3. **O simplemente:**
   - Presiona `R` (Hot Restart) en la terminal donde está corriendo Flutter
   - O presiona `Shift + F5` en VS Code

---

## 🔍 Verificación de Problemas

### **Opción A: Verificar en Supabase Dashboard**

1. Ve a: `Authentication` → `Users`
   - Deberías ver los usuarios creados
   - Verifica que tengan el campo `rol` en `User Metadata` o en la tabla `public.users`

2. Ve a: `Table Editor` → Selecciona cada tabla
   - Verifica que los datos existan
   - Verifica los valores de las columnas

### **Opción B: Verificar desde la app**

1. **Abre Flutter DevTools:**
   ```bash
   flutter run --verbose
   ```

2. **Mira los logs** cuando intentes cargar datos:
   - Busca errores de tipo `PostgrestException`
   - Busca mensajes de "permission denied" o "policy"

### **Opción C: Desactivar RLS temporalmente (SOLO PARA PRUEBAS)**

```sql
-- ⚠️ SOLO PARA DESARROLLO - NO EN PRODUCCIÓN
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.technicians DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.specialties DISABLE ROW LEVEL SECURITY;
-- etc...
```

Si los datos aparecen después de esto, confirma que el problema son las políticas RLS.

---

## ✅ Checklist Final

- [ ] Archivo `.env` corregido (sin espacios)
- [ ] Políticas RLS ejecutadas en Supabase
- [ ] Foreign keys con nombres correctos
- [ ] Tablas creadas con estructura correcta
- [ ] Datos de prueba insertados
- [ ] App reiniciada con `flutter clean` y `flutter run`
- [ ] Usuario autenticado con rol correcto

---

## 🆘 Si el problema persiste

1. **Revisa los logs de Supabase:**
   - Dashboard → Logs → Postgres Logs
   - Busca errores de permisos o políticas

2. **Verifica la autenticación:**
   ```dart
   // En la app, agrega esto temporalmente:
   print('User ID: ${Supabase.instance.client.auth.currentUser?.id}');
   print('User metadata: ${Supabase.instance.client.auth.currentUser?.userMetadata}');
   ```

3. **Comparte el error específico:**
   - Captura de pantalla del error
   - Logs de la consola de Flutter
   - Resultado de la verificación de políticas en Supabase

---

## 📚 Documentación Adicional

- [Supabase RLS Documentation](https://supabase.com/docs/guides/auth/row-level-security)
- [PostgreSQL Policies](https://www.postgresql.org/docs/current/sql-createpolicy.html)
- [Flutter Supabase SDK](https://supabase.com/docs/reference/dart/introduction)
