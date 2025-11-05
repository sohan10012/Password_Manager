// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:password_manager/constants/app_constants.dart'; 
// import 'package:password_manager/helper/encryption_helper.dart';
// import 'package:password_manager/screens/add_new_password_screen.dart';
// import 'package:password_manager/screens/password_health.dart';
// import 'package:password_manager/screens/profile_screen.dart';
// import 'package:password_manager/theme/theme.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:local_auth/local_auth.dart';

// class PasswordDetailsScreen extends StatefulWidget {
//   final String? initialCategory;
//   const PasswordDetailsScreen({super.key, this.initialCategory});

//   @override
//   State<PasswordDetailsScreen> createState() => _PasswordDetailsScreenState();
// }

// class _PasswordDetailsScreenState extends State<PasswordDetailsScreen> {
//   final ValueNotifier<String> _searchQuery = ValueNotifier<String>("");
//   final ValueNotifier<String> _selectedCategory = ValueNotifier<String>("All");
//   // Update tabs to include Social, Apps, Card
//   final List<String> tabs = [
//     "All",
//     // "Social",
//     // "Apps",
//     // "Card",
//     "Browser",
//     "Cloud",
//     "Application",
//     "Payment",
//   ];
//   final databaseRef = FirebaseDatabase.instance.ref();
//   bool _isLoading = false;
//   final List<Map<String, String>> _allItems = [];
//   List<Map<String, String>> _filteredItems = [];
//   late List<bool> _isPasswordVisible;
//   final LocalAuthentication auth = LocalAuthentication();

//   @override
//   void initState() {
//     super.initState();
//     // Set initial category if provided and present in tabs
//     if (widget.initialCategory != null &&
//         tabs.contains(widget.initialCategory)) {
//       _selectedCategory.value = widget.initialCategory!;
//     }
//     _searchQuery.addListener(_filterList);
//     _loadPasswords();
//   }

//   Future<void> _loadPasswords() async {
//     setState(() => _isLoading = true);

//     final uid = FirebaseAuth.instance.currentUser?.uid;
//     if (uid == null) {
//       setState(() => _isLoading = false);
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('User not logged in')));
//       return;
//     }

//     try {
//       final snapshot = await databaseRef.child('users/$uid/passwords').get();

//       if (snapshot.exists) {
//         List<Map<String, String>> tempList = [];
//         Map<dynamic, dynamic> values = snapshot.value as Map;

//         for (var entry in values.entries) {
//           final key = entry.key;
//           final value = entry.value as Map;
//           try {
//             final decryptedSite = await EncryptionHelper.decrypt(
//               value['site'] ?? '',
//               value['site_iv'] ?? '',
//             );
//             final decryptedUsername = await EncryptionHelper.decrypt(
//               value['username'] ?? '',
//               value['username_iv'] ?? '',
//             );
//             final decryptedPassword = await EncryptionHelper.decrypt(
//               value['password'] ?? '',
//               value['password_iv'] ?? '',
//             );
//             final decryptedNote = await EncryptionHelper.decrypt(
//               value['note'] ?? '',
//               value['note_iv'] ?? '',
//             );
//             // Use category from DB, decrypt if needed
//             String? decryptedCategory;
//             if (value.containsKey('category') &&
//                 value.containsKey('category_iv')) {
//               decryptedCategory = await EncryptionHelper.decrypt(
//                 value['category'] ?? '',
//                 value['category_iv'] ?? '',
//               );
//             } else if (value.containsKey('category')) {
//               decryptedCategory = value['category'];
//             }

//             // Decrypt cvv and expiry if present (for Payment)
//             String? decryptedCvv;
//             String? decryptedExpiry;
//             if (value.containsKey('cvv') && value.containsKey('cvv_iv')) {
//               decryptedCvv = await EncryptionHelper.decrypt(
//                 value['cvv'] ?? '',
//                 value['cvv_iv'] ?? '',
//               );
//             }
//             if (value.containsKey('expiry') && value.containsKey('expiry_iv')) {
//               decryptedExpiry = await EncryptionHelper.decrypt(
//                 value['expiry'] ?? '',
//                 value['expiry_iv'] ?? '',
//               );
//             }

//             tempList.add({
//               'id': key,
//               'title': _getDomainName(decryptedSite),
//               'site': decryptedSite,
//               'email': decryptedUsername,
//               'password': decryptedPassword,
//               'note': decryptedNote,
//               'category': decryptedCategory ?? 'Browser',
//               'cvv': decryptedCvv ?? '', // <-- Ensure these are included
//               'expiry': decryptedExpiry ?? '', // <-- Ensure these are included
//             });
//           } catch (e) {
//             print('Decryption error for entry $key: $e');
//             continue;
//           }
//         }

//         setState(() {
//           _allItems.clear();
//           _allItems.addAll(tempList);
//           _filteredItems = List.from(_allItems);
//           _isPasswordVisible = List.generate(_allItems.length, (_) => false);
//           // Filter by initial category if set and not "All"
//           if (widget.initialCategory != null &&
//               widget.initialCategory != "All" &&
//               tabs.contains(widget.initialCategory)) {
//             _selectedCategory.value = widget.initialCategory!;
//             _filterList();
//           }
//           _isLoading = false;
//         });
//       } else {
//         setState(() => _isLoading = false);
//       }
//     } catch (e) {
//       setState(() => _isLoading = false);
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error loading passwords: $e')));
//     }
//   }

//   String _getDomainName(String url) {
//     try {
//       Uri uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
//       String host = uri.host;
//       if (host.startsWith('www.')) {
//         host = host.substring(4);
//       }
//       List<String> parts = host.split('.');
//       if (parts.length >= 2) {
//         return parts[parts.length - 2];
//       }
//       return host;
//     } catch (e) {
//       return url;
//     }
//   }

//   void _filterList() {
//     final query = _searchQuery.value.toLowerCase();
//     final selectedCategory = _selectedCategory.value;

//     setState(() {
//       _filteredItems =
//           _allItems.where((item) {
//             final matchesQuery =
//                 item['title']!.toLowerCase().contains(query) ||
//                 item['email']!.toLowerCase().contains(query);
//             final matchesCategory =
//                 selectedCategory == 'All' ||
//                 (item['category'] ?? 'Social') == selectedCategory;
//             return matchesQuery && matchesCategory;
//           }).toList();
//     });
//   }

//   // ✅ Fixed: Removed deprecated AuthenticationOptions
//   Future<bool> _authenticateAction(String reason) async {
//     try {
//       // Check if device supports authentication
//       final bool isDeviceSupported = await auth.isDeviceSupported();
//       if (!isDeviceSupported) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Biometric authentication not supported')),
//         );
//         return false;
//       }

//       // Use modern authentication without deprecated options
//       return await auth.authenticate(
//         localizedReason: reason,
//         biometricOnly: false, // Allows fallback to PIN/pattern
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Authentication failed: $e')));
//       return false;
//     }
//   }

//   void _toggleVisibility(int index) async {
//     bool isAuthenticated = await _authenticateAction(
//       'Please authenticate to view this password',
//     );
//     if (!isAuthenticated) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Authentication canceled')));
//       return;
//     }
//     setState(() {
//       _isPasswordVisible[index] = !_isPasswordVisible[index];
//     });
//   }

//   void _copyPassword(String password) async {
//     bool isAuthenticated = await _authenticateAction(
//       'Please authenticate to copy this password',
//     );
//     if (!isAuthenticated) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Authentication canceled')));
//       return;
//     }
//     Clipboard.setData(ClipboardData(text: password));
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Password copied to clipboard')),
//     );
//   }

//   void _editPassword(int index) async {
//     bool isAuthenticated = await _authenticateAction(
//       'Please authenticate to edit this password',
//     );
//     if (!isAuthenticated) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Authentication canceled')));
//       return;
//     }
//     final item = _allItems[index];
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder:
//             (_) => AddNewPasswordScreen(
//               id: item['id'],
//               site: item['site'],
//               username: item['email'],
//               password: item['password'],
//               note: item['note'],
//               category: item['category'],
//               cvv: item['cvv'], // <-- Pass cvv
//               expiry: item['expiry'], // <-- Pass expiry
//             ),
//       ),
//     ).then((_) => _loadPasswords());
//   }

//   // ✅ Fixed: Updated _deletePassword to use centralized authentication
//   Future<void> _deletePassword(int index) async {
//     final item = _allItems[index];
//     final userId = FirebaseAuth.instance.currentUser!.uid;
//     final dbRef = FirebaseDatabase.instance.ref(
//       'users/$userId/passwords/${item['id']}',
//     );

//     bool isAuthenticated = false;

//     try {
//       isAuthenticated = await _authenticateAction(
//         'Please authenticate to delete this password',
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Authentication failed: $e')));
//       return;
//     }

//     if (!isAuthenticated) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Authentication canceled')));
//       return;
//     }

//     // ✅ Show delete confirmation dialog after successful auth
//     showDialog(
//       context: context,
//       builder:
//           (context) => AlertDialog(
//             title: const Text('Delete Password'),
//             content: Text(
//               'Are you sure you want to delete the password for ${item['title']}?',
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('Cancel'),
//               ),
//               ElevatedButton(
//                 onPressed: () async {
//                   try {
//                     await dbRef.remove();
//                     setState(() {
//                       _allItems.removeAt(index);
//                       _filteredItems = List.from(_allItems);
//                       _isPasswordVisible.removeAt(index);
//                     });
//                     Navigator.pop(context);
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(content: Text('Password deleted')),
//                     );
//                   } catch (e) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text('Error deleting password: $e')),
//                     );
//                   }
//                 },
//                 child: const Text('Delete'),
//               ),
//             ],
//           ),
//     );
//   }

//   @override
//   void dispose() {
//     _searchQuery.dispose();
//     _selectedCategory.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.backgroundColor,
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (_) => const AddNewPasswordScreen()),
//           ).then((_) => _loadPasswords());
//         },
//         backgroundColor: AppColors.primaryColor,
//         child: const Icon(Icons.add, color: Colors.white),
//         elevation: 8,
//         // shape: const CircleBorder(),
//       ),
//       floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
//       appBar: AppBar(
//         backgroundColor: AppColors.primaryColor,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
//           onPressed: () => Navigator.pop(context),
//         ),
//         titleSpacing: 0, // Optional: to reduce spacing before title
//         // title: Row(
//         //   children: [
//         //     Expanded(child: SearchBar(searchQueryNotifier: _searchQuery)),
//         //   ],
//         // ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.shield, color: AppColors.whiteColor),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => const PasswordHealth()),
//               ).then((_) => _loadPasswords());
//             },
//           ),
//           const SizedBox(width: AppConstants.spacing8),
//           IconButton(
//             onPressed: () {
//               Navigator.of(context).push(
//                 MaterialPageRoute(builder: (context) => const ProfileScreen()),
//               );
//             },
//             icon: const Icon(Icons.person, color: Colors.white),
//             iconSize: 24,
//           ),
//           const SizedBox(width: AppConstants.spacing8),
//         ],
//       ),

//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   // IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back), color: AppColors.primaryColor),
//                   const SizedBox(width: AppConstants.spacing4),
//                   Expanded(child: SearchBar(searchQueryNotifier: _searchQuery)),
//                   const SizedBox(width: AppConstants.spacing4),
//                   // IconButton(
//                   //   icon: const Icon(Icons.shield, color: AppColors.primaryColor),
//                   //   onPressed: () {
//                   //     Navigator.push(
//                   //       context,
//                   //       MaterialPageRoute(
//                   //         builder: (_) => const PasswordHealth(),
//                   //       ),
//                   //     ).then((_) => _loadPasswords());
//                   //   },
//                   // ),
//                   // const Icon(Icons.settings, color: AppColors.secondaryColor),
//                 ],
//               ),
//               const SizedBox(height: 24),
//               Row(
//                 children: const [
//                   Text(
//                     "Passwords",
//                     style: TextStyle(
//                       color: AppColors.primaryColor,
//                       fontSize: 28,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   // Icon(
//                   //   Icons.keyboard_arrow_down,
//                   //   color: AppColors.primaryColor,
//                   // ),
//                 ],
//               ),
//               const SizedBox(height: 16),
//               ValueListenableBuilder<String>(
//                 valueListenable: _selectedCategory,
//                 builder: (_, selected, __) {
//                   return SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: Row(
//                       children: List.generate(tabs.length, (index) {
//                         final isSelected = tabs[index] == selected;
//                         return Padding(
//                           padding: const EdgeInsets.only(right: 16.0),
//                           child: GestureDetector(
//                             onTap: () {
//                               _selectedCategory.value = tabs[index];
//                               _filterList();
//                             },
//                             child: Text(
//                               tabs[index],
//                               style: TextStyle(
//                                 fontSize: 20,
//                                 color:
//                                     isSelected
//                                         ? AppColors.secondaryColor
//                                         : AppColors.primaryColor,
//                                 fontWeight:
//                                     isSelected
//                                         ? FontWeight.bold
//                                         : FontWeight.normal,
//                                 decoration:
//                                     isSelected
//                                         ? TextDecoration.underline
//                                         : TextDecoration.none,
//                               ),
//                             ),
//                           ),
//                         );
//                       }),
//                     ),
//                   );
//                 },
//               ),
//               const SizedBox(height: 24),
//               Expanded(
//                 child:
//                     _isLoading
//                         ? const Center(child: CircularProgressIndicator())
//                         : _filteredItems.isEmpty
//                         ? const Center(child: Text('No passwords found'))
//                         : ListView.separated(
//                           itemCount: _filteredItems.length,
//                           separatorBuilder:
//                               (_, __) => const SizedBox(height: 12),
//                           itemBuilder: (context, index) {
//                             final item = _filteredItems[index];
//                             final originalIndex = _allItems.indexOf(item);
//                             final passwordVisible =
//                                 _isPasswordVisible[originalIndex];

//                             return RecentItem(
//                               title: item['title']!,
//                               email: item['email']!,
//                               password: item['password']!,
//                               passwordVisible: passwordVisible,
//                               onToggleVisibility:
//                                   () => _toggleVisibility(originalIndex),
//                               onCopyPassword:
//                                   () => _copyPassword(item['password']!),
//                               onEdit: () => _editPassword(originalIndex),
//                               onDelete: () => _deletePassword(originalIndex),
//                               // ✅ Fixed: Removed auth parameter and AuthenticationOptions
//                               onTap: () async {
//                                 bool isAuthenticated = await _authenticateAction(
//                                   'Please authenticate to view details',
//                                 );
//                                 if (!isAuthenticated) {
//                                   ScaffoldMessenger.of(context).showSnackBar(
//                                     const SnackBar(
//                                       content: Text('Authentication canceled'),
//                                     ),
//                                   );
//                                   return;
//                                 }
//                                 showDialog(
//                                   context: context,
//                                   builder: (context) {
//                                     final labelStyle = TextStyle(
//                                       fontWeight: FontWeight.bold,
//                                       fontSize:
//                                           Theme.of(
//                                             context,
//                                           ).textTheme.bodyMedium!.fontSize! +
//                                           1,
//                                       color: Colors.black,
//                                     );
//                                     final valueStyle = TextStyle(
//                                       fontWeight: FontWeight.normal,
//                                       fontSize:
//                                           Theme.of(
//                                             context,
//                                           ).textTheme.bodyMedium!.fontSize,
//                                       color: Colors.black87,
//                                     );
//                                     final category = (item['category'] ?? '');
//                                     String mainLabel;
//                                     String secondLabel;
//                                     String passwordLabel;
//                                     if (category == 'Payment') {
//                                       mainLabel = 'Card Number';
//                                       secondLabel = 'Card Holder';
//                                       passwordLabel = 'PIN';
//                                     } else if (category == 'Application') {
//                                       mainLabel = 'Application';
//                                       secondLabel = 'Application ID';
//                                       passwordLabel = 'Password';
//                                     } else if (category == 'Cloud') {
//                                       mainLabel = 'Cloud';
//                                       secondLabel = 'Cloud ID';
//                                       passwordLabel = 'Password';
//                                     } else {
//                                       mainLabel = 'Site';
//                                       secondLabel = 'Username';
//                                       passwordLabel = 'Password';
//                                     }
//                                     return AlertDialog(
//                                       title: Text(item['title'] ?? 'Details'),
//                                       content: SingleChildScrollView(
//                                         child: Column(
//                                           crossAxisAlignment:
//                                               CrossAxisAlignment.start,
//                                           children: [
//                                             Text(mainLabel, style: labelStyle),
//                                             Text(
//                                               item['site'] ?? '',
//                                               style: valueStyle,
//                                             ),
//                                             const SizedBox(height: 8),
//                                             Text(
//                                               secondLabel,
//                                               style: labelStyle,
//                                             ),
//                                             Text(
//                                               item['email'] ?? '',
//                                               style: valueStyle,
//                                             ),
//                                             const SizedBox(height: 8),
//                                             Text(
//                                               passwordLabel,
//                                               style: labelStyle,
//                                             ),
//                                             Text(
//                                               item['password'] ?? '',
//                                               style: valueStyle,
//                                             ),
//                                             if ((item['cvv'] ?? '')
//                                                 .isNotEmpty) ...[
//                                               const SizedBox(height: 8),
//                                               Text('CVV', style: labelStyle),
//                                               Text(
//                                                 item['cvv']!,
//                                                 style: valueStyle,
//                                               ),
//                                             ],
//                                             if ((item['expiry'] ?? '')
//                                                 .isNotEmpty) ...[
//                                               const SizedBox(height: 8),
//                                               Text('Expiry', style: labelStyle),
//                                               Text(
//                                                 item['expiry']!,
//                                                 style: valueStyle,
//                                               ),
//                                             ],
//                                             const SizedBox(height: 8),
//                                             Text('Note', style: labelStyle),
//                                             Text(
//                                               item['note'] ?? '',
//                                               style: valueStyle,
//                                             ),
//                                             const SizedBox(height: 8),
//                                             Text('Category', style: labelStyle),
//                                             Text(
//                                               item['category'] ?? '',
//                                               style: valueStyle,
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                       actions: [
//                                         TextButton(
//                                           onPressed:
//                                               () => Navigator.pop(context),
//                                           child: const Text('Close'),
//                                         ),
//                                       ],
//                                     );
//                                   },
//                                 );
//                               },
//                             );
//                           },
//                         ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class SearchBar extends StatelessWidget {
//   final ValueNotifier<String> searchQueryNotifier;

//   const SearchBar({super.key, required this.searchQueryNotifier});

//   @override
//   Widget build(BuildContext context) {
//     return TextField(
//       onChanged: (value) => searchQueryNotifier.value = value,
//       style: const TextStyle(color: AppColors.primaryColor),
//       decoration: InputDecoration(
//         hintText: 'Search',
//         hintStyle: TextStyle(color: AppColors.primaryColor.withOpacity(0.5)),
//         filled: true,
//         fillColor: AppColors.backgroundColor,
//         prefixIcon: const Icon(Icons.search, color: AppColors.primaryColor),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: const BorderSide(color: AppColors.primaryColor),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: const BorderSide(color: AppColors.primaryColor),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: const BorderSide(color: AppColors.primaryColor),
//         ),
//       ),
//     );
//   }
// }

// class RecentItem extends StatelessWidget {
//   final String title;
//   final String email;
//   final String password;
//   final bool passwordVisible;
//   final VoidCallback onToggleVisibility;
//   final VoidCallback onCopyPassword;
//   final VoidCallback onEdit;
//   // final VoidCallback onShare;
//   final VoidCallback onDelete;
//   final VoidCallback onTap; // <-- Keep this

//   const RecentItem({
//     super.key,
//     required this.title,
//     required this.email,
//     required this.password,
//     required this.passwordVisible,
//     required this.onToggleVisibility,
//     required this.onCopyPassword,
//     required this.onEdit,
//     required this.onDelete,
//     required this.onTap, // <-- Keep this
//   });

//   // ✅ Fixed: Removed auth parameter and AuthenticationOptions
//   // Authentication is now handled by parent widget methods

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: ListTile(
//         contentPadding: const EdgeInsets.symmetric(
//           horizontal: 16,
//           vertical: 12,
//         ),
//         leading: CircleAvatar(
//           backgroundColor: AppColors.primaryColor,
//           child: Text(
//             title.isNotEmpty ? title[0].toUpperCase() : '?',
//             style: const TextStyle(color: Colors.white),
//           ),
//         ),
//         title: Text(
//           title.isNotEmpty ? title : 'Untitled',
//           style: const TextStyle(color: AppColors.primaryColor),
//         ),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               email.isNotEmpty ? email : 'No email',
//               style: const TextStyle(color: AppColors.primaryColor),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               passwordVisible ? password : '●●●●●●●●',
//               style: const TextStyle(color: AppColors.primaryColor),
//             ),
//           ],
//         ),
//         trailing: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             IconButton(
//               icon: Icon(
//                 passwordVisible ? Icons.visibility_off : Icons.visibility,
//                 color: AppColors.secondaryColor,
//               ),
//               onPressed: onToggleVisibility, // Now handled by parent
//             ),
//             IconButton(
//               icon: const Icon(Icons.copy, color: AppColors.secondaryColor),
//               onPressed: onCopyPassword, // Now handled by parent
//             ),
//             PopupMenuButton<String>(
//               icon: const Icon(
//                 Icons.more_vert,
//                 color: AppColors.secondaryColor,
//               ),
//               onSelected: (value) {
//                 switch (value) {
//                   case 'edit':
//                     onEdit(); // Now handled by parent
//                     break;
//                   case 'delete':
//                     onDelete();
//                     break;
//                   // case 'password Generator':
//                   //   Navigator.push(
//                   //     context,
//                   //     MaterialPageRoute(
//                   //       builder: (_) => const PasswordGeneratorScreen(),
//                   //     ),
//                   //   );
//                   //   break;
//                 }
//               },
//               itemBuilder:
//                   (context) => [
//                     const PopupMenuItem(value: 'edit', child: Text('Edit')),
//                     // const PopupMenuItem(
//                     //   value: 'password Generator',
//                     //   child: Text('Password Generator'),
//                     // ),
//                     // const PopupMenuItem(value: 'share', child: Text('Share')),
//                     const PopupMenuItem(value: 'delete', child: Text('Delete')),
//                   ],
//             ),
//           ],
//         ),
//         onTap: onTap,
//       ),
//     );
//   }
// }