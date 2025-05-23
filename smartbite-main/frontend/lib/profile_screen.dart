import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Replace this with your real user fetching logic
  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool isEditing = false;
  final _formKey = GlobalKey<FormState>();
  // Editable fields
  late TextEditingController _usernameController;
  late TextEditingController _heightController;
  late TextEditingController _dobController;
  String _sex = 'Male';
  final List<String> _sexOptions = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    setState(() { isLoading = true; });
    try {
      final data = await UserService.getProfile();
      setState(() {
        userData = data;
        _usernameController = TextEditingController(text: userData!["username"] ?? "");
        _heightController = TextEditingController(text: userData!["height"] ?? "");
        _dobController = TextEditingController(text: userData!["dob"] ?? "");
        _sex = userData!["sex"] ?? "Male";
        if (!_sexOptions.contains(_sex)) {
          _sex = _sexOptions[0];
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() { isLoading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch profile: $e')),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    setState(() { isLoading = true; });
    try {
      final updated = await UserService.updateProfile({
        ...userData!,
        'username': _usernameController.text,
        'height': _heightController.text,
        'sex': _sex,
        'dob': _dobController.text,
      });
      setState(() {
        userData = updated;
        isEditing = false;
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!')),
        );
      }
    } catch (e) {
      setState(() { isLoading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!isLoading && !isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.black),
              onPressed: () {
                setState(() { isEditing = true; });
              },
            ),
        ],
      ),
      body: isLoading || userData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    // Profile photo and username
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: Colors.black,
                      child: (userData?["profilePhoto"] ?? null) == null
                          ? const Icon(Icons.person, color: Colors.white, size: 60)
                          : ClipOval(
                              child: Image.network(userData?["profilePhoto"] ?? '', width: 80, height: 80, fit: BoxFit.cover),
                            ),
                    ),
                    const SizedBox(height: 10),
                    isEditing
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Center(
                              child: TextFormField(
                                controller: _usernameController,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  labelText: 'User Name',
                                  labelStyle: GoogleFonts.poppins(color: Colors.black54),
                                ),
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 20,
                                  color: Colors.black,
                                ),
                                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                              ),
                            ),
                          )
                        : Text(
                            userData?["username"] ?? '',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 20,
                              color: const Color(0xFF22A045),
                            ),
                          ),
                    const SizedBox(height: 24),
                    // Info card
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 18),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          isEditing
                              ? _profileEditRow('Height', _heightController)
                              : _profileRow('Height', (userData?["height"] ?? '').isEmpty ? 'Not set' : userData?["height"], highlight: true),
                          _divider(),
                          isEditing
                              ? _profileDropdownRow('Sex', _sex, (val) => setState(() => _sex = val!), _sexOptions)
                              : _profileRow('Sex', (userData?["sex"] ?? '').isEmpty ? 'Not set' : userData?["sex"], highlight: true),
                          _divider(),
                          isEditing
                              ? _profileDateRow('Date of Birth', _dobController)
                              : _profileRow('Date of Birth', (userData?["dob"] ?? '').isEmpty ? 'Not set' : userData?["dob"], highlight: true),
                          _divider(),
                          _profileRow('Email', userData?["email"] ?? '', highlight: true),
                        ],
                      ),
                    ),
                    if (isEditing)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: () {
                                setState(() { isEditing = false; });
                              },
                              child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.white)),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF22A045),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  _updateProfile();
                                }
                              },
                              child: Text('Save', style: GoogleFonts.poppins(color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _divider() => const Divider(color: Colors.white24, height: 0, thickness: 1);

  Widget _profileRow(String label, String value, {bool highlight = false, IconData? icon, bool isPhoto = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
          isPhoto
              ? CircleAvatar(radius: 20, backgroundColor: const Color(0xFF22A045), child: const Icon(Icons.person, color: Colors.white, size: 24))
              : Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: highlight ? const Color(0xFF22A045) : Colors.white,
                    fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 16,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _profileEditRow(String label, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 18),
      child: TextFormField(
        controller: controller,
        style: GoogleFonts.poppins(color: const Color(0xFF22A045), fontWeight: FontWeight.w600, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.white70),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF22A045))),
        ),
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _profileDropdownRow(String label, String value, void Function(String?) onChanged, List<String> options) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
          DropdownButton<String>(
            value: value,
            dropdownColor: Colors.black,
            style: GoogleFonts.poppins(color: const Color(0xFF22A045), fontWeight: FontWeight.w600, fontSize: 16),
            underline: Container(height: 1, color: Colors.white24),
            items: options.map((opt) => DropdownMenuItem(
              value: opt,
              child: Text(opt),
            )).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _profileDateRow(String label, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 18),
      child: TextFormField(
        controller: controller,
        style: GoogleFonts.poppins(color: const Color(0xFF22A045), fontWeight: FontWeight.w600, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          hintText: 'MM-DD-YYYY',
          labelStyle: GoogleFonts.poppins(color: Colors.white70),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF22A045))),
        ),
        readOnly: true,
        onTap: () async {
          DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime.tryParse(controller.text) ?? DateTime(2000, 1, 1),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (picked != null) {
            controller.text = "${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}-${picked.year}";
          }
        },
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      ),
    );
  }
} 