import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'services/firebase_service.dart';
import 'widgets/app_colors.dart';
import 'widgets/ui_components.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _pinController = TextEditingController();
  bool _isError = false;

  void _verifyPin() async {
    if (_pinController.text == '1111') {
      setState(() {
        _isError = false;
      });
      _performLogin();
    } else {
      setState(() {
        _isError = true;
        _pinController.clear();
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid PIN. Please try again.')),
        );
      }
    }
  }

  void _performLogin() async {
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);
    try {
      await firebaseService.loginAsMember('Admin');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  void _openQRScanner(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Scan QR Code', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF070D1F),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: MobileScanner(
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
              // Successfully scanned a QR Code. Any valid QR code works for this simple logic.
              Navigator.of(context).pop(); // Close scanner
              _performLogin();
            }
          },
        ),
      ),
    ));
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF070D1F), Color(0xFF0B1026)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 80,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(height: 24),
              const Text(
                'Enter PIN',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Enter your PIN or scan QR code',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: GlassBox(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      style: const TextStyle(
                        fontSize: 32,
                        letterSpacing: 24,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                        hintText: '••••',
                        hintStyle: TextStyle(
                          color: AppColors.textSecondary.withOpacity(0.5),
                          letterSpacing: 24,
                        ),
                        errorText: _isError ? 'Incorrect PIN' : null,
                      ),
                      onChanged: (value) {
                        if (value.length == 4) {
                          _verifyPin();
                        }
                        if (_isError) {
                          setState(() {
                            _isError = false;
                          });
                        }
                      },
                      onSubmitted: (_) => _verifyPin(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _verifyPin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Login',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              const Text('OR', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => _openQRScanner(context),
                icon: const Icon(Icons.qr_code_scanner, color: AppColors.primaryBlue),
                label: const Text('Scan QR Code', style: TextStyle(color: AppColors.primaryBlue, fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  side: const BorderSide(color: AppColors.primaryBlue, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}