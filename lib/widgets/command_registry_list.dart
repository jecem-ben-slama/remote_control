import 'package:flutter/material.dart';
import '../models/ir_command.dart';

/// Command registry list widget
/// Displays all available IR commands in a scrollable list
class CommandRegistryList extends StatelessWidget {
  final List<IRCommand> commands;
  final int? selectedIndex;
  final ValueChanged<int> onCommandSelected;
  final ScrollController? scrollController;

  const CommandRegistryList({
    Key? key,
    required this.commands,
    this.selectedIndex,
    required this.onCommandSelected,
    this.scrollController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Color(0xFF222222))),
      ),
      child: ListView.builder(
        controller: scrollController,
        itemCount: commands.length,
        itemExtent: 52,
        itemBuilder: (context, index) => _buildCommandItem(context, index),
      ),
    );
  }

  Widget _buildCommandItem(BuildContext context, int index) {
    final cmd = commands[index];
    final isSelected = selectedIndex == index;

    return InkWell(
      onTap: () => onCommandSelected(index),
      child: Container(
        color: isSelected ? const Color(0xFF112511) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Text(
              cmd.hex,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: isSelected
                    ? const Color(0xFF00C853)
                    : cmd.hasLabel
                    ? Colors.green
                    : Colors.grey.shade600,
              ),
            ),
            if (cmd.hasLabel && !isSelected) ...[
              const Spacer(),
              const CircleAvatar(radius: 3, backgroundColor: Color(0xFF00C853)),
            ],
          ],
        ),
      ),
    );
  }
}
