import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/appointment_provider.dart';
import 'agenda_tab_content.dart';
import 'historial_screen.dart';
import 'patients_placeholder.dart';
import 'settings_placeholder.dart';

/// Pantalla principal ProAgenda: BottomNavigationBar (Agenda, Pacientes, Historial, Configuración) + Drawer (Perfil, Reportes).
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  static const List<_NavItem> _tabs = [
    _NavItem(
      label: 'Agenda',
      icon: Icons.calendar_today_outlined,
      selectedIcon: Icons.calendar_today,
    ),
    _NavItem(
      label: 'Pacientes',
      icon: Icons.people_alt_outlined,
      selectedIcon: Icons.people_alt,
    ),
    _NavItem(
      label: 'Historial',
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment,
    ),
    _NavItem(
      label: 'Configuración',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
    ),
  ];

  String get _title {
    switch (_currentIndex) {
      case 0:
        return 'Agenda';
      case 1:
        return 'Pacientes';
      case 2:
        return 'Historial';
      case 3:
        return 'Configuración';
      default:
        return 'ProAgenda';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      drawer: _buildDrawer(context),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          AgendaTabContent(),
          PatientsPlaceholder(),
          HistorialScreen(),
          SettingsPlaceholder(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: _tabs
            .map(
              (tab) => BottomNavigationBarItem(
                icon: Icon(tab.icon),
                activeIcon: Icon(tab.selectedIcon),
                label: tab.label,
              ),
            )
            .toList(),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                final selectedDate =
                    context.read<AppointmentProvider>().selectedDate;
                Navigator.pushNamed(
                  context,
                  AppRoutes.appointmentForm,
                  arguments: {'date': selectedDate},
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Nueva Cita'),
            )
          : null,
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.darkSurfaceVariant,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'ProAgenda',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gestión de citas',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.darkTextSecondary,
                      ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Perfil'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.profile);
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart_outlined),
            title: const Text('Reportes'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.reports);
            },
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}
