import 'package:flutter/material.dart';

import '../services/users/user_service.dart';
import '../widgets/smartcare_bottom_nav.dart';
import '../widgets/smartcare_dashboard_header.dart';

const List<String> _roles = ['patient', 'doctor', 'secretary'];
const List<String> _genders = ['Male', 'Female', 'Other'];

Color _roleBackgroundColor(String role) {
  switch (role) {
    case 'doctor':
      return const Color(0xFFE3F0FF);
    case 'secretary':
      return const Color(0xFFF3E8FF);
    default:
      return const Color(0xFFE0F4E1);
  }
}

Color _roleTextColor(String role) {
  switch (role) {
    case 'doctor':
      return const Color(0xFF1F5AA2);
    case 'secretary':
      return const Color(0xFF7C3AED);
    default:
      return const Color(0xFF16751F);
  }
}

InputDecoration _fieldDecoration(String label) {
  return InputDecoration(
    labelText: label,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
  );
}

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(() => setState(() {}));
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final users = await UserService.getAllUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _users;
    return _users.where((u) {
      final name = (u['full_name'] as String).toLowerCase();
      final email = (u['email'] as String).toLowerCase();
      final phone = (u['contact_number'] as String).toLowerCase();
      return name.contains(query) ||
          email.contains(query) ||
          phone.contains(query);
    }).toList();
  }

  void _editUser(Map<String, dynamic> user) {
    final firstNameController = TextEditingController(
      text: user['first_name'] as String,
    );
    final middleNameController = TextEditingController(
      text: user['middle_name'] as String,
    );
    final lastNameController = TextEditingController(
      text: user['last_name'] as String,
    );
    final emailController = TextEditingController(
      text: user['email'] as String,
    );
    final phoneController = TextEditingController(
      text: user['contact_number'] as String,
    );
    final addressController = TextEditingController(
      text: user['address'] as String,
    );
    final emergencyController = TextEditingController(
      text: user['emergency_contact'] as String,
    );
    final passwordController = TextEditingController();
    String? selectedGender = (user['gender'] as String).isEmpty
        ? null
        : user['gender'] as String;
    String selectedRole = user['role'] as String;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setStateDialog) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            width: MediaQuery.of(dialogContext).size.width * 0.9,
            constraints: const BoxConstraints(maxWidth: 600),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Edit User',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF006837),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: firstNameController,
                      decoration: _fieldDecoration('First Name'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: middleNameController,
                      decoration: _fieldDecoration('Middle Name'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: lastNameController,
                      decoration: _fieldDecoration('Last Name'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailController,
                      decoration: _fieldDecoration('Email'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: phoneController,
                      decoration: _fieldDecoration('Contact Number'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedGender,
                      decoration: _fieldDecoration('Gender'),
                      items: _genders
                          .map(
                            (g) => DropdownMenuItem(value: g, child: Text(g)),
                          )
                          .toList(),
                      onChanged: (value) {
                        setStateDialog(() => selectedGender = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: addressController,
                      decoration: _fieldDecoration('Address'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emergencyController,
                      decoration: _fieldDecoration('Emergency Number'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: _fieldDecoration('Role'),
                      items: _roles
                          .map(
                            (r) => DropdownMenuItem(
                              value: r,
                              child: Text(r[0].toUpperCase() + r.substring(1)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setStateDialog(
                          () => selectedRole = value ?? selectedRole,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: _fieldDecoration(
                        'Password (leave blank to keep current)',
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () => Navigator.pop(dialogContext),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3D3D3D),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  setStateDialog(() => isSaving = true);
                                  try {
                                    await UserService.updateUser(
                                      userId: user['user_id'] as int,
                                      email: emailController.text.trim(),
                                      firstName: firstNameController.text
                                          .trim(),
                                      middleName: middleNameController.text
                                          .trim(),
                                      lastName: lastNameController.text.trim(),
                                      contactNumber: phoneController.text
                                          .trim(),
                                      gender: selectedGender ?? '',
                                      address: addressController.text.trim(),
                                      emergencyContact: emergencyController.text
                                          .trim(),
                                      role: selectedRole,
                                      password: passwordController.text,
                                    );
                                    if (!dialogContext.mounted) return;
                                    Navigator.pop(dialogContext);
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('User updated.'),
                                      ),
                                    );
                                    await _load();
                                  } catch (e) {
                                    setStateDialog(() => isSaving = false);
                                    if (!dialogContext.mounted) return;
                                    ScaffoldMessenger.of(
                                      dialogContext,
                                    ).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          e.toString().replaceFirst(
                                            'Exception: ',
                                            '',
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF006837),
                            foregroundColor: Colors.white,
                          ),
                          child: Text(isSaving ? 'Saving...' : 'Update'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _deleteUser(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text('Are you sure you want to delete ${user['full_name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await UserService.deleteUser(user['user_id'] as int);
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('User deleted.')));
                await _load();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString().replaceFirst('Exception: ', '')),
                  ),
                );
              }
            },
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBF5),
      bottomNavigationBar: const SmartCareBottomNav(
        currentItem: SmartCareBottomItem.profile,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SmartCareDashboardHeader(
                title: "User Management",
                subtitle: "Manage user accounts and roles.",
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 26),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search by name, email, or phone...',
                            hintStyle: const TextStyle(
                              color: Color(0xFFBBBBBB),
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Color(0xFF6E8D73),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE0E0E0),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE0E0E0),
                              ),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFFAFAFA),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF006837),
                              ),
                            ),
                          )
                        else if (_error != null)
                          Column(
                            children: [
                              Text(
                                _error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                              TextButton(
                                onPressed: _load,
                                child: const Text('Retry'),
                              ),
                            ],
                          )
                        else if (_filteredUsers.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 48,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No users found',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE3EFE1),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0x0A000000),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: WidgetStateColor.resolveWith(
                                  (states) => const Color(0xFFF6FBF5),
                                ),
                                headingRowHeight: 56,
                                dataRowMinHeight: 60,
                                dataRowMaxHeight: 72,
                                columnSpacing: 20,
                                headingTextStyle: const TextStyle(
                                  color: Color(0xFF1A3320),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                                columns: const [
                                  DataColumn(label: Text('USER ID')),
                                  DataColumn(label: Text('EMAIL')),
                                  DataColumn(label: Text('FULL NAME')),
                                  DataColumn(label: Text('CONTACT NUMBER')),
                                  DataColumn(label: Text('GENDER')),
                                  DataColumn(label: Text('ADDRESS')),
                                  DataColumn(label: Text('EMERGENCY NUMBER')),
                                  DataColumn(label: Text('ROLE')),
                                  DataColumn(label: Text('ACTION')),
                                ],
                                rows: _filteredUsers.map((user) {
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Text(
                                          "${user['user_id']}",
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          user['email'] as String,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          user['full_name'] as String,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          user['contact_number'] as String,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          user['gender'] as String,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 160,
                                          child: Text(
                                            user['address'] as String,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          user['emergency_contact'] as String,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _roleBackgroundColor(
                                              user['role'] as String,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            (user['role'] as String)
                                                .toUpperCase(),
                                            style: TextStyle(
                                              color: _roleTextColor(
                                                user['role'] as String,
                                              ),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF006B2D),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  onTap: () => _editUser(user),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  child: const Padding(
                                                    padding: EdgeInsets.all(6),
                                                    child: Icon(
                                                      Icons.edit,
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFC41C3B),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  onTap: () =>
                                                      _deleteUser(user),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  child: const Padding(
                                                    padding: EdgeInsets.all(6),
                                                    child: Icon(
                                                      Icons.delete,
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                      ],
                    ),
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
