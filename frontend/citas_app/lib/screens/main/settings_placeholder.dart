import 'package:flutter/material.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';

/// Contenido de pestaña Configuración: enlace a pantalla completa.
class SettingsPlaceholder extends StatelessWidget {
  const SettingsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.settings_outlined,
              size: 80,
              color: AppColors.darkTextSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Configuración',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Ajustes de cuenta y preferencias.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.darkTextSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.settings),
              icon: const Icon(Icons.settings),
              label: const Text('Abrir configuración'),
            ),
          ],
        ),
      ),
    );
  }
}
