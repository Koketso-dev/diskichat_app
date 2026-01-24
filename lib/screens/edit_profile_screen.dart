import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/themes/app_colors.dart';
import '../../utils/routes.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../services/image_upload_service.dart';
import '../../components/buttons/gradient_button.dart';
import '../../components/inputs/custom_text_field.dart';
import '../../components/avatars/custom_avatar.dart';
import 'onboarding/team_selection_screen.dart';
import 'onboarding/country_selection_screen.dart';
import '../data/models/country_model.dart';


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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profile = authProvider.userProfile;

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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) return;

    // Direct to Team Selection (No Country Category)
    if (!mounted) return;
    final teamResult = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeamSelectionScreen(
          userId: user.uid,
          subscriptionType: 'FREE', // Or fetch actual subscription if available
          currentFollowCount: 0, 
          // countryName argument removed (null) implies "All Teams"
        ),
      ),
    );

    if (teamResult != null) {
      // Result is Team object (dynamic or typed)
      final teamName = (teamResult as dynamic).name;
      final teamLogo = (teamResult as dynamic).logo;

      setState(() {
        _favoriteTeamController.text = teamName;
        _newFavoriteTeamLogo = teamLogo;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final profile = authProvider.userProfile;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Avatar
                  Stack(
                    children: [
                      // Avatar with loading indicator
                      if (_isUploadingImage)
                        Container(
                          width: 100,
                          height: 100,
                          decoration: const BoxDecoration(
                            color: AppColors.cardSurface,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else
                        CustomAvatar(
                          imageUrl: _newAvatarUrl ?? profile?.avatarUrl,
                          size: 100,
                        ),
                      
                      // Edit button
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
                              border: Border.all(
                                color: AppColors.primaryDark,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: AppColors.textWhite,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Display Name
                  CustomTextField(
                    controller: _displayNameController,
                    labelText: 'Display Name',
                    hintText: 'Enter your display name',
                    prefixIcon: Icons.person,
                  ),

                  const SizedBox(height: 16),

                  // Username
                  CustomTextField(
                    controller: _usernameController,
                    labelText: 'Username',
                    hintText: 'Enter your username',
                    prefixIcon: Icons.alternate_email,
                  ),

                  const SizedBox(height: 16),

                  // Favorite Team - Updated to be ReadOnly and triggering selection
                  GestureDetector(
                    onTap: _selectTeam,
                    child: AbsorbPointer(
                      child: CustomTextField(
                        controller: _favoriteTeamController,
                        labelText: 'Favorite Team',
                        hintText: 'Select your favorite team',
                        prefixIcon: Icons.sports_soccer,
                        // readOnly: true, // CustomTextField might not support readOnly prop directly if custom.
                                          // Using AbsorbPointer + GestureDetector is a safe way.
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Bio
                  CustomTextField(
                    controller: _bioController,
                    labelText: 'Bio',
                    hintText: 'Tell us about yourself',
                    prefixIcon: Icons.info,
                    maxLines: 4,
                    maxLength: 150,
                  ),

                  const SizedBox(height: 32),

                  // Save button
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
      favoriteTeamLogo: _newFavoriteTeamLogo, // Include new logo
      bio: _bioController.text.trim(),
      avatarUrl: _newAvatarUrl,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully'),
          backgroundColor: AppColors.successGreen,
        ),
      );
      AppRoutes.navigateBack(context);
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

      setState(() {
        _isUploadingImage = true;
      });

      final File file = File(image.path);
      final String downloadUrl = await _imageUploadService.uploadImage(file);

      if (mounted) {
        setState(() {
          _newAvatarUrl = downloadUrl;
          _isUploadingImage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
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