package com.macif.plugin.sslpinningplugin

import android.os.Build
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

import javax.net.ssl.HttpsURLConnection
import javax.security.cert.CertificateException
import java.io.IOException
import java.text.ParseException

import java.net.URL
import java.security.MessageDigest
import java.security.NoSuchAlgorithmException
import java.security.cert.Certificate
import java.security.cert.CertificateEncodingException

import android.os.StrictMode

import androidx.annotation.NonNull
import androidx.annotation.RequiresApi

class SslPinningPlugin: MethodCallHandler, FlutterPlugin {

    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel : MethodChannel

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        StrictMode.setThreadPolicy(StrictMode.ThreadPolicy.Builder().detectAll().build())

        channel = MethodChannel(flutterPluginBinding.getFlutterEngine().getDartExecutor(), "ssl_pinning_plugin")
        channel.setMethodCallHandler(this);
    }

    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar): {
            // Disable the `NetworkOnMainThreadException` and make sure it is just logged.
            StrictMode.setThreadPolicy(StrictMode.ThreadPolicy.Builder().detectAll().build())

            val channel = MethodChannel(registrar.messenger(), "ssl_pinning_plugin")
            channel.setMethodCallHandler(SslPinningPlugin())
        }
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        try {
            when (call.method) {
                "check" -> handleCheckEvent(call, result)
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error(e.toString(), "", "")
        }

    }

    @Throws(ParseException::class)
    private fun handleCheckEvent(call: MethodCall, result: Result) {

        val arguments: HashMap<String, Any> = call.arguments as HashMap<String, Any>
        val serverURL: String = arguments.get("url") as String
        val allowedFingerprints: List<String> = arguments.get("fingerprints") as List<String>
        val httpHeaderArgs: Map<String, String> = arguments.get("headers") as Map<String, String>
        val timeout: Int = arguments.get("timeout") as Int
        val type: String = arguments.get("type") as String

        if (this.checkConnexion(serverURL, allowedFingerprints, httpHeaderArgs, timeout, type)) {
            result.success("CONNECTION_SECURE")
        } else {
            result.error("CONNECTION_NOT_SECURE", "Connection is not secure", "Fingerprint doesn't match")
        }

    }

    fun checkConnexion(serverURL: String, allowedFingerprints: List<String>, httpHeaderArgs: Map<String, String>, timeout: Int, type: String): Boolean {
        val sha: String = this.getFingerprint(serverURL, timeout, httpHeaderArgs, type)
        return allowedFingerprints.map { fp -> fp.toUpperCase().replace("\\s".toRegex(), "") }.contains(sha)
    }

    @Throws(IOException::class, NoSuchAlgorithmException::class, CertificateException::class, CertificateEncodingException::class)
    private fun getFingerprint(httpsURL: String, connectTimeout: Int, httpHeaderArgs: Map<String, String>, type: String): String {

        val url = URL(httpsURL)
        val httpClient: HttpsURLConnection = url.openConnection() as HttpsURLConnection

        httpHeaderArgs.forEach { key, value -> httpClient.setRequestProperty(key, value) }
        httpClient.connect()

        val cert: Certificate = httpClient.getServerCertificates()[0] as Certificate

        return this.hashString(type, cert.getEncoded())

    }

    private fun hashString(type: String, input: ByteArray) =
            MessageDigest
                    .getInstance(type)
                    .digest(input)
                    .map { String.format("%02X", it) }
                    .joinToString(separator = "")


    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
