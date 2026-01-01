import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class IconService {
  static final Map<String, IconData> _serviceIcons = {
    // Google services
    'google': FontAwesomeIcons.google,
    'gmail': FontAwesomeIcons.google,
    'youtube': FontAwesomeIcons.youtube,
    'google drive': FontAwesomeIcons.googleDrive,
    'google photos': FontAwesomeIcons.google,
    
    // Social media
    'facebook': FontAwesomeIcons.facebook,
    'twitter': FontAwesomeIcons.twitter,
    'instagram': FontAwesomeIcons.instagram,
    'linkedin': FontAwesomeIcons.linkedin,
    'discord': FontAwesomeIcons.discord,
    'telegram': FontAwesomeIcons.telegram,
    'whatsapp': FontAwesomeIcons.whatsapp,
    'reddit': FontAwesomeIcons.reddit,
    'snapchat': FontAwesomeIcons.snapchat,
    'tiktok': FontAwesomeIcons.tiktok,
    
    // Cloud services
    'dropbox': FontAwesomeIcons.dropbox,
    'onedrive': FontAwesomeIcons.microsoft,
    'icloud': FontAwesomeIcons.apple,
    'aws': FontAwesomeIcons.aws,
    'azure': FontAwesomeIcons.microsoft,
    
    // Development
    'github': FontAwesomeIcons.github,
    'gitlab': FontAwesomeIcons.gitlab,
    'bitbucket': FontAwesomeIcons.bitbucket,
    'docker': FontAwesomeIcons.docker,
    'npm': FontAwesomeIcons.npm,
    'node': FontAwesomeIcons.node,
    
    // Banking & Finance
    'paypal': FontAwesomeIcons.paypal,
    'stripe': FontAwesomeIcons.stripe,
    'venmo': Icons.account_balance_wallet,
    'cashapp': Icons.attach_money,
    'coinbase': FontAwesomeIcons.bitcoin,
    'binance': Icons.trending_up,
    
    // E-commerce
    'amazon': FontAwesomeIcons.amazon,
    'ebay': FontAwesomeIcons.ebay,
    'shopify': FontAwesomeIcons.shopify,
    'etsy': FontAwesomeIcons.etsy,
    
    // Communication
    'slack': FontAwesomeIcons.slack,
    'teams': FontAwesomeIcons.microsoft,
    'zoom': Icons.videocam,
    'skype': FontAwesomeIcons.skype,
    
    // Gaming
    'steam': FontAwesomeIcons.steam,
    'epic games': Icons.games,
    'xbox': FontAwesomeIcons.xbox,
    'playstation': FontAwesomeIcons.playstation,
    'nintendo': Icons.sports_esports,
    'twitch': FontAwesomeIcons.twitch,
    
    // Productivity
    'notion': Icons.note,
    'trello': FontAwesomeIcons.trello,
    'asana': Icons.task,
    'jira': FontAwesomeIcons.jira,
    'confluence': FontAwesomeIcons.confluence,
    
    // Other services
    'spotify': FontAwesomeIcons.spotify,
    'apple': FontAwesomeIcons.apple,
    'microsoft': FontAwesomeIcons.microsoft,
    'yahoo': FontAwesomeIcons.yahoo,
    'wordpress': FontAwesomeIcons.wordpress,
    'medium': FontAwesomeIcons.medium,
    
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
    if (lowerIssuer.contains('microsoft')) return FontAwesomeIcons.microsoft;
    if (lowerIssuer.contains('apple')) return FontAwesomeIcons.apple;
    if (lowerIssuer.contains('amazon')) return _serviceIcons['amazon']!;
    if (lowerIssuer.contains('facebook')) return _serviceIcons['facebook']!;
    if (lowerIssuer.contains('twitter')) return _serviceIcons['twitter']!;
    if (lowerIssuer.contains('github')) return _serviceIcons['github']!;
    if (lowerIssuer.contains('paypal')) return _serviceIcons['paypal']!;
    if (lowerIssuer.contains('bank')) return Icons.account_balance;
    if (lowerIssuer.contains('crypto') || lowerIssuer.contains('bitcoin')) return FontAwesomeIcons.bitcoin;
    
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
