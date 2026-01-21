import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/nfc_bloc.dart';
import '../../data/services/nfc_service.dart';

/// NFC Writer Modal for writing data to NFC tags
/// 
/// Features:
/// - Platform check for iOS restriction
/// - Data input with validation
/// - Write progress animation
/// - Success confirmation with haptic feedback
/// 
/// **Note**: Writing is only supported on Android. iOS restricts third-party NFC writes.
class NFCWriterModal extends StatefulWidget {
  final String? initialData;
  final String? mimeType;
  final VoidCallback? onSuccess;

  const NFCWriterModal({
    this.initialData,
    this.mimeType,
    this.onSuccess,
    super.key,
  });

  /// Show the writer modal as a bottom sheet
  static Future<bool?> show(
    BuildContext context, {
    String? initialData,
    String? mimeType,
    VoidCallback? onSuccess,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NFCWriterModal(
        initialData: initialData,
        mimeType: mimeType,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<NFCWriterModal> createState() => _NFCWriterModalState();
}

class _NFCWriterModalState extends State<NFCWriterModal>
    with SingleTickerProviderStateMixin {
  late TextEditingController _dataController;
  late AnimationController _writeController;
  late Animation<double> _writeAnimation;
  late NFCBloc _nfcBloc;
  String _selectedMimeType = 'text/plain';

  static const _mimeTypes = [
    'text/plain',
    'application/json',
    'text/vcard',
    'application/x-momo', // Mobile money custom type
  ];

  @override
  void initState() {
    super.initState();
    _nfcBloc = NFCBloc(NFCService.instance);
    _dataController = TextEditingController(text: widget.initialData);
    _selectedMimeType = widget.mimeType ?? 'text/plain';

    _writeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _writeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _writeController, curve: Curves.easeInOut),
    );
  }

  void _startWrite() {
    if (_dataController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter data to write')),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    _writeController.repeat();
    
    _nfcBloc.add(WriteNFCTag(
      data: _dataController.text,
      mimeType: _selectedMimeType,
    ));
  }

  void _onWriteSuccess() {
    _writeController.stop();
    _writeController.reset();
    HapticFeedback.heavyImpact();
    widget.onSuccess?.call();
    
    // Show success and close
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pop(true);
    });
  }

  void _onWriteError() {
    _writeController.stop();
    _writeController.reset();
    HapticFeedback.vibrate();
  }

  @override
  void dispose() {
    _dataController.dispose();
    _writeController.dispose();
    _nfcBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // iOS restriction check
    if (!Platform.isAndroid) {
      return _buildIOSRestrictionUI();
    }

    return BlocProvider.value(
      value: _nfcBloc,
      child: BlocConsumer<NFCBloc, NFCState>(
        listener: (context, state) {
          if (state is NFCWriteSuccess) {
            _onWriteSuccess();
          } else if (state is NFCError) {
            _onWriteError();
          }
        },
        builder: (context, state) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E).withValues(alpha: 0.98),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHandle(),
                    const SizedBox(height: 24),
                    _buildHeader(state),
                    const SizedBox(height: 24),
                    if (state is! NFCWriting && state is! NFCWriteSuccess)
                      ..._buildInputSection(),
                    const SizedBox(height: 24),
                    _buildWriteArea(state),
                    const SizedBox(height: 24),
                    _buildActionButton(state),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIOSRestrictionUI() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withValues(alpha: 0.98),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHandle(),
              const SizedBox(height: 32),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.phone_iphone,
                  size: 50,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'iOS Restriction',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Apple restricts NFC writing for third-party apps.\n'
                'You can still read NFC tags on iOS.\n\n'
                'To write NFC tags, please use an Android device.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Got It',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(NFCState state) {
    String title;
    IconData icon;
    Color color;

    if (state is NFCWriteSuccess) {
      title = 'Write Successful';
      icon = Icons.check_circle;
      color = Colors.greenAccent;
    } else if (state is NFCWriting) {
      title = 'Hold Near Tag';
      icon = Icons.nfc;
      color = Colors.blueAccent;
    } else if (state is NFCError) {
      title = 'Write Failed';
      icon = Icons.error;
      color = Colors.redAccent;
    } else {
      title = 'Write NFC Tag';
      icon = Icons.edit_note;
      color = Colors.blueAccent;
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildInputSection() {
    return [
      // Data input
      TextField(
        controller: _dataController,
        style: const TextStyle(color: Colors.white),
        maxLines: 3,
        decoration: InputDecoration(
          labelText: 'Data to Write',
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          hintText: 'Enter text, JSON, or vCard data...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blueAccent),
          ),
        ),
      ),
      const SizedBox(height: 16),
      // MIME type selector
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedMimeType,
            isExpanded: true,
            dropdownColor: const Color(0xFF2A2A4E),
            style: const TextStyle(color: Colors.white),
            icon: Icon(
              Icons.arrow_drop_down,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            items: _mimeTypes.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedMimeType = value);
              }
            },
          ),
        ),
      ),
    ];
  }

  Widget _buildWriteArea(NFCState state) {
    if (state is NFCWriting) {
      return Center(
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _writeAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_writeAnimation.value * 0.1),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.nfc,
                      size: 50,
                      color: Colors.blueAccent,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Waiting for NFC tag...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    if (state is NFCWriteSuccess) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.greenAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.greenAccent.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.greenAccent,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Data written successfully!',
              style: TextStyle(
                color: Colors.greenAccent,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _dataController.text.length > 50
                  ? '${_dataController.text.substring(0, 50)}...'
                  : _dataController.text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (state is NFCError) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.redAccent.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                state.message,
                style: TextStyle(
                  color: Colors.redAccent.withValues(alpha: 0.9),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Info card for initial state
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blueAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Enter the data above and tap Write. '
              'Then hold your phone near an NFC tag to write.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(NFCState state) {
    if (state is NFCWriting) {
      return TextButton(
        onPressed: () {
          _nfcBloc.add(StopNFCScan());
          _writeController.stop();
          _writeController.reset();
        },
        child: Text(
          'Cancel',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 16,
          ),
        ),
      );
    }

    if (state is NFCWriteSuccess) {
      return ElevatedButton(
        onPressed: () => Navigator.pop(context, true),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.greenAccent,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Done',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return ElevatedButton(
      onPressed: _startWrite,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.nfc),
          const SizedBox(width: 8),
          Text(
            state is NFCError ? 'Try Again' : 'Write to Tag',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
