// lib/screens/password_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database_helper.dart';
import '../models/password_item.dart';

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final dbHelper = DatabaseHelper.instance;
  final Color themeColor = const Color(0xFF6A1B9A); // deep purple
  late Future<List<PasswordItem>> _passwords;

  // Form controllers
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();

  // For toggling visibility in saved cards (handled per-card in widget)
  @override
  void initState() {
    super.initState();
    _loadPasswords();
  }

  void _loadPasswords() {
    setState(() {
      _passwords = dbHelper.getAllPasswords();
    });
  }

  Future<void> _savePassword() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill both fields")),
      );
      return;
    }

    await dbHelper.insertPassword(PasswordItem(
      title: email
          .split('@')
          .first
          .isNotEmpty ? email
          .split('@')
          .first : "Account",
      email: email,
      password: pass,
    ));

    // reset form
    _emailCtrl.clear();
    _passCtrl.clear();
    _loadPasswords();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Saved successfully")),
    );
  }

  Future<void> _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$label copied")),
    );
  }

  Future<void> _deletePassword(int id) async {
    await dbHelper.deletePassword(id);
    _loadPasswords();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme
        .of(context)
        .brightness == Brightness.dark;
    final Color backgroundColor = isDark
        ? const Color(0xFF0B0F13)
        : const Color(0xFFF6F8FB);
    final Color glassBase = isDark ? Colors.black : Colors.white;
    final TextEditingController _titleCtrl = TextEditingController();
    final Color textColor = isDark ? Colors.white : Colors.grey.shade900;
    final Color glassColor = isDark ? Colors.black : Colors.white;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: backgroundColor,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // हेडर में कलर्स पास करें
              _buildGlassHeaderTitle(
                  themeColor, "My Lists", glassColor, textColor),

              const SizedBox(height: 20),
              // --- GLASS FORM CARD ---
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          glassBase.withOpacity(0.50),
                          glassBase.withOpacity(0.18),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.45), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: themeColor.withOpacity(0.14),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Title
                        Text(
                          "Add Credentials",
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.grey.shade900,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // -------------------- WEBSITE BOX --------------------
                        _glassTextField(
                          controller: _titleCtrl,
                          hint: "Website / App Name",
                          keyboardType: TextInputType.text,
                          isPassword: false,
                          onCopy: () =>
                              _copyToClipboard(_titleCtrl.text, "Website"),
                        ),
                        const SizedBox(height: 12),

                        // -------------------- EMAIL BOX ----------------------
                        _glassTextField(
                          controller: _emailCtrl,
                          hint: "Username or Email",
                          keyboardType: TextInputType.emailAddress,
                          isPassword: false,
                          onCopy: () =>
                              _copyToClipboard(_emailCtrl.text, "Username"),
                        ),
                        const SizedBox(height: 12),

                        // -------------------- PASSWORD BOX -------------------
                        _glassTextField(
                          controller: _passCtrl,
                          hint: "Password",
                          keyboardType: TextInputType.visiblePassword,
                          isPassword: true,
                          onCopy: () =>
                              _copyToClipboard(_passCtrl.text, "Password"),
                          onGenerate: () {
                            final generated = _generatePassword();
                            _passCtrl.text = generated;
                            _copyToClipboard(generated, "Generated");
                          },
                        ),

                        const SizedBox(height: 14),

                        // Save button
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () async {
                              final title = _titleCtrl.text.trim();
                              final email = _emailCtrl.text.trim();
                              final password = _passCtrl.text.trim();

                              if (title.isEmpty || email.isEmpty ||
                                  password.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Fill all fields")),
                                );
                                return;
                              }

                              await dbHelper.insertPassword(PasswordItem(
                                title: title,
                                email: email,
                                password: password,
                              ));

                              _titleCtrl.clear();
                              _emailCtrl.clear();
                              _passCtrl.clear();
                              _loadPasswords();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeColor,
                              foregroundColor: isDark ? Colors.black : Colors
                                  .white,
                              // ⭐ KEY FIX
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 8,
                              shadowColor: themeColor.withOpacity(0.35),
                              textStyle: const TextStyle(
                                  fontWeight: FontWeight.w700),
                            ),
                            child: const Text(
                              "Save & New",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // --- Saved passwords header ---
              Row(
                children: [
                  Text(
                    "Saved passwords",
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.grey.shade900,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Spacer(),
                  // optional hint
                  Text(
                    "Tap eye to view",
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // --- Saved list (from DB) ---
              Expanded(
                child: FutureBuilder<List<PasswordItem>>(
                  future: _passwords,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final items = snapshot.data ?? [];

                    if (items.isEmpty) {
                      return Center(
                        child: Text(
                          "No saved credentials yet.",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      padding: const EdgeInsets.only(top: 6, bottom: 16),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _SavedPasswordCard(
                          item: item,
                          themeColor: themeColor,
                          glassBase: glassBase,
                          onDelete: () => _deletePassword(item.id!),
                          onCopyEmail: () =>
                              _copyToClipboard(item.email, "Username"),
                          onCopyPassword: () =>
                              _copyToClipboard(item.password, "Password"),
                          onCopyTitle: () {},
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _generatePassword() {
    // simple but decent password generator (replace or improve as needed)
    const letters = 'abcdefghijklmnopqrstuvwxyz';
    const upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const nums = '0123456789';
    const sym = '!@#\$%^&*()';
    final mix = (letters + upper + nums + sym).split('');
    mix.shuffle();
    return mix.take(12).join();
  }

  // Reusable glass text field with copy + optional generate
  Widget _glassTextField({
    required TextEditingController controller,
    required String hint,
    required TextInputType keyboardType,
    required bool isPassword,
    required VoidCallback onCopy,
    VoidCallback? onGenerate,
  }) {
    final bool isDark = Theme
        .of(context)
        .brightness == Brightness.dark;
    final Color glassBase = isDark ? Colors.black : Colors.white;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: glassBase.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.30)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  obscureText: isPassword ? false : false,
                  // saved input visible until saved card eye toggles
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.grey.shade900,
                      fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),

              // Generate button for password field
              if (onGenerate != null)
                IconButton(
                  icon: Icon(Icons.autorenew, color: Colors.grey.shade700),
                  onPressed: onGenerate,
                  tooltip: "Generate",
                ),

              // Copy button
              IconButton(
                icon: Icon(Icons.copy, color: Colors.blueAccent.shade400),
                onPressed: onCopy,
                tooltip: "Copy",
              ),
            ],
          ),
        ),
      ),
    );
  }

// --- हेडर ---
  Widget _buildGlassHeaderTitle(Color themeColor,
      String title,
      Color glassColor,
      Color textColor,) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: [
                        glassColor.withOpacity(0.45),
                        glassColor.withOpacity(0.15),
                      ],
                    ),
                    border: Border.all(
                      color: glassColor.withOpacity(0.40),
                      width: 1.2,
                    ),
                  ),
                  child: Icon(Icons.arrow_back, size: 22, color: textColor),
                ),
              ),
            ),
          ),

          Expanded(
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          glassColor.withOpacity(0.32),
                          glassColor.withOpacity(0.18),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: glassColor.withOpacity(0.45),
                        width: 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Right dummy for balance
          const SizedBox(width: 46),
        ],
      ),
    );
  }
}
// -------------------------------------
// Saved password card (glassmorphic)
// -------------------------------------
class _SavedPasswordCard extends StatefulWidget {
  final PasswordItem item;
  final Color themeColor;
  final Color glassBase;
  final VoidCallback onDelete;
  final VoidCallback onCopyEmail;
  final VoidCallback onCopyPassword;
  final VoidCallback onCopyTitle;

  const _SavedPasswordCard({
    required this.item,
    required this.themeColor,
    required this.glassBase,
    required this.onDelete,
    required this.onCopyEmail,
    required this.onCopyPassword,
    required this.onCopyTitle,
  });

  @override
  State<_SavedPasswordCard> createState() => _SavedPasswordCardState();
}

class _SavedPasswordCardState extends State<_SavedPasswordCard> {
  bool _isObscured = true;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.glassBase.withOpacity(0.25),
                widget.glassBase.withOpacity(0.10),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.30)),
            boxShadow: [
              BoxShadow(
                color: widget.themeColor.withOpacity(0.12),
                blurRadius: 25,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Row(
            children: [
              // ------------------ LEFT GRADIENT ICON ------------------
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      widget.themeColor,
                      widget.themeColor.withOpacity(0.7),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.themeColor.withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.lock_rounded, color: Colors.white, size: 22),
              ),

              const SizedBox(width: 14),

              // ------------------ CENTER TEXT ------------------
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---------- WEBSITE TITLE + COPY ----------
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.item.title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: widget.themeColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onCopyTitle,
                          child: Icon(Icons.copy_rounded,
                              size: 18, color: Colors.blueAccent.shade400),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // ---------- EMAIL + COPY ----------
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.item.email,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onCopyEmail,
                          child: const Icon(Icons.copy, size: 17, color: Colors.blue),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // ---------- PASSWORD + COPY ----------
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _isObscured ? "••••••••••" : widget.item.password,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() {
                            _isObscured = !_isObscured;
                          }),
                          child: Icon(
                            _isObscured ? Icons.visibility_off : Icons.visibility,
                            size: 20,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: widget.onCopyPassword,
                          child: Icon(Icons.copy_rounded,
                              size: 18, color: Colors.blueAccent.shade400),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ------------------ DELETE BUTTON ------------------
              IconButton(
                icon: Icon(
                  Icons.delete_forever_rounded,
                  color: Colors.redAccent.shade200,
                  size: 22,
                ),
                onPressed: widget.onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
