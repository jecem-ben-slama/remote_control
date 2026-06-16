import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ir_state_provider.dart';
import '../widgets/remote_button.dart';

/// Compact remote control interface
/// Displays physical button layout for quick IR command transmission
class MiniRemoteScreen extends StatelessWidget {
  const MiniRemoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF161616),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hardware Interface Remote',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Text(
              'Direct IR Signal Transmission',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Consumer<IRStateProvider>(
        builder: (context, provider, _) => SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Row 1: Source / Power
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildButton(
                        context,
                        provider,
                        17,
                        Icons.input,
                        'SOURCE',
                      ),
                      _buildButton(
                        context,
                        provider,
                        16,
                        Icons.power_settings_new,
                        'POWER',
                      ),
                    ],
                  ),
                ),
                // Row 2: D-Pad Up
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 4,
                  ),
                  child: _buildButton(
                    context,
                    provider,
                    24,
                    Icons.arrow_upward,
                    'UP',
                  ),
                ),
                // Row 3: D-Pad Left / Enter / Right
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildButton(
                        context,
                        provider,
                        27,
                        Icons.arrow_back,
                        'LEFT',
                      ),
                      _buildButton(
                        context,
                        provider,
                        29,
                        Icons.check_circle,
                        'ENTER',
                      ),
                      _buildButton(
                        context,
                        provider,
                        28,
                        Icons.arrow_forward,
                        'RIGHT',
                      ),
                    ],
                  ),
                ),
                // Row 4: D-Pad Down
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 4,
                  ),
                  child: _buildButton(
                    context,
                    provider,
                    26,
                    Icons.arrow_downward,
                    'DOWN',
                  ),
                ),
                // Row 5: Volume+/ Menu / Volume-
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildButton(
                        context,
                        provider,
                        14,
                        Icons.volume_up,
                        'VOL+',
                      ),
                      _buildButton(context, provider, 21, Icons.menu, 'MENU'),
                      _buildButton(
                        context,
                        provider,
                        15,
                        Icons.volume_down,
                        'VOL-',
                      ),
                    ],
                  ),
                ),
                // Row 6: Mute / Back
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildButton(
                        context,
                        provider,
                        23,
                        Icons.volume_mute,
                        'MUTE',
                      ),
                      _buildButton(
                        context,
                        provider,
                        67,
                        Icons.arrow_back,
                        'BACK',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Status indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    border: Border(
                      top: BorderSide(color: const Color(0xFF2A2A2A)),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'System Status',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        provider.hardwareStatus,
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: provider.hardwareStatus.contains('✓')
                              ? const Color(0xFF00C853)
                              : provider.hardwareStatus.contains('✗')
                              ? Colors.redAccent
                              : Colors.blueAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    IRStateProvider provider,
    int commandCode,
    IconData icon,
    String label,
  ) {
    return RemoteButton(
      icon: icon,
      label: label,
      commandCode: commandCode,
      onPressed: () => provider.transmitCommand(commandCode),
    );
  }
}
