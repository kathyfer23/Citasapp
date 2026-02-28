import 'package:flutter/material.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';

/// Contenido de pestaña Pacientes: enlace a pantalla completa.
class PatientsPlaceholder extends StatelessWidget {
  const PatientsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_alt_outlined,
              size: 80,
              color: AppColors.darkTextSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Pacientes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Gestiona tu lista de pacientes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.darkTextSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.patients),
              icon: const Icon(Icons.list),
              label: const Text('Ver lista de pacientes'),
            ),
          ],
        ),
      ),
    );
  }
}
