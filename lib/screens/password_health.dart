import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_svg/svg.dart'; 
import 'package:password_manager/helper/encryption_helper.dart';

class PasswordHealth extends StatefulWidget {
  const PasswordHealth({super.key});

  @override
  State<PasswordHealth> createState() => _PasswordHealthState();
}

class _PasswordHealthState extends State<PasswordHealth> {
  int safeCount = 0;
  int compromisedCount = 0;
  int weakCount = 0;
  int reusedCount = 0;
  int totalCount = 0;
  bool isLoading = true;

  // Store details for each category
  List<Map<String, String>> safeList = [];
  List<Map<String, String>> compromisedList = [];
  List<Map<String, String>> weakList = [];
  List<Map<String, String>> reusedList = [];

  @override
  void initState() {
    super.initState();
    _analyzePasswords();
  }

  Future<void> _analyzePasswords() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }
    final databaseRef = FirebaseDatabase.instance.ref();
    try {
      final snapshot = await databaseRef.child('users/$uid/passwords').get();
      if (!snapshot.exists) {
        setState(() {
          isLoading = false;
        });
        return;
      }
      Map<dynamic, dynamic> values = snapshot.value as Map;
      List<Map<String, String>> allPasswords = [];
      Map<String, int> passwordUsage = {};
      int safe = 0, compromised = 0, weak = 0, reused = 0;

      for (var entry in values.entries) {
        final value = entry.value as Map;
        final decryptedPassword = await EncryptionHelper.decrypt(
          value['password'] ?? '',
          value['password_iv'] ?? '',
        );
        final decryptedUsername = await EncryptionHelper.decrypt(
          value['username'] ?? '',
          value['username_iv'] ?? '',
        );
        allPasswords.add({
          'username': decryptedUsername,
          'password': decryptedPassword,
        });
        passwordUsage[decryptedPassword] =
            (passwordUsage[decryptedPassword] ?? 0) + 1;
      }

      // Clear previous lists
      safeList.clear();
      compromisedList.clear();
      weakList.clear();
      reusedList.clear();

      for (var item in allPasswords) {
        final pwd = item['password'] ?? '';
        final username = item['username'] ?? '';
        bool isWeak = _isWeakPassword(pwd);
        bool isCompromised = _isCompromisedPassword(pwd); // Mocked
        bool isReused = (passwordUsage[pwd] ?? 0) > 1;

        if (isCompromised) {
          compromised++;
          compromisedList.add({'username': username, 'password': pwd});
        } else if (isWeak) {
          weak++;
          weakList.add({'username': username, 'password': pwd});
        } else if (isReused) {
          reused++;
          reusedList.add({'username': username, 'password': pwd});
        } else {
          safe++;
          safeList.add({'username': username, 'password': pwd});
        }
      }

      setState(() {
        safeCount = safe;
        compromisedCount = compromised;
        weakCount = weak;
        reusedCount = reused;
        totalCount = allPasswords.length;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  bool _isWeakPassword(String password) {
    // Example: less than 8 chars or only letters or only digits
    if (password.length < 8) return true;
    if (RegExp(r'^[a-zA-Z]+$').hasMatch(password)) return true;
    if (RegExp(r'^\d+$').hasMatch(password)) return true;
    // Add more checks as needed
    return false;
  }

  bool _isCompromisedPassword(String password) {
    // Mock: treat 'password', '123456', 'qwerty' as compromised
    const compromisedList = {'password', '123456', 'qwerty'};
    return compromisedList.contains(password.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Password Health',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Circular Progress Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Circular Progress
                          SizedBox(
                            width: 160,
                            height: 160,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Background circle
                                SizedBox(
                                  width: 160,
                                  height: 160,
                                  child: CircularProgressIndicator(
                                    value: 1.0,
                                    strokeWidth: 12,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.grey[200]!,
                                    ),
                                  ),
                                ),
                                // Progress segments
                                SizedBox(
                                  width: 160,
                                  height: 160,
                                  child: CustomPaint(
                                    painter: ProgressPainter(
                                      safe: safeCount,
                                      reused: reusedCount,
                                      weak: weakCount,
                                      compromised: compromisedCount,
                                      total: totalCount,
                                    ),
                                  ),
                                ),
                                // Center text
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      totalCount > 0
                                          ? ((safeCount / totalCount) * 100)
                                              .round()
                                              .toString()
                                          : '0',
                                      style: TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    Text(
                                      'Total score',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Legend
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildLegendItem(
                                Colors.blue,
                                'Safe ($safeCount)',
                              ),
                              _buildLegendItem(
                                Colors.yellow[600]!,
                                'Reused ($reusedCount)',
                              ),
                              _buildLegendItem(Colors.red, 'Weak ($weakCount)'),
                              _buildLegendItem(
                                Colors.teal,
                                'Compromised ($compromisedCount)',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Password Categories List
                    Expanded(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap:
                                () => _showPasswordListDialog(
                                  context,
                                  'Safe Passwords',
                                  safeList,
                                ),
                            child: _buildPasswordCategory(
                              'assets/password_svg/password_gen.svg',
                              'Safe Password',
                              '$safeCount found',
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap:
                                () => _showPasswordListDialog(
                                  context,
                                  'Compromised Passwords',
                                  compromisedList,
                                ),
                            child: _buildPasswordCategory(
                              'assets/password_svg/crack_password.svg',
                              'Compromised Password',
                              '$compromisedCount found',
                              Colors.teal,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap:
                                () => _showPasswordListDialog(
                                  context,
                                  'Weak Passwords',
                                  weakList,
                                ),
                            child: _buildPasswordCategory(
                              'assets/password_svg/weak_password.svg',
                              'Weak Password',
                              '$weakCount found',
                              Colors.red,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap:
                                () => _showPasswordListDialog(
                                  context,
                                  'Reused Passwords',
                                  reusedList,
                                ),
                            child: _buildPasswordCategory(
                              'assets/password_svg/reuse_password.svg',
                              'Reused Password',
                              '$reusedCount found',
                              Colors.yellow[600]!,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  void _showPasswordListDialog(
    BuildContext context,
    String title,
    List<Map<String, String>> list,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: double.maxFinite,
              child:
                  list.isEmpty
                      ? const Text('No passwords found.')
                      : ListView.builder(
                        shrinkWrap: true,
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final item = list[index];
                          return ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(item['username'] ?? ''),
                            subtitle: Text(item['password'] ?? ''),
                            // trailing: IconButton(
                            //   icon: const Icon(Icons.copy),
                            //   onPressed: () {
                            //     Clipboard.setData(
                            //       ClipboardData(text: item['password'] ?? ''),
                            //     );
                            //     ScaffoldMessenger.of(context).showSnackBar(
                            //       const SnackBar(
                            //         content: Text('Password copied'),
                            //       ),
                            //     );
                            //   },
                            // ),
                          );
                        },
                      ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  //

  Widget _buildPasswordCategory(
    // IconData icon,
    String svgAssetPath,
    String title,
    String count,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              // color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              fit: StackFit.expand, // let children fill the container
              children: [
                // ❶ The SVG now occupies (almost) the full 48×48, 56×56, etc.
                Positioned.fill(
                  left: -80,
                  right: -70,
                  top: -70,
                  bottom: -70,
                  child: SvgPicture.asset(
                    svgAssetPath,
                    fit: BoxFit.contain, // keeps aspect ratio
                    color: color, // works only if the SVG uses currentColor
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  count,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
        ],
      ),
    );
  }
}

class ProgressPainter extends CustomPainter {
  final int safe;
  final int reused;
  final int weak;
  final int compromised;
  final int total;

  ProgressPainter({
    this.safe = 0,
    this.reused = 0,
    this.weak = 0,
    this.compromised = 0,
    this.total = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    final strokeWidth = 12.0;

    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    double startAngle = -1.5708; // -90deg
    double fullCircle = 3.14159 * 2;
    double safeSweep = total > 0 ? (safe / total) * fullCircle : 0;
    double reusedSweep = total > 0 ? (reused / total) * fullCircle : 0;
    double weakSweep = total > 0 ? (weak / total) * fullCircle : 0;
    double compromisedSweep =
        total > 0 ? (compromised / total) * fullCircle : 0;

    // Safe
    if (safeSweep > 0) {
      paint.color = Colors.blue;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        safeSweep,
        false,
        paint,
      );
      startAngle += safeSweep;
    }
    // Reused
    if (reusedSweep > 0) {
      paint.color = Colors.yellow[600]!;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        reusedSweep,
        false,
        paint,
      );
      startAngle += reusedSweep;
    }
    // Weak
    if (weakSweep > 0) {
      paint.color = Colors.red;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        weakSweep,
        false,
        paint,
      );
      startAngle += weakSweep;
    }
    // Compromised
    if (compromisedSweep > 0) {
      paint.color = Colors.teal;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        compromisedSweep,
        false,
        paint,
      );
      startAngle += compromisedSweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}