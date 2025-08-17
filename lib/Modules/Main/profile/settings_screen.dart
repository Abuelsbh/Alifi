import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/Language/app_languages.dart';
import '../../../core/Theme/theme_provider.dart';
import '../../../core/Theme/theme_model.dart';
import '../../../Widgets/custom_card.dart';
import '../../../Widgets/translated_text.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const TranslatedText('profile.settings'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // إعدادات اللغة
            _buildSection(
              context,
              title: 'profile.language',
              children: [
                _buildLanguageSelector(context),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // إعدادات المظهر
            _buildSection(
              context,
              title: 'profile.theme',
              children: [
                _buildThemeSelector(context),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // إعدادات الإشعارات
            _buildSection(
              context,
              title: 'profile.notifications',
              children: [
                _buildNotificationSettings(context),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // معلومات التطبيق
            _buildSection(
              context,
              title: 'profile.about',
              children: [
                _buildAboutSection(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TranslatedText(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        CustomCard(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageSelector(BuildContext context) {
    return Consumer<AppLanguage>(
      builder: (context, appLanguage, child) {
        return Column(
          children: appLanguage.availableLanguages.map((language) {
            final isSelected = appLanguage.appLang.name == language['code'];
            
            return ListTile(
              leading: Radio<Languages>(
                value: Languages.values.firstWhere(
                  (lang) => lang.name == language['code'],
                ),
                groupValue: appLanguage.appLang,
                onChanged: (Languages? value) {
                  if (value != null) {
                    appLanguage.changeLanguage(language: value);
                  }
                },
              ),
              title: Text(language['nativeName']!),
              subtitle: Text(language['name']!),
              trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                final selectedLanguage = Languages.values.firstWhere(
                  (lang) => lang.name == language['code'],
                );
                appLanguage.changeLanguage(language: selectedLanguage);
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildThemeSelector(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // Create light and dark theme instances
        final lightTheme = ThemeModel(
          isDark: false,
          primaryColor: Colors.green,
          accentColor: Colors.orange,
          backGroundColor: Colors.white,
          darkGreyColor: const Color(0xff555555),
          lightGreyColor: const Color(0xffaaaaaa),
          warningColor: Colors.red,
        );
        
        final darkTheme = ThemeModel(
          isDark: true,
          primaryColor: Colors.green,
          accentColor: Colors.orange,
          backGroundColor: const Color(0xff121212),
          darkGreyColor: const Color(0xff555555),
          lightGreyColor: const Color(0xffaaaaaa),
          warningColor: Colors.red,
        );
        
        return Column(
          children: [
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: const TranslatedText('common.light'),
              trailing: Radio<bool>(
                value: false,
                groupValue: themeProvider.isDarkMode,
                onChanged: (bool? value) {
                  if (value != null && value != themeProvider.isDarkMode) {
                    themeProvider.changeTheme(theme: lightTheme);
                  }
                },
              ),
              onTap: () {
                if (!themeProvider.isDarkMode) return;
                themeProvider.changeTheme(theme: lightTheme);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const TranslatedText('common.dark'),
              trailing: Radio<bool>(
                value: true,
                groupValue: themeProvider.isDarkMode,
                onChanged: (bool? value) {
                  if (value != null && value != themeProvider.isDarkMode) {
                    themeProvider.changeTheme(theme: darkTheme);
                  }
                },
              ),
              onTap: () {
                if (themeProvider.isDarkMode) return;
                themeProvider.changeTheme(theme: darkTheme);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationSettings(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          title: const TranslatedText('profile.notifications'),
          subtitle: const TranslatedText('profile.notifications_subtitle'),
          value: true, // TODO: Implement notification settings
          onChanged: (bool value) {
            // TODO: Handle notification toggle
          },
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const TranslatedText('profile.about'),
          subtitle: const TranslatedText('profile.about_subtitle'),
          onTap: () {
            // TODO: Navigate to about screen
          },
        ),
        ListTile(
          leading: const Icon(Icons.help_outline),
          title: const TranslatedText('profile.help'),
          subtitle: const TranslatedText('profile.help_subtitle'),
          onTap: () {
            // TODO: Navigate to help screen
          },
        ),
        ListTile(
          leading: const Icon(Icons.contact_support),
          title: const TranslatedText('profile.contact_us'),
          subtitle: const TranslatedText('profile.contact_us_subtitle'),
          onTap: () {
            // TODO: Navigate to contact screen
          },
        ),
        ListTile(
          leading: const Icon(Icons.description),
          title: const TranslatedText('profile.terms'),
          subtitle: const TranslatedText('profile.terms_subtitle'),
          onTap: () {
            // TODO: Navigate to terms screen
          },
        ),
        ListTile(
          leading: const Icon(Icons.app_settings_alt),
          title: const TranslatedText('profile.version'),
          subtitle: const TranslatedText('profile.version_subtitle'),
          onTap: null,
        ),
      ],
    );
  }
} 