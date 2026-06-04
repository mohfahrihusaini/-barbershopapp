import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barbershopapp/providers/auth_provider.dart';
import 'package:barbershopapp/presentation/theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _showEditProfileDialog(BuildContext context) {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    final nameController = TextEditingController(text: user?.nama);
    final phoneController = TextEditingController(text: user?.telepon);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ubah Profil"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Nama Lengkap"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: "Nomor Telepon"),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                Navigator.pop(context);
                await Provider.of<AuthProvider>(context, listen: false).updateProfile(
                  nama: nameController.text,
                  telepon: phoneController.text,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Profil berhasil diperbarui"), backgroundColor: AppColors.success),
                  );
                }
              } catch (e) {
                if (mounted) {
                  // Tampilkan error lebih detail
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Gagal update: $e"), 
                      backgroundColor: AppColors.error,
                      duration: const Duration(seconds: 5), // Tampil lebih lama
                      action: SnackBarAction(
                        label: 'Tutup',
                        textColor: Colors.white,
                        onPressed: () {},
                      ),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDark, foregroundColor: Colors.white),
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ubah Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPassController,
              decoration: const InputDecoration(labelText: "Password Lama"),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPassController,
              decoration: const InputDecoration(labelText: "Password Baru"),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPassController.text.length < 8) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Password minimal 8 karakter"), backgroundColor: AppColors.warning),
                );
                return;
              }
              try {
                Navigator.pop(context);
                await Provider.of<AuthProvider>(context, listen: false).updatePassword(
                  newPassword: newPassController.text,
                  oldPassword: oldPassController.text,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Password berhasil diubah"), backgroundColor: AppColors.success),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Gagal ubah password: $e"), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDark, foregroundColor: Colors.white),
            child: const Text("Ubah"),
          ),
        ],
      ),
    );
  }

  void _showChangeEmailDialog(BuildContext context) {
    final emailController = TextEditingController();
    final passController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ubah Email"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email Baru"),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passController,
              decoration: const InputDecoration(labelText: "Konfirmasi Password"),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                Navigator.pop(context);
                await Provider.of<AuthProvider>(context, listen: false).updateEmail(
                  email: emailController.text,
                  password: passController.text,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Email berhasil diubah"), backgroundColor: AppColors.success),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Gagal ubah email: $e"), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDark, foregroundColor: Colors.white),
            child: const Text("Ubah"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil Saya"),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.gold,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 50,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.nama ?? "Nama Pengguna",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? "email@example.com",
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (user?.telepon != null && user!.telepon.isNotEmpty)
                    Text(
                      user.telepon,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline, color: AppColors.primaryDark),
                    title: const Text("Ubah Profil (Nama & HP)"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showEditProfileDialog(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.email_outlined, color: AppColors.primaryDark),
                    title: const Text("Ubah Email"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showChangeEmailDialog(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.lock_outline, color: AppColors.primaryDark),
                    title: const Text("Ubah Password"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showChangePasswordDialog(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}