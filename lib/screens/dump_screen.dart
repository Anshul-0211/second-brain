import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../app/theme.dart';
import '../providers/providers.dart';
import '../widgets/inline_note_input.dart';
import '../widgets/file_preview.dart';
import '../services/file_picker_service.dart';
import '../services/clipboard_service.dart';

class DumpScreen extends StatefulWidget {
  const DumpScreen({super.key});

  @override
  State<DumpScreen> createState() => _DumpScreenState();
}

class _DumpScreenState extends State<DumpScreen> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _isProcessing = false;
  bool _isSavingNote = false;
  String _detectedType = '';
  Map<String, dynamic>? _result;
  String? _savedItemId;
  List<File> _selectedFiles = [];

  void _detectType(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      setState(() => _detectedType = '');
      return;
    }
    
    final urlRegex = RegExp(r'^(https?:\/\/)?([\w-]+\.)+[\w-]+(\/[\w\-./?%&=]*)?$', caseSensitive: false);
    final hasUrl = RegExp(r'https?:\/\/[^\s]+', caseSensitive: false);
    
    if (urlRegex.hasMatch(trimmed) || trimmed.startsWith('http') || trimmed.startsWith('www')) {
      setState(() => _detectedType = 'link');
    } else if (hasUrl.hasMatch(trimmed)) {
      setState(() => _detectedType = 'link');
    } else {
      setState(() => _detectedType = 'note');
    }
  }

  Future<void> _pickFiles() async {
    try {
      final files = await FilePickerService.pickFiles(
        dialogTitle: 'Select files to attach',
        allowMultiple: true,
      );

      if (files.isNotEmpty) {
        if (files.length > 4) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('📦 Maximum 4 files per item. First 4 selected.'),
                backgroundColor: const Color(0xFFFCA311),
              ),
            );
          }
          setState(() {
            _selectedFiles = files.take(4).toList();
          });
        } else {
          setState(() {
            _selectedFiles = files;
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Added ${_selectedFiles.length} file${_selectedFiles.length > 1 ? 's' : ''}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking files: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _pasteFromClipboard() async {
    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📋 Reading clipboard...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Get clipboard content
      final content = await ClipboardService.getClipboardContent();

      if (content.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📋 Clipboard is empty'),
              backgroundColor: Color(0xFFFCA311),
            ),
          );
        }
        return;
      }

      // Handle text content
      if (content.hasText && content.text != null) {
        setState(() {
          // Append to existing text with proper spacing
          if (_controller.text.isNotEmpty && !_controller.text.endsWith('\n')) {
            _controller.text += '\n';
          }
          _controller.text += content.text!;
          _detectType(_controller.text);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Pasted text (${content.text!.length} chars)',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }

      // Handle image content
      if (content.hasImages) {
        // Check file count limit (max 4)
        final totalFiles = _selectedFiles.length + content.images.length;
        if (totalFiles > 4) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '📦 Max 4 files. Adding ${4 - _selectedFiles.length} of ${content.images.length} images.',
                ),
                backgroundColor: const Color(0xFFFCA311),
              ),
            );
          }
          setState(() {
            _selectedFiles.addAll(
              content.images.take(4 - _selectedFiles.length),
            );
          });
        } else {
          setState(() {
            _selectedFiles.addAll(content.images);
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '✅ Added ${content.images.length} image${content.images.length > 1 ? 's' : ''} from clipboard',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error pasting from clipboard: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _removeSelectedFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _saveToBrain() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _isProcessing = true;
      _result = null;
      _savedItemId = null;
    });

    try {
      Map<String, dynamic>? result;
      
      // If files are selected, use the file upload endpoint
      if (_selectedFiles.isNotEmpty) {
        final item = await context.read<ItemsProvider>().addItemWithFiles(
          _controller.text.trim(),
          files: _selectedFiles,
        );
        result = {'itemId': item.id, 'item': item};
      } else {
        // Otherwise use the regular text endpoint
        result = await context.read<ItemsProvider>().addItem(_controller.text.trim());
      }
      
      setState(() {
        _result = result;
        _savedItemId = result?['itemId'];
        _isProcessing = false;
      });

      // If there's a note, save it immediately
      if (_noteController.text.trim().isNotEmpty && _savedItemId != null) {
        await _saveNoteToItem();
      } else {
        // Clear after short delay to show success
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          setState(() {
            _controller.clear();
            _noteController.clear();
            _selectedFiles.clear();
            _detectedType = '';
            _result = null;
            _savedItemId = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _saveNoteToItem() async {
    if (_savedItemId == null || _noteController.text.trim().isEmpty) return;

    setState(() => _isSavingNote = true);

    try {
      await context.read<ItemsProvider>().addNoteToItem(
        _savedItemId!,
        _noteController.text.trim(),
      );

      if (mounted) {
        setState(() => _isSavingNote = false);
        // Clear after success
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          setState(() {
            _controller.clear();
            _noteController.clear();
            _selectedFiles.clear();
            _detectedType = '';
            _result = null;
            _savedItemId = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSavingNote = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save note: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasContent = _controller.text.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [
              // ─── Title Greeting ───
              Text(
                'Dump Your Thoughts',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),

              const SizedBox(height: 8),

              Text(
                'Save links, notes, ideas — we\'ll organize them for you',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.onSurfaceVariant,
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

              const SizedBox(height: 32),

              // ─── Main Content Input (Centered) ───
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Main text field
                    Container(
                      decoration: glassDecoration(withGlow: _controller.text.isNotEmpty),
                      child: TextField(
                        controller: _controller,
                        onChanged: (text) {
                          _detectType(text);
                          setState(() {});
                        },
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.center,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: AppTheme.onSurface,
                          height: 1.6,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Paste a link or type a note...',
                          hintStyle: GoogleFonts.inter(
                            color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3),
                            fontSize: 16,
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.all(24),
                        ),
                      ),
                    ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideY(begin: 0.05),

                    // Voice button overlay (top-right)
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Paste button
                          Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF667EEA).withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _pasteFromClipboard,
                                borderRadius: BorderRadius.circular(28),
                                child: const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Icon(
                                    Icons.content_paste,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ).animate().fadeIn(duration: 500.ms, delay: 400.ms).scale(),
                          
                          const SizedBox(width: 12),

                          // File picker button
                          Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF667EEA).withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _pickFiles,
                                borderRadius: BorderRadius.circular(28),
                                child: const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Icon(
                                    Icons.attach_file,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ).animate().fadeIn(duration: 500.ms, delay: 300.ms).scale(),
                          
                          const SizedBox(width: 12),

                          // Voice button
                          Container(
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryDim.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  // Voice button placeholder (will be implemented next)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Voice notes coming in the next update! 🎤'),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(28),
                                child: const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Icon(
                                    Icons.mic,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ).animate().fadeIn(duration: 500.ms, delay: 400.ms).scale(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ─── Conditional Inline Note Input ───
              if (hasContent)
                InlineNoteInput(
                  notesController: _noteController,
                  isLoading: _isSavingNote,
                  onNoteSaved: (_) {
                    // Note will be saved along with item
                  },
                ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1),

              const SizedBox(height: 12),

              // ─── File Selection Preview (Native only, web shows count) ───
              if (_selectedFiles.isNotEmpty)
                if (kIsWeb)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      '📎 ${_selectedFiles.length} file${_selectedFiles.length > 1 ? 's' : ''} selected',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1)
                else
                  FileSelectionPreview(
                    selectedFiles: _selectedFiles,
                    onRemove: _removeSelectedFile,
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1),

              if (_selectedFiles.isNotEmpty) const SizedBox(height: 12),

              // ─── Detected Type Badge ───
              if (_detectedType.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _detectedType == 'link' ? Icons.link : Icons.edit_note,
                        size: 14,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Detected: ${_detectedType == 'link' ? 'Link 🔗' : 'Note 📝'}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms),

              // ─── Result Banner ───
              if (_result != null)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Saved to brain! ✨',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),

              const SizedBox(height: 12),

              // ─── Save Button ───
              SizedBox(
                width: double.infinity,
                height: 56,
                child: _isProcessing
                    ? Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: _controller.text.trim().isNotEmpty
                              ? AppTheme.primaryGradient
                              : null,
                          color: _controller.text.trim().isEmpty
                              ? AppTheme.surfaceContainerHigh
                              : null,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: _controller.text.trim().isNotEmpty
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primaryDim.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _controller.text.trim().isNotEmpty ? _saveToBrain : null,
                            borderRadius: BorderRadius.circular(14),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.psychology,
                                    color: _controller.text.trim().isNotEmpty
                                        ? Colors.white
                                        : AppTheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Save to Brain',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: _controller.text.trim().isNotEmpty
                                          ? Colors.white
                                          : AppTheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
              ).animate().fadeIn(duration: 600.ms, delay: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
