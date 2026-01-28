-- ============================================================================
-- POLÍTICAS RLS (ROW LEVEL SECURITY) PARA CLICKFIX
-- ============================================================================
-- IMPORTANTE: Ejecuta estos comandos en el SQL Editor de Supabase
-- para que los datos sean visibles en la aplicación
-- ============================================================================

-- 1. HABILITAR RLS en todas las tablas
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.technicians ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.specialties ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.technician_specialties ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.technician_certificates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quotes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 2. POLÍTICAS PARA TABLA: users
-- ============================================================================

-- Los usuarios pueden ver su propio perfil
CREATE POLICY "Users can view own profile"
ON public.users FOR SELECT
USING (auth.uid() = id);

-- Los admins pueden ver todos los usuarios
CREATE POLICY "Admins can view all users"
ON public.users FOR SELECT
USING (
  auth.uid() IN (
    SELECT id FROM public.users WHERE rol = 'admin'
  )
);

-- Los usuarios pueden actualizar su propio perfil
CREATE POLICY "Users can update own profile"
ON public.users FOR UPDATE
USING (auth.uid() = id);

-- Permitir INSERT durante el registro
CREATE POLICY "Enable insert for authenticated users"
ON public.users FOR INSERT
WITH CHECK (auth.uid() = id);

-- ============================================================================
-- 3. POLÍTICAS PARA TABLA: specialties
-- ============================================================================

-- Todos pueden leer las especialidades
CREATE POLICY "Everyone can view specialties"
ON public.specialties FOR SELECT
TO public
USING (true);

-- Solo admins pueden crear/modificar especialidades
CREATE POLICY "Admins can manage specialties"
ON public.specialties FOR ALL
USING (
  auth.uid() IN (
    SELECT id FROM public.users WHERE rol = 'admin'
  )
);

-- ============================================================================
-- 4. POLÍTICAS PARA TABLA: technicians
-- ============================================================================

-- Los técnicos pueden ver su propio perfil
CREATE POLICY "Technicians can view own profile"
ON public.technicians FOR SELECT
USING (auth.uid() = user_id);

-- Todos pueden ver técnicos verificados
CREATE POLICY "Everyone can view verified technicians"
ON public.technicians FOR SELECT
USING (verificado_por IS NOT NULL);

-- Los admins pueden ver todos los técnicos
CREATE POLICY "Admins can view all technicians"
ON public.technicians FOR SELECT
USING (
  auth.uid() IN (
    SELECT id FROM public.users WHERE rol = 'admin'
  )
);

-- Los técnicos pueden actualizar su propio perfil
CREATE POLICY "Technicians can update own profile"
ON public.technicians FOR UPDATE
USING (auth.uid() = user_id);

-- Permitir INSERT durante el registro de técnico
CREATE POLICY "Enable insert for new technicians"
ON public.technicians FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Los admins pueden actualizar cualquier técnico (para verificación)
CREATE POLICY "Admins can update technicians"
ON public.technicians FOR UPDATE
USING (
  auth.uid() IN (
    SELECT id FROM public.users WHERE rol = 'admin'
  )
);

-- ============================================================================
-- 5. POLÍTICAS PARA TABLA: technician_specialties
-- ============================================================================

-- Todos pueden ver las especialidades de los técnicos
CREATE POLICY "Everyone can view technician specialties"
ON public.technician_specialties FOR SELECT
TO public
USING (true);

-- Los técnicos pueden gestionar sus propias especialidades
CREATE POLICY "Technicians can manage own specialties"
ON public.technician_specialties FOR ALL
USING (
  auth.uid() IN (
    SELECT user_id FROM public.technicians WHERE id = technician_id
  )
);

-- ============================================================================
-- 6. POLÍTICAS PARA TABLA: technician_certificates
-- ============================================================================

-- Todos pueden ver los certificados de técnicos verificados
CREATE POLICY "Everyone can view certificates"
ON public.technician_certificates FOR SELECT
TO public
USING (true);

-- Los técnicos pueden gestionar sus propios certificados
CREATE POLICY "Technicians can manage own certificates"
ON public.technician_certificates FOR ALL
USING (
  auth.uid() IN (
    SELECT user_id FROM public.technicians WHERE id = technician_id
  )
);

-- ============================================================================
-- 7. POLÍTICAS PARA TABLA: service_requests
-- ============================================================================

-- Los clientes pueden ver sus propias solicitudes
CREATE POLICY "Clients can view own requests"
ON public.service_requests FOR SELECT
USING (auth.uid() = cliente_id);

-- Los clientes pueden crear solicitudes
CREATE POLICY "Clients can create requests"
ON public.service_requests FOR INSERT
WITH CHECK (auth.uid() = cliente_id);

-- Los clientes pueden actualizar sus propias solicitudes
CREATE POLICY "Clients can update own requests"
ON public.service_requests FOR UPDATE
USING (auth.uid() = cliente_id);

-- Los técnicos pueden ver todas las solicitudes (para cotizar)
CREATE POLICY "Technicians can view all requests"
ON public.service_requests FOR SELECT
USING (
  auth.uid() IN (
    SELECT user_id FROM public.technicians
  )
);

-- Los admins pueden ver todas las solicitudes
CREATE POLICY "Admins can view all requests"
ON public.service_requests FOR SELECT
USING (
  auth.uid() IN (
    SELECT id FROM public.users WHERE rol = 'admin'
  )
);

-- ============================================================================
-- 8. POLÍTICAS PARA TABLA: services
-- ============================================================================

-- Los clientes pueden ver servicios donde son clientes
CREATE POLICY "Clients can view own services"
ON public.services FOR SELECT
USING (
  auth.uid() IN (
    SELECT cliente_id FROM public.service_requests WHERE id = request_id
  )
);

-- Los técnicos pueden ver sus servicios asignados
CREATE POLICY "Technicians can view assigned services"
ON public.services FOR SELECT
USING (auth.uid() IN (
  SELECT user_id FROM public.technicians WHERE id = technician_id
));

-- Los técnicos pueden actualizar sus servicios asignados
CREATE POLICY "Technicians can update assigned services"
ON public.services FOR UPDATE
USING (auth.uid() IN (
  SELECT user_id FROM public.technicians WHERE id = technician_id
));

-- Los admins pueden ver todos los servicios
CREATE POLICY "Admins can view all services"
ON public.services FOR SELECT
USING (
  auth.uid() IN (
    SELECT id FROM public.users WHERE rol = 'admin'
  )
);

-- Los admins pueden gestionar todos los servicios
CREATE POLICY "Admins can manage all services"
ON public.services FOR ALL
USING (
  auth.uid() IN (
    SELECT id FROM public.users WHERE rol = 'admin'
  )
);

-- ============================================================================
-- 9. POLÍTICAS PARA TABLA: quotes (cotizaciones)
-- ============================================================================

-- Los técnicos pueden crear cotizaciones
CREATE POLICY "Technicians can create quotes"
ON public.quotes FOR INSERT
WITH CHECK (
  auth.uid() IN (
    SELECT user_id FROM public.technicians WHERE id = technician_id
  )
);

-- Los técnicos pueden ver sus propias cotizaciones
CREATE POLICY "Technicians can view own quotes"
ON public.quotes FOR SELECT
USING (
  auth.uid() IN (
    SELECT user_id FROM public.technicians WHERE id = technician_id
  )
);

-- Los clientes pueden ver cotizaciones de sus solicitudes
CREATE POLICY "Clients can view quotes for own requests"
ON public.quotes FOR SELECT
USING (
  auth.uid() IN (
    SELECT cliente_id FROM public.service_requests WHERE id = request_id
  )
);

-- Los clientes pueden actualizar cotizaciones (aceptar/rechazar)
CREATE POLICY "Clients can update quotes"
ON public.quotes FOR UPDATE
USING (
  auth.uid() IN (
    SELECT cliente_id FROM public.service_requests WHERE id = request_id
  )
);

-- ============================================================================
-- 10. POLÍTICAS PARA TABLA: reviews
-- ============================================================================

-- Todos pueden ver las reseñas
CREATE POLICY "Everyone can view reviews"
ON public.reviews FOR SELECT
TO public
USING (true);

-- Los usuarios pueden crear reseñas
CREATE POLICY "Users can create reviews"
ON public.reviews FOR INSERT
WITH CHECK (auth.uid() = autor_id);

-- Los admins pueden gestionar reseñas
CREATE POLICY "Admins can manage reviews"
ON public.reviews FOR ALL
USING (
  auth.uid() IN (
    SELECT id FROM public.users WHERE rol = 'admin'
  )
);

-- ============================================================================
-- 11. POLÍTICAS PARA TABLA: notifications
-- ============================================================================

-- Los usuarios pueden ver sus propias notificaciones
CREATE POLICY "Users can view own notifications"
ON public.notifications FOR SELECT
USING (auth.uid() = user_id);

-- Los usuarios pueden actualizar sus notificaciones (marcar como leídas)
CREATE POLICY "Users can update own notifications"
ON public.notifications FOR UPDATE
USING (auth.uid() = user_id);

-- El sistema puede crear notificaciones para cualquier usuario
CREATE POLICY "System can create notifications"
ON public.notifications FOR INSERT
WITH CHECK (true);

-- ============================================================================
-- VERIFICAR QUE LAS POLÍTICAS SE APLICARON
-- ============================================================================

-- Ejecuta esta consulta para ver todas las políticas creadas:
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- ============================================================================
-- NOTA IMPORTANTE
-- ============================================================================
-- Si encuentras errores o los datos aún no se muestran:
-- 1. Verifica que el usuario esté autenticado correctamente
-- 2. Verifica que el rol del usuario sea correcto ('admin', 'tecnico', 'cliente')
-- 3. Verifica que las foreign keys estén correctamente configuradas
-- 4. Revisa los logs de Supabase en: Logs > Postgres Logs
-- ============================================================================
