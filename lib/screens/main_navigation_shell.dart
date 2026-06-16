import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:remote_control/screens/ir_scanner.dart';
import 'package:remote_control/screens/lastresort.dart';
import '../providers/ir_state_provider.dart';
import '../repositories/ir_command_repository.dart';
import '../services/native_ir_blaster_service.dart';
import 'command_mapper_screen.dart';
import 'mini_remote_screen.dart';

/// Main navigation shell with tab-based layout
/// Sets up dependency injection and manages screen navigation
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _selectedIndex = 1; // Start on MiniRemoteScreen

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Create singleton instances for dependency injection
        Provider<NativeIrBlasterService>(
          create: (_) => NativeIrBlasterService(),
        ),
        Provider<IRCommandRepository>(create: (_) => IRCommandRepository()),
        // StateNotifier that depends on the above
        ChangeNotifierProvider(
          create: (context) => IRStateProvider(
            irBlaster: context.read<NativeIrBlasterService>(),
            repository: context.read<IRCommandRepository>(),
          ),
        ),
      ],
      child: Scaffold(
        body: _buildScreens()[_selectedIndex],
        bottomNavigationBar: _buildNavigationBar(),
      ),
    );
  }

  List<Widget> _buildScreens() => [
    const CommandMapperScreen(),
    const MiniRemoteScreen(),
    const IrScannerScreen(),
    IrRecoveryPlaygroundScreen(),
  ];

  Widget _buildNavigationBar() {
    return NavigationBar(
      backgroundColor: const Color(0xFF111111),
      indicatorColor: const Color(0xFF00C853),
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() => _selectedIndex = index);
      },
      destinations: [
        NavigationDestination(
          icon: Icon(Icons.dashboard),
          label: 'Command Matrix',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_remote),
          label: 'Remote Control',
        ),
        NavigationDestination(icon: Icon(Icons.power), label: 'brute force'),
        NavigationDestination(icon: Icon(Icons.build), label: 'recovery'),
      ],
    );
  }
}
