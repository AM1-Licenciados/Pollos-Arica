# Funcionalidades y reglas de negocio — Pollos Arica

## Propósito
Pollos Arica es una solución para digitalizar la consulta del menú y la gestión de pedidos del restaurante. Se compone de una aplicación Flutter para clientes y un panel Flutter Web para administración, conectados al mismo proyecto Supabase.

## Roles
- **Cliente:** consulta el menú, prepara un pedido, elige modalidad de atención y forma de pago, envía el pedido y consulta su estado.
- **Administrador:** administra productos y precios, revisa pedidos, actualiza estados y mantiene datos de configuración del negocio y del pago QR.
- **Personal:** el flujo operativo contempla recibir, aceptar y actualizar pedidos según los permisos configurados. La asignación exacta de permisos debe verificarse en las políticas vigentes de Supabase.

## Funcionalidades del cliente
- Pantalla de bienvenida y acceso al menú.
- Catálogo por categorías, productos, variantes/presentaciones, precios y disponibilidad.
- Búsqueda de productos; la versión desarrollada incluye búsqueda por voz.
- Carrito: agregar, quitar y modificar cantidades antes de confirmar.
- Captura de datos básicos del cliente (nombre y celular).
- Selección de modalidad: retiro en el local; la entrega a domicilio se considera una etapa futura y no debe anunciarse como operativa hasta habilitarla.
- Selección de pago en efectivo o pago mediante QR.
- Registro del pedido en Supabase y visualización del código/confirmación.
- Sección **Mis pedidos** para consultar pedidos y estados.
- Para pago QR, el cliente puede adjuntar el comprobante y confirmar que realizó el pago cuando la interfaz lo habilita.

## Funcionalidades del panel administrativo
- Inicio de sesión administrativo mediante Supabase Auth.
- Vista de pedidos y detalle de artículos.
- Actualización del estado operativo del pedido.
- Revisión/actualización del estado de pago.
- Gestión de catálogo y precios, con precios administrables y no fijados en la interfaz cliente.
- Configuración del QR de pago y su imagen.
- Configuración de información del negocio, según los campos disponibles en el panel.

## Reglas de negocio conocidas
- Los precios vigentes deben consultarse desde Supabase; el cliente no debe ser la fuente autoritativa del precio.
- La creación del pedido debe validar en el backend productos, variantes, cantidades, disponibilidad y precios.
- El total debe calcularse en el servidor con los precios actuales.
- Pedido y pago son estados separados: un pedido puede estar en preparación y tener el pago pendiente o por verificar.
- El comprobante QR no equivale automáticamente a pago confirmado; la verificación es manual por el personal autorizado.
- El cliente puede editar o cancelar antes de que el personal acepte el pedido, conforme a las reglas implementadas.
- No se debe aceptar pedido fuera del horario operativo configurado.
- Horario operativo informado para el negocio: lunes a viernes 10:00–14:00; sábado y domingo 10:00–21:30. Confirmar que estos horarios coincidan con la configuración activa de producción antes de usarlos como fuente oficial.
- Tiempo de preparación habitual informado: más de 20 minutos; comunicar el tiempo estimado según la carga real, no como garantía fija.
- Actualmente no hay delivery operativo; el flujo principal es retiro en local.

## Menú y precios
El catálogo es administrable. Los precios de referencia históricos mencionados durante el desarrollo (por ejemplo, pollo Broaster/Brasa y milanesas) pueden cambiar y **no deben considerarse precios actuales**. El administrador debe mantener precios y disponibilidad desde el panel.

## Experiencia visual
- Identidad de marca naranja y crema, con logo Pollos Arica.
- Navegación cliente: Inicio, Mis pedidos y Perfil.
- Carrito como acceso independiente.
- Perfil con datos del cliente, contacto/ubicación y enlaces sociales.
- La interfaz debe mostrar mensajes de validación y estados vacíos de forma clara.

## Funcionalidades futuras o no confirmadas como operativas
- Delivery con seguimiento.
- Notificaciones push automáticas.
- Recuperación de pedidos mediante SMS o cuenta autenticada del cliente.
- Promociones automáticas configurables.
- Confirmación automática de pagos QR.

No marcar estas funciones como entregadas sin validación en el código y en el entorno desplegado.
