import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../utils/themes/app_colors.dart';
import '../services/image_upload_service.dart';
import '../components/buttons/gradient_button.dart';
import '../components/inputs/custom_text_field.dart';
import '../components/avatars/custom_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imageUploadService = ImageUploadService();
  final _picker = ImagePicker();

  bool _isUploadingImage = false;
  String? _newAvatarUrl;
  String? _newFavoriteTeamLogo;

  late TextEditingController _displayNameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late TextEditingController _favoriteTeamController;

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<AuthProvider>(context, listen: false).userProfile;
    _displayNameController = TextEditingController(text: profile?.displayName);
    _usernameController = TextEditingController(text: profile?.username);
    _bioController = TextEditingController(text: profile?.bio);
    _favoriteTeamController = TextEditingController(text: profile?.favoriteTeam);
    _newFavoriteTeamLogo = profile?.favoriteTeamLogo;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _favoriteTeamController.dispose();
    super.dispose();
  }

  Future<void> _selectTeam() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;

    final result = await context.push<dynamic>('/team-selection', extra: {
      'userId': user.uid,
      'subscriptionType': 'FREE',
      'currentFollowCount': 0,
      'countryName': null,
    });

    if (result != null) {
      setState(() {
        _favoriteTeamController.text = (result as dynamic).name as String;
        _newFavoriteTeamLogo = (result as dynamic).logo as String?;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final profile = authProvider.userProfile;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Stack(
                    children: [
                      if (_isUploadingImage)
                        Container(
                          width: 100,
                          height: 100,
                          decoration: const BoxDecoration(
                            color: AppColors.cardSurface,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(child: CircularProgressIndicator()),
                        )
                      else
                        CustomAvatar(imageUrl: _newAvatarUrl ?? profile?.avatarUrl, size: 100),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _isUploadingImage ? null : _pickAndUploadImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.accentBlue,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primaryDark, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt, color: AppColors.textWhite, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  CustomTextField(
                    controller: _displayNameController,
                    labelText: 'Display Name',
                    hintText: 'Enter your display name',
                    prefixIcon: Icons.person,
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _usernameController,
                    labelText: 'Username',
                    hintText: 'Enter your username',
                    prefixIcon: Icons.alternate_email,
                  ),
                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: _selectTeam,
                    child: AbsorbPointer(
                      child: CustomTextField(
                        controller: _favoriteTeamController,
                        labelText: 'Favorite Team',
                        hintText: 'Select your favorite team',
                        prefixIcon: Icons.sports_soccer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _bioController,
                    labelText: 'Bio',
                    hintText: 'Tell us about yourself',
                    prefixIcon: Icons.info,
                    maxLines: 4,
                    maxLength: 150,
                  ),
                  const SizedBox(height: 32),

                  GradientButton(
                    text: 'Save Changes',
                    isLoading: authProvider.isLoading || _isUploadingImage,
                    onPressed: () => _saveProfile(authProvider),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveProfile(AuthProvider authProvider) async {
    if (!_formKey.currentState!.validate()) return;

    final success = await authProvider.updateProfile(
      displayName: _displayNameController.text.trim(),
      username: _usernameController.text.trim(),
      favoriteTeam: _favoriteTeamController.text.trim(),
      favoriteTeamLogo: _newFavoriteTeamLogo,
      bio: _bioController.text.trim(),
      avatarUrl: _newAvatarUrl,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: AppColors.successGreen,
        ),
      );
      context.pop();
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 75,
      );
      if (image == null) return;

      setState(() => _isUploadingImage = true);

      final String downloadUrl = await _imageUploadService.uploadImage(File(image.path));

      if (mounted) {
        setState(() {
          _newAvatarUrl = downloadUrl;
          _isUploadingImage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }
}
