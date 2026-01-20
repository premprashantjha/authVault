import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../app/theme.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Terms of Service',
          style: AppTheme.headlineMedium(colorScheme.onSurface),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: FutureBuilder<String>(
        future: rootBundle.loadString('assets/legal/terms_of_service.md'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error Loading Terms of Service',
                      style: AppTheme.bodyLarge(colorScheme.onSurface),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please try again later or contact support.',
                      style: AppTheme.bodyMedium(
                        colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return Markdown(
            data: snapshot.data ?? '',
            styleSheet: MarkdownStyleSheet(
              h1: AppTheme.headlineLarge(colorScheme.onSurface),
              h2: AppTheme.headlineMedium(colorScheme.onSurface),
              h3: AppTheme.bodyLarge(
                colorScheme.onSurface,
              ).copyWith(fontWeight: AppTheme.weightBold),
              h4: AppTheme.bodyLarge(
                colorScheme.onSurface,
              ).copyWith(fontWeight: AppTheme.weightSemiBold),
              p: AppTheme.bodyMedium(
                colorScheme.onSurface.withValues(alpha: 0.8),
              ),
              listBullet: AppTheme.bodyMedium(
                colorScheme.onSurface.withValues(alpha: 0.8),
              ),
              strong: AppTheme.bodyMedium(
                colorScheme.onSurface,
              ).copyWith(fontWeight: AppTheme.weightBold),
              em: AppTheme.bodyMedium(
                colorScheme.onSurface.withValues(alpha: 0.8),
              ).copyWith(fontStyle: FontStyle.italic),
              blockquote: AppTheme.bodyMedium(
                colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              code: AppTheme.caption(colorScheme.primary).copyWith(
                fontFamily: 'monospace',
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
              horizontalRuleDecoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: colorScheme.outlineVariant, width: 1),
                ),
              ),
            ),
            padding: const EdgeInsets.all(20),
          );
        },
      ),
    );
  }
}
