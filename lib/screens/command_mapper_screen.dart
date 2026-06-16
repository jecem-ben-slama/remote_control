import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ir_state_provider.dart';
import '../services/pdf_export_service.dart';
import '../widgets/command_registry_list.dart';

/// Screen for mapping and managing IR commands
/// Displays a registry of all commands and allows labeling them
class CommandMapperScreen extends StatefulWidget {
  const CommandMapperScreen({super.key});

  @override
  State<CommandMapperScreen> createState() => _CommandMapperScreenState();
}

class _CommandMapperScreenState extends State<CommandMapperScreen> {
  late final ScrollController _scrollCtrl;
  late final FocusNode _fieldFocus;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
    _fieldFocus = FocusNode();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _fieldFocus.dispose();
    super.dispose();
  }

  void _selectCommand(BuildContext context, int index) {
    context.read<IRStateProvider>().selectCommand(index);
    _animateToCommand(index);
    Future.delayed(
      const Duration(milliseconds: 60),
      () => _fieldFocus.requestFocus(),
    );
  }

  void _animateToCommand(int index) {
    _scrollCtrl.animateTo(
      index * 52.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  Future<void> _handleExportPDF(BuildContext context) async {
    try {
      final provider = context.read<IRStateProvider>();
      final labeledCommands = provider.getLabeledCommands();
      await PDFExportService.exportToPDF(labeledCommands);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Consumer<IRStateProvider>(
        builder: (context, provider, _) => Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  SizedBox(
                    width: 125,
                    child: CommandRegistryList(
                      commands: provider.commands,
                      selectedIndex: provider.selectedCommandIndex,
                      onCommandSelected: (index) =>
                          _selectCommand(context, index),
                      scrollController: _scrollCtrl,
                    ),
                  ),
                  Expanded(
                    child: provider.selectedCommandIndex == null
                        ? const _EmptyState()
                        : _CommandDetails(
                            index: provider.selectedCommandIndex!,
                            focusNode: _fieldFocus,
                          ),
                  ),
                ],
              ),
            ),
            _buildStatusBar(provider),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF161616),
      title: Consumer<IRStateProvider>(
        builder: (context, provider, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Matrix Register Map',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Text(
              'Profile: NEC 0x01 · ${provider.labeledCommandCount} active mappings',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => _handleExportPDF(context),
          icon: const Icon(
            Icons.picture_as_pdf,
            size: 20,
            color: Color(0xFF00C853),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildStatusBar(IRStateProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      color: const Color(0xFF111111),
      child: Text(
        'IO_STREAM_MONITOR: ${provider.hardwareStatus}',
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          color: Colors.blueAccent,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Command details panel for editing a selected command
class _CommandDetails extends StatefulWidget {
  final int index;
  final FocusNode focusNode;

  const _CommandDetails({required this.index, required this.focusNode});

  @override
  State<_CommandDetails> createState() => _CommandDetailsState();
}

class _CommandDetailsState extends State<_CommandDetails> {
  late TextEditingController _labelController;

  @override
  void initState() {
    super.initState();
    final cmd = context.read<IRStateProvider>().commands[widget.index];
    _labelController = cmd.controller;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<IRStateProvider>(
      builder: (context, provider, _) {
        final cmd = provider.commands[widget.index];
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    cmd.hex,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 36,
                      color: Color(0xFF00C853),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: provider.isTransmitting
                        ? null
                        : () => provider.transmitCommand(widget.index),
                    icon: const Icon(Icons.bolt, size: 16),
                    label: const Text('BLAST DATA'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.redAccent.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              Text(
                'Vector ID Array: #${widget.index}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              TextField(
                focusNode: widget.focusNode,
                controller: _labelController,
                onChanged: (_) => provider.updateCommandLabel(
                  widget.index,
                  _labelController.text,
                ),
                onSubmitted: (_) {
                  if (widget.index < 255) {
                    context.read<IRStateProvider>().selectCommand(
                      widget.index + 1,
                    );
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Assigned Functional Flag Label',
                  filled: true,
                  fillColor: Color(0xFF161616),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00C853)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Empty state widget when no command is selected
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Select an internal address token space',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }
}
