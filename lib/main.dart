import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  // IMPORTANT: Replace with your actual OpenAI API Key
  OpenAI.apiKey = 'YOUR_OPENAI_API_KEY';
  runApp(const ScannerApp());
}

class ScannerApp extends StatelessWidget {
  const ScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aura Scanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6750A4),
          secondary: Color(0xFF03DAC6),
          surface: Color(0xFF1E1E1E),
          background: Color(0xFF121212),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF1E1E1E),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

// ==========================================
// HOME SCREEN
// ==========================================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Aura',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              const Text(
                'Smart Scanner',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white54,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const Spacer(),
              _ScannerOptionCard(
                title: 'Document Scanner',
                subtitle: 'PDF, Magic Color, Edge Detection',
                icon: Icons.document_scanner_outlined,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const DocumentScannerScreen())),
              ),
              const SizedBox(height: 20),
              _ScannerOptionCard(
                title: 'Visiting Card',
                subtitle: 'OCR + AI Smart Extraction',
                icon: Icons.contact_page_outlined,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CardScannerScreen())),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannerOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ScannerOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.secondary, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 14)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// DOCUMENT SCANNER SCREEN
// ==========================================
class DocumentScannerScreen extends StatefulWidget {
  const DocumentScannerScreen({super.key});

  @override
  State<DocumentScannerScreen> createState() => _DocumentScannerScreenState();
}

class _DocumentScannerScreenState extends State<DocumentScannerScreen> {
  String? _pdfPath;
  List<String> _jpegPaths = [];
  bool _isScanning = false;

  Future<void> _startScan() async {
    setState(() => _isScanning = true);
    try {
      final documentScanner = DocumentScanner(
        options: DocumentScannerOptions(
          documentFormat: DocumentFormat.pdfAndJpeg,
          mode: ScannerMode.full, // Enables auto edge detection, manual crop, and filters
          pageLimit: 5,
          isGalleryImport: true,
        ),
      );

      final result = await documentScanner.scanDocument();
      setState(() {
        _pdfPath = result.pdf?.path;
        _jpegPaths = result.jpegs?.map((e) => e.path).toList() ?? [];
      });
    } catch (e) {
      debugPrint("Scan Error: $e");
    } finally {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _shareScan() async {
    if (_pdfPath != null) {
      await Share.shareXFiles([XFile(_pdfPath!)], text: 'Scanned Document');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Scan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isScanning
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_jpegPaths.isNotEmpty || _pdfPath != null)
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _jpegPaths.length,
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(File(_jpegPaths[index]), fit: BoxFit.cover),
                          );
                        },
                      ),
                    )
                  else
                    const Expanded(
                      child: Center(
                        child: Text(
                          'No documents scanned yet.\nTap the button below to start.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  if (_pdfPath != null)
                    ElevatedButton.icon(
                      onPressed: _shareScan,
                      icon: const Icon(Icons.share),
                      label: const Text('Share PDF'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _startScan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Scan Document', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
    );
  }
}

// ==========================================
// VISITING CARD SCANNER SCREEN
// ==========================================
class CardScannerScreen extends StatefulWidget {
  const CardScannerScreen({super.key});

  @override
  State<CardScannerScreen> createState() => _CardScannerScreenState();
}

class _CardScannerScreenState extends State<CardScannerScreen> {
  File? _image;
  bool _isProcessing = false;
  Map<String, String> _extractedData = {};
  final _formKey = GlobalKey<FormState>();

  // Controllers for editable fields
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _companyController = TextEditingController();
  final _jobTitleController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _jobTitleController.dispose();
    super.dispose();
  }

  Future<void> _captureCard() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _isProcessing = true;
        _extractedData.clear();
      });
      await _processCard();
    }
  }

  Future<void> _processCard() async {
    try {
      // 1. Extract Raw Text
      final textRecognizer = TextRecognizer();
      final RecognizedText recognizedText = await textRecognizer.processImage(
        InputImage.fromFile(_image!),
      );
      await textRecognizer.close();

      // 2. Send to OpenAI for JSON structuring
      final prompt = '''
      Extract contact information from the following OCR text of a visiting card.
      Return ONLY a valid JSON object with the following keys: 
      "First Name", "Last Name", "Phone Number", "Email", "Company", "Job Title".
      If a field is not found, return an empty string for that field.
      
      OCR Text:
      ${recognizedText.text}
      ''';

      final completion = await OpenAI.instance.chat.create(
        model: "gpt-4o-mini",
        messages: [
          ChatMessage(role: ChatUserRole.system, content: "You are a helpful assistant that extracts contact info into JSON."),
          ChatMessage(role: ChatUserRole.user, content: prompt),
        ],
        responseFormat: {"type": "json_object"},
      );

      String jsonContent = completion.choices.first.message.content;
      // Clean up markdown if present
      jsonContent = jsonContent.replaceAll('```json', '').replaceAll('```', '').trim();

      final Map<String, dynamic> parsed = _parseJson(jsonContent);
      
      setState(() {
        _firstNameController.text = parsed['First Name'] ?? '';
        _lastNameController.text = parsed['Last Name'] ?? '';
        _phoneController.text = parsed['Phone Number'] ?? '';
        _emailController.text = parsed['Email'] ?? '';
        _companyController.text = parsed['Company'] ?? '';
        _jobTitleController.text = parsed['Job Title'] ?? '';
      });

    } catch (e) {
      debugPrint("Processing Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to process card. Please try again.')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Map<String, dynamic> _parseJson(String jsonString) {
    // Simple JSON cleaner (in production, use dart:convert)
    jsonString = jsonString.trim();
    if (jsonString.startsWith('{') && jsonString.endsWith('}')) {
      return Map<String, dynamic>.from(
        // ignore: avoid_dynamic_calls
        (jsonString.split(',').fold<Map<String, dynamic>>({}, (map, item) {
          final parts = item.split(':');
          if (parts.length == 2) {
            String key = parts[0].trim().replaceAll(RegExp(r'[{"\}]'), '');
            String value = parts[1].trim().replaceAll(RegExp(r'[{"\}]'), '');
            map[key] = value;
          }
          return map;
        })),
      );
    }
    return {};
  }

  Future<void> _saveToContacts() async {
    if (await FlutterContacts.requestPermission()) {
      final newContact = Contact(
        name: Name(
          first: _firstNameController.text,
          last: _lastNameController.text,
        ),
        organizations: [
          Organization(company: _companyController.text, title: _jobTitleController.text)
        ],
        emails: [Email(_emailController.text)],
        phones: [Phone(_phoneController.text)],
      );
      
      await newContact.insert();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact saved successfully!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contacts permission denied')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visiting Card'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isProcessing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text('AI is extracting data...', style: TextStyle(color: Colors.white70)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_image != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(_image!, height: 180, width: double.infinity, fit: BoxFit.cover),
                      )
                    else
                      GestureDetector(
                        onTap: _captureCard,
                        child: Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white10, width: 2),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, size: 40, color: Colors.white54),
                              SizedBox(height: 8),
                              Text('Tap to capture card', style: TextStyle(color: Colors.white54)),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 30),
                    _buildEditableField('First Name', _firstNameController),
                    _buildEditableField('Last Name', _lastNameController),
                    _buildEditableField('Phone Number', _phoneController, keyboardType: TextInputType.phone),
                    _buildEditableField('Email', _emailController, keyboardType: TextInputType.emailAddress),
                    _buildEditableField('Company', _companyController),
                    _buildEditableField('Job Title', _jobTitleController),
                    const SizedBox(height: 30),
                    if (_image != null)
                      ElevatedButton.icon(
                        onPressed: _saveToContacts,
                        icon: const Icon(Icons.person_add),
                        label: const Text('Save to Contacts'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2),
          ),
        ),
      ),
    );
  }
}
