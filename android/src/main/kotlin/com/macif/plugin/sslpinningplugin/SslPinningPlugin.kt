package com.macif.plugin.sslpinningplugin

import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.MethodCall
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

class SslPinningPlugin() : MethodCallHandler {

    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar): Unit {

            val policy = StrictMode.ThreadPolicy.Builder().permitAll().build()
            StrictMode.setThreadPolicy(policy)

            val channel = MethodChannel(registrar.messenger(), "ssl_pinning_plugin")
            channel.setMethodCallHandler(SslPinningPlugin())
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result): Unit {
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

        //result.success(this.checkConnexion(serverURL, allowedFingerprints, httpHeaderArgs, timeout))

        if (this.checkConnexion(serverURL, allowedFingerprints, httpHeaderArgs, timeout)) {
            result.success("CONNECTION_SECURE")
        } else {
            result.error("CONNECTION_NOT_SECURE", "Connection is not secure", "Fingerprint doesn't match")
        }

    }

    fun checkConnexion(serverURL: String, allowedFingerprints: List<String>, httpHeaderArgs: Map<String, String>, timeout: Int): Boolean {
        val sha1: String = this.getFingerprint(serverURL, timeout, httpHeaderArgs)
        return allowedFingerprints.map { fp -> fp.toUpperCase().replace("\\s".toRegex(), "") }.contains(sha1)
    }

    @Throws(IOException::class, NoSuchAlgorithmException::class, CertificateException::class, CertificateEncodingException::class)
    private fun getFingerprint(httpsURL: String, connectTimeout: Int, httpHeaderArgs: Map<String, String>): String {

        val url = URL(httpsURL)
        val httpClient: HttpsURLConnection = url.openConnection() as HttpsURLConnection

        httpHeaderArgs.forEach { key, value -> httpClient.setRequestProperty(key, value) }
        httpClient.connect();

        val cert: Certificate = httpClient.getServerCertificates()[0] as Certificate

        return this.hashString("SHA1", cert.getEncoded())

    }

    private fun hashString(type: String, input: ByteArray) =
            MessageDigest
                    .getInstance(type)
                    .digest(input)
                    .map { String.format("%02X", it) }
                    .joinToString(separator = "")
}
