import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

class MobilePdfViewerScreen extends StatefulWidget {
  const MobilePdfViewerScreen({
    super.key,
    required this.title,
    required this.filePath,
    this.isOffline = false,
  });

  final String title;
  final String filePath;
  final bool isOffline;

  @override
  State<MobilePdfViewerScreen> createState() => _MobilePdfViewerScreenState();
}

class _MobilePdfViewerScreenState extends State<MobilePdfViewerScreen> {
  late final PdfControllerPinch _controller;

  @override
  void initState() {
    super.initState();
    _controller = PdfControllerPinch(
      document: PdfDocument.openFile(widget.filePath),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (widget.isOffline)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Center(
                child: Chip(
                  avatar: Icon(Icons.offline_pin, size: 16),
                  label: Text('Offline copy'),
                ),
              ),
            ),
        ],
      ),
      body: PdfViewPinch(
        controller: _controller,
      ),
    );
  }
}
