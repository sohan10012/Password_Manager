// lib/screens/password_generator_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:password_manager/screens/password_generator.dart'; 

class PasswordGeneratorScreen extends StatefulWidget {
  const PasswordGeneratorScreen({super.key});

  @override
  _PasswordGeneratorScreenState createState() => _PasswordGeneratorScreenState();
}

class _PasswordGeneratorScreenState extends State<PasswordGeneratorScreen> {
  String _password = '';
  int _length = 16;
  bool _uppercase = true;
  bool _lowercase = true;
  bool _numbers = true;
  bool _symbols = true;
  String _strength = '';

  @override
  void initState() {
    super.initState();
    _generatePassword();
  }

  void _generatePassword() {
    try {
      _password = PasswordGenerator.generate(
        length: _length,
        includeUppercase: _uppercase,  // Fixed parameter name
        includeLowercase: _lowercase,  // Fixed parameter name
        includeNumbers: _numbers,      // Fixed parameter name
        includeSymbols: _symbols,      // Fixed parameter name
        avoidAmbiguous: true,
      );
      final score = PasswordGenerator.calculateStrength(_password); // Fixed method
      _strength = PasswordGenerator.getStrengthLabel(score);       // Fixed method
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _copyPassword() {
    Clipboard.setData(ClipboardData(text: _password));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Password copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Password Generator'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Generated Password
            Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      _strength,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getStrengthColor(_strength),
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _getStrengthColor(_strength).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _password,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _copyPassword,
                          icon: Icon(Icons.copy),
                          label: Text('Copy'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _generatePassword,
                          icon: Icon(Icons.refresh),
                          label: Text('Generate'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            
            // Settings
            Expanded(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 16),
                      
                      // Length Slider
                      Text('Length: $_length'),
                      Slider(
                        value: _length.toDouble(),
                        min: 8,
                        max: 32,
                        divisions: 24,
                        onChanged: (value) {
                          setState(() => _length = value.toInt());
                          _generatePassword();
                        },
                      ),
                      
                      // Toggles
                      SwitchListTile(
                        title: Text('Uppercase Letters'),
                        value: _uppercase,
                        onChanged: (value) {
                          setState(() => _uppercase = value);
                          _generatePassword();
                        },
                      ),
                      SwitchListTile(
                        title: Text('Lowercase Letters'),
                        value: _lowercase,
                        onChanged: (value) {
                          setState(() => _lowercase = value);
                          _generatePassword();
                        },
                      ),
                      SwitchListTile(
                        title: Text('Numbers'),
                        value: _numbers,
                        onChanged: (value) {
                          setState(() => _numbers = value);
                          _generatePassword();
                        },
                      ),
                      SwitchListTile(
                        title: Text('Symbols'),
                        value: _symbols,
                        onChanged: (value) {
                          setState(() => _symbols = value);
                          _generatePassword();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStrengthColor(String strength) {
    switch (strength) {
      case 'Very Strong': return Colors.green;
      case 'Strong': return Colors.blue;
      case 'Medium': return Colors.orange;
      default: return Colors.red;
    }
  }
}