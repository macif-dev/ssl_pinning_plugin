package com.macif.plugin.sslpinningplugin

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
import androidx.annotation.NonNull
import java9.util.concurrent.CompletableFuture

class SslPinningPlugin: MethodCallHandler, FlutterPlugin {

    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel : MethodChannel

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "ssl_pinning_plugin")
        channel.setMethodCallHandler(this);
    }

    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar){

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
        val httpMethod: String = arguments.get("httpMethod") as String
        val httpHeaderArgs: Map<String, String> = arguments.get("headers") as Map<String, String>
        val timeout: Int = arguments.get("timeout") as Int
        val type: String = arguments.get("type") as String

        val get: Boolean = CompletableFuture.supplyAsync { this.checkConnexion(serverURL, allowedFingerprints, httpHeaderArgs, timeout, type, httpMethod) }.get()

        if(get) {
            result.success("CONNECTION_SECURE")
        }else {
            result.error("CONNECTION_NOT_SECURE", "Connection is not secure", "Fingerprint doesn't match")
        }

    }

    private fun checkConnexion(serverURL: String, allowedFingerprints: List<String>, httpHeaderArgs: Map<String, String>, timeout: Int, type: String, httpMethod: String): Boolean {
        val sha: String = this.getFingerprint(serverURL, timeout, httpHeaderArgs, type, httpMethod)
        return allowedFingerprints.map { fp -> fp.toUpperCase().replace("\\s".toRegex(), "") }.contains(sha)
    }

    @Throws(IOException::class, NoSuchAlgorithmException::class, CertificateException::class, CertificateEncodingException::class)
    private fun getFingerprint(httpsURL: String, connectTimeout: Int, httpHeaderArgs: Map<String, String>, type: String, httpMethod: String): String {

        val url = URL(httpsURL)
        val httpClient: HttpsURLConnection = url.openConnection() as HttpsURLConnection

        if (httpMethod == "Head") httpClient.requestMethod = "HEAD";
        httpHeaderArgs.forEach { entry -> httpClient.setRequestProperty(entry.key, entry.value) }

        httpClient.connect()

        val cert: Certificate = httpClient.serverCertificates[0] as Certificate

        httpClient.disconnect()

        return this.hashString(type, cert.encoded)

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
