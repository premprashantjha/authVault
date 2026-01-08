package com.cdac.authenticator

import android.accounts.AccountManager
import android.app.Activity
import android.content.Context
import android.content.Intent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

class AccountPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var activity: Activity? = null
    private var pendingResult: Result? = null
    
    companion object {
        private const val ACCOUNT_PICKER_REQUEST_CODE = 1002
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.cdac.authenticator/account")
        channel.setMethodCallHandler(this)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getGoogleAccountId" -> {
                showAccountPicker(result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun showAccountPicker(result: Result) {
        val currentActivity = activity
        if (currentActivity == null) {
            result.error("NO_ACTIVITY", "Activity not available", null)
            return
        }

        try {
            // Use AccountManager.newChooseAccountIntent() - no permission required!
            // This shows a system account picker dialog
            val intent = AccountManager.newChooseAccountIntent(
                null, // selectedAccount
                null, // allowableAccounts
                arrayOf("com.google"), // allowableAccountTypes - only Google accounts
                null, // descriptionOverrideText
                null, // addAccountAuthTokenType
                null, // addAccountRequiredFeatures
                null  // addAccountOptions
            )
            
            pendingResult = result
            currentActivity.startActivityForResult(intent, ACCOUNT_PICKER_REQUEST_CODE)
        } catch (e: Exception) {
            android.util.Log.e("AccountPlugin", "Error showing account picker: ${e.message}", e)
            result.error("PICKER_ERROR", "Failed to show account picker: ${e.message}", null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == ACCOUNT_PICKER_REQUEST_CODE) {
            val result = pendingResult ?: return false
            pendingResult = null
            
            if (resultCode == Activity.RESULT_OK && data != null) {
                // User selected an account
                val accountName = data.getStringExtra(AccountManager.KEY_ACCOUNT_NAME)
                if (accountName != null) {
                    android.util.Log.d("AccountPlugin", "Account selected: $accountName")
                    result.success(accountName)
                } else {
                    result.error("NO_ACCOUNT_SELECTED", "No account name returned", null)
                }
            } else {
                // User cancelled or no account selected
                result.error("CANCELLED", "Account selection cancelled", null)
            }
            return true
        }
        return false
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
