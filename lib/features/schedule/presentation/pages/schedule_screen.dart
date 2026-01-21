import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:ridelink/shared/services/gemini_service.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormBuilderState>();
  final _aiController = TextEditingController();
  final GeminiService _geminiService = GeminiService(); // Should utilize DI in real app
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _handleAiSubmit() async {
    if (_aiController.text.isEmpty) return;
    setState(() => _isLoading = true);
    
    try {
      final tripData = await _geminiService.parseTripRequest(_aiController.text);
      // Here we would populate the form or confirm data
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Parsed: ${tripData.origin} -> ${tripData.destination}')),
        );
        // Switch to form tab and populate? Or show confirmation dialog.
        // For now, let's just show success.
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error parsing request: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Schedule Ride', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.cyanAccent,
          labelColor: Colors.white,
          tabs: const [
            Tab(text: 'Manual'),
            Tab(text: 'AI Assistant'),
          ],
        ),
      ),
      backgroundColor: Colors.black87, // Fallback if no bg image
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
          )
        ),
        child: SafeArea(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildManualForm(),
              _buildAiAssistant(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManualForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: FormBuilder(
        key: _formKey,
        child: Column(
          children: [
            GlassmorphicContainer(
               width: double.infinity,
               height: 300,
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
               child: Padding(
                 padding: const EdgeInsets.all(16.0),
                 child: Column(
                   children: [
                     FormBuilderTextField(
                       name: 'origin',
                       decoration: const InputDecoration(
                         labelText: 'Origin',
                         labelStyle: TextStyle(color: Colors.white70),
                         prefixIcon: Icon(Icons.my_location, color: Colors.cyanAccent),
                         enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                       ),
                       style: const TextStyle(color: Colors.white),
                       validator: FormBuilderValidators.required(),
                     ),
                     const SizedBox(height: 16),
                      FormBuilderTextField(
                       name: 'destination',
                       decoration: const InputDecoration(
                         labelText: 'Destination',
                          labelStyle: TextStyle(color: Colors.white70),
                         prefixIcon: Icon(Icons.location_on, color: Colors.cyanAccent),
                         enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                       ),
                        style: const TextStyle(color: Colors.white),
                       validator: FormBuilderValidators.required(),
                     ),
                     const SizedBox(height: 16),
                     FormBuilderDateTimePicker(
                       name: 'time',
                       inputType: InputType.both,
                       decoration: const InputDecoration(
                         labelText: 'Departure Time',
                          labelStyle: TextStyle(color: Colors.white70),
                         prefixIcon: Icon(Icons.access_time, color: Colors.cyanAccent),
                           enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                       ),
                        style: const TextStyle(color: Colors.white),
                       validator: FormBuilderValidators.required(),
                     ),
                   ],
                 ),
               ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  if (_formKey.currentState?.saveAndValidate() ?? false) {
                    // Submit
                  }
                },
                child: const Text('Schedule', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAiAssistant() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, color: Colors.purpleAccent, size: 60),
          const SizedBox(height: 20),
          const Text(
            'Tell me about your trip',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Example: "I need a ride from Kigali Heights to Airport tomorrow at 10 AM, 2 seats"',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 30),
          TextField(
            controller: _aiController,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.1),
              hintText: 'Type your request here...',
              hintStyle: const TextStyle(color: Colors.white30),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const CircularProgressIndicator(color: Colors.purpleAccent)
          else
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _handleAiSubmit,
                icon: const Icon(Icons.send, color: Colors.white),
                label: const Text('Parse Request', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            )
        ],
      ),
    );
  }
}
