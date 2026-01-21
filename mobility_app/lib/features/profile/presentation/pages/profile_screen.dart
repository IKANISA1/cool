import 'package:flutter/material.dart'; // Core Flutter framework
import 'package:glassmorphism/glassmorphism.dart';
import 'package:ridelink/shared/services/qr_service.dart';
// Note: In real app, get user data from Auth/Profile Bloc
// Assuming a 'User' model or similar exists or we mock it for UI

class ProfileScreen extends StatelessWidget {
  final String userId = "user_12345";
  final String userName = "Jean Bosco";
  final String userRole = "Driver";
  
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final qrService = QRService();
    // Assuming qrService.generateQRCode returns a Widget, based on my implementation
    final qrData = qrService.generateProfileQR(userId: userId, name: userName, role: userRole);

    return Scaffold(
      backgroundColor: Colors.black87,
      body: Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0f0c29), Color(0xFF302b63), Color(0xFF24243e)],
            )
        ),
        child: SafeArea(
          child: Column(
            children: [
               const SizedBox(height: 20),
               const Text('My Profile', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
               const SizedBox(height: 40),
               
               Center(
                 child: GlassmorphicContainer(
                   width: 300,
                   height: 500,
                   borderRadius: 20,
                   blur: 20,
                   alignment: Alignment.center,
                   border: 2,
                   linearGradient: LinearGradient(
                      colors: [Colors.white.withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.05)],
                   ),
                   borderGradient: LinearGradient(
                      colors: [Colors.white.withValues(alpha: 0.5), Colors.white.withValues(alpha: 0.5)],
                   ),
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                        const CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.purpleAccent,
                          child: Icon(Icons.person, size: 50, color: Colors.white),
                        ),
                        const SizedBox(height: 20),
                        Text(userName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        Text(userRole, style: const TextStyle(color: Colors.cyanAccent, fontSize: 16)),
                        
                        const SizedBox(height: 30),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12)
                          ),
                          child: qrService.generateQRCode(data: qrData, size: 180),
                        ),
                        
                        const SizedBox(height: 20),
                        const Text('Scan to verify or pay', style: TextStyle(color: Colors.white54, fontSize: 12)),
                     ],
                   ),
                 ),
               )
            ],
          ),
        ),
      ),
    );
  }
}
