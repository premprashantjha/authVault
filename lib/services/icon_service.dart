import 'package:flutter/material.dart';

class IconService {
  static final Map<String, IconData> _serviceIcons = {
    // Google services
    'google': Icons.g_mobiledata,
    'gmail': Icons.mail,
    'youtube': Icons.play_circle,
    'google drive': Icons.cloud,
    'google photos': Icons.photo_library,
    
    // Social media
    'facebook': Icons.facebook,
    'twitter': Icons.alternate_email,
    'instagram': Icons.camera_alt,
    'linkedin': Icons.work,
    'discord': Icons.chat,
    'telegram': Icons.send,
    'whatsapp': Icons.message,
    
    // Cloud services
    'dropbox': Icons.cloud_download,
    'onedrive': Icons.cloud_upload,
    'icloud': Icons.cloud,
    'aws': Icons.cloud_circle,
    'azure': Icons.cloud_queue,
    
    // Development
    'github': Icons.code,
    'gitlab': Icons.terminal,
    'bitbucket': Icons.storage,
    'docker': Icons.dock,
    
    // Banking & Finance
    'paypal': Icons.payment,
    'stripe': Icons.credit_card,
    'venmo': Icons.account_balance_wallet,
    'cashapp': Icons.attach_money,
    'coinbase': Icons.currency_bitcoin,
    'binance': Icons.trending_up,
    
    // E-commerce
    'amazon': Icons.shopping_cart,
    'ebay': Icons.store,
    'shopify': Icons.storefront,
    'etsy': Icons.handyman,
    
    // Communication
    'slack': Icons.chat_bubble,
    'teams': Icons.groups,
    'zoom': Icons.videocam,
    'skype': Icons.video_call,
    
    // Gaming
    'steam': Icons.sports_esports,
    'epic games': Icons.games,
    'xbox': Icons.sports_esports,
    'playstation': Icons.sports_esports,
    'nintendo': Icons.sports_esports,
    
    // Productivity
    'notion': Icons.note,
    'trello': Icons.dashboard,
    'asana': Icons.task,
    'jira': Icons.bug_report,
    'confluence': Icons.description,
    
    // Security
    '1password': Icons.lock,
    'lastpass': Icons.security,
    'bitwarden': Icons.security,
    'dashlane': Icons.shield,
    
    // Default fallback
    'default': Icons.security,
  };

  static IconData getIconForService(String issuer) {
    if (issuer.isEmpty) return _serviceIcons['default']!;
    
    final lowerIssuer = issuer.toLowerCase().trim();
    
    // Direct match
    if (_serviceIcons.containsKey(lowerIssuer)) {
      return _serviceIcons[lowerIssuer]!;
    }
    
    // Partial matches for common patterns
    for (final entry in _serviceIcons.entries) {
      if (lowerIssuer.contains(entry.key) || entry.key.contains(lowerIssuer)) {
        return entry.value;
      }
    }
    
    // Check for common patterns
    if (lowerIssuer.contains('google')) return _serviceIcons['google']!;
    if (lowerIssuer.contains('microsoft')) return Icons.business;
    if (lowerIssuer.contains('apple')) return Icons.apple;
    if (lowerIssuer.contains('amazon')) return _serviceIcons['amazon']!;
    if (lowerIssuer.contains('facebook')) return _serviceIcons['facebook']!;
    if (lowerIssuer.contains('twitter')) return _serviceIcons['twitter']!;
    if (lowerIssuer.contains('github')) return _serviceIcons['github']!;
    if (lowerIssuer.contains('paypal')) return _serviceIcons['paypal']!;
    if (lowerIssuer.contains('bank')) return Icons.account_balance;
    if (lowerIssuer.contains('crypto') || lowerIssuer.contains('bitcoin')) return _serviceIcons['coinbase']!;
    
    // Default fallback
    return _serviceIcons['default']!;
  }

  static Color getColorForService(String issuer) {
    final lowerIssuer = issuer.toLowerCase().trim();
    
    // Service-specific colors
    if (lowerIssuer.contains('google')) return const Color(0xFF4285F4);
    if (lowerIssuer.contains('microsoft')) return const Color(0xFF0078D4);
    if (lowerIssuer.contains('apple')) return const Color(0xFF000000);
    if (lowerIssuer.contains('facebook')) return const Color(0xFF1877F2);
    if (lowerIssuer.contains('twitter')) return const Color(0xFF1DA1F2);
    if (lowerIssuer.contains('github')) return const Color(0xFF333333);
    if (lowerIssuer.contains('paypal')) return const Color(0xFF0070BA);
    if (lowerIssuer.contains('amazon')) return const Color(0xFFFF9900);
    if (lowerIssuer.contains('discord')) return const Color(0xFF5865F2);
    if (lowerIssuer.contains('slack')) return const Color(0xFF4A154B);
    if (lowerIssuer.contains('steam')) return const Color(0xFF171a21);
    if (lowerIssuer.contains('bank')) return const Color(0xFF2E7D32);
    if (lowerIssuer.contains('crypto') || lowerIssuer.contains('bitcoin')) return const Color(0xFFF7931A);
    
    // Default color
    return const Color(0xFF8B5CF6);
  }
}
