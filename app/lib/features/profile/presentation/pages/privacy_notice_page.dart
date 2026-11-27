import 'package:bookia_mobile/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Screen 15 → Aviso de privacidad (SEG-05).
///
/// This is a technical draft. It describes the verified behaviour of the
/// current build and explicitly marks the decisions that are still pending;
/// it is not a legal document.
class PrivacyNoticePage extends StatelessWidget {
  const PrivacyNoticePage({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Aviso de privacidad')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Aviso de privacidad de BOOKIA', style: text.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Borrador técnico de la aplicación móvil. El texto definitivo '
            'debe ser revisado y aprobado por el equipo antes de publicarse.',
            style: text.bodySmall,
          ),
          const _Section(
            title: 'Datos que procesa BOOKIA',
            body:
                'Para operar la cuenta se usan el nombre, el correo '
                'electrónico, el rol y la fecha de alta. Las reservas, '
                'favoritos y alertas se asocian a esa cuenta. La aplicación '
                'no guarda contraseñas en el teléfono.',
          ),
          const _Section(
            title: 'Para qué se usan',
            body:
                'Identificar a la persona, iniciar y restaurar la sesión, '
                'gestionar reservas y favoritos, mostrar el historial de '
                'actividad y permitir el acceso del personal de una librería '
                'a su propio panel.',
          ),
          const _Section(
            title: 'Ubicación',
            body:
                'La ubicación se usa para ordenar librerías por distancia y '
                'trazar rutas. En esta versión, cuando la persona activa '
                '"Usar mi ubicación", la aplicación envía latitud y longitud '
                'a GET /api/stores/near para calcular la distancia. El código '
                'revisado de la API calcula la distancia en memoria y no '
                'guarda esas coordenadas en MongoDB; la petición sí viaja por '
                'la red. La Constitución SEG-04 dice que la ubicación no se '
                'envía ni se guarda: esa contradicción sigue pendiente de '
                'decisión del equipo. La alternativa recomendada es calcular '
                'las distancias en el teléfono con las coordenadas públicas '
                'de las librerías. Si la preferencia está desactivada, la app '
                'no solicita nuevas coordenadas ni las envía.',
          ),
          const _Section(
            title: 'Notificaciones',
            body:
                'Esta compilación no incluye notificaciones push porque '
                'Firebase no está configurado y la integración de I1 sigue en '
                'revisión. No se registra ningún token de dispositivo desde '
                'esta pantalla. Cuando la función esté disponible se avisará '
                'qué token se envía y con qué finalidad.',
          ),
          const _Section(
            title: 'Qué se guarda en el teléfono',
            body:
                'El token de sesión se guarda en el almacenamiento seguro del '
                'sistema (Keychain/Keystore). Las preferencias, como usar la '
                'ubicación, y las búsquedas recientes se guardan localmente en '
                'Hive. El token no se guarda en Hive ni en preferencias '
                'compartidas. Al cerrar sesión se intenta borrar el token y se '
                'limpia el estado de la cuenta.',
          ),
          const _Section(
            title: 'Cierre de sesión y preferencias',
            body:
                'La persona puede cambiar su nombre, su contraseña, la '
                'preferencia de ubicación y cerrar sesión desde Perfil. Si el '
                'almacenamiento seguro falla al cerrar sesión, la aplicación '
                'debe informar el problema y no afirmar que el token fue '
                'borrado.',
          ),
          const _Section(
            title: 'Responsable y contacto',
            body:
                'BOOKIA es un proyecto académico. Aún no se ha confirmado un '
                'responsable legal, un domicilio, un correo de privacidad ni '
                'un plazo de conservación. No se inventan aquí. El equipo debe '
                'definirlos y aprobar el texto definitivo antes de declarar '
                'cumplido SEG-05.',
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Estado: borrador. Dependencias pendientes: decisión SEG-04, '
            'aprobación del texto y datos de contacto del responsable.',
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: text.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(body, style: text.bodyMedium),
        ],
      ),
    );
  }
}
