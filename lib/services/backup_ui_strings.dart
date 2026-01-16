/// UI strings for local encrypted backup feature
class BackupUIStrings {
  BackupUIStrings._();

  static const String backupFeatureName = 'Local Encrypted Backup';
  static const String backupLocation = 'This Device';
  
  static const String backupDescription = 
      'Your accounts are encrypted with your password and stored securely on this device. '
      'This backup is automatically updated when you add or remove accounts.';
  
  static const String restoreDescription = 
      'Restore your accounts from the encrypted backup stored on this device.';
  
  static const String noBackupMessage = 
      'No backup found on this device. Add accounts to create your first backup.';
  
  static const String backupSetupInstructions = 
      'Create a strong password to encrypt your backup. You\'ll need this password to restore your accounts.';
  
  static const String passwordRequirement = 
      'Your backup password must be at least 8 characters long and include a mix of letters and numbers.';
  
  static const String backupSuccessMessage = 
      'Backup created successfully and stored on this device.';
  
  static const String restoreSuccessMessage = 
      'Accounts restored successfully from local backup.';
  
  static const String backupEnabledMessage = 
      'Automatic backup is now enabled. Your accounts will be backed up locally whenever you make changes.';
  
  static const String backupDisabledMessage = 
      'Automatic backup has been disabled. Your existing backup file remains on this device.';
}
