package com.kangsi.ooxx.match

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothServerSocket
import android.bluetooth.BluetoothSocket
import android.content.Context
import com.kangsi.ooxx.BuildConfig
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import okhttp3.WebSocket
import okhttp3.WebSocketListener
import java.io.BufferedReader
import java.io.Closeable
import java.io.InputStreamReader
import java.util.UUID
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

interface MatchConnection : Closeable {
    suspend fun send(message: String)
    suspend fun receive(): String?
}

/** Standard WebSocket client for ws://host:9527/ws (not Socket.IO). */
class WebSocketMatchClient(private val client: OkHttpClient = OkHttpClient()) {
    suspend fun connect(url: String = BuildConfig.MATCH_WS_URL): MatchConnection = suspendCancellableCoroutine { continuation ->
        val messages = Channel<String>(Channel.BUFFERED)
        lateinit var socket: WebSocket
        socket = client.newWebSocket(Request.Builder().url(url).build(), object : WebSocketListener() {
            override fun onOpen(webSocket: WebSocket, response: Response) {
                if (continuation.isActive) continuation.resume(WebSocketConnection(webSocket, messages))
            }

            override fun onMessage(webSocket: WebSocket, text: String) {
                messages.trySend(text)
            }

            override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                messages.close(t)
                if (continuation.isActive) continuation.resumeWithException(t)
            }

            override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
                messages.close()
            }
        })
        continuation.invokeOnCancellation { socket.cancel(); messages.close() }
    }
}

private class WebSocketConnection(
    private val socket: WebSocket,
    private val messages: Channel<String>
) : MatchConnection {
    override suspend fun send(message: String) {
        check(socket.send(message)) { "WebSocket 已关闭" }
    }
    override suspend fun receive(): String? = messages.receiveCatching().getOrNull()
    override fun close() { socket.close(1000, "client closed"); messages.close() }
}

class BluetoothMatchService(context: Context) {
    private val adapter: BluetoothAdapter? =
        (context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager).adapter
    private val serviceUuid = UUID.fromString("54f53f2e-6cc5-4aa4-b851-8b229c758850")

    fun isAvailable(): Boolean = adapter != null
    fun isEnabled(): Boolean = adapter?.isEnabled == true

    @SuppressLint("MissingPermission")
    fun pairedDevices(): List<BluetoothDevice> = adapter?.bondedDevices?.sortedBy { it.name }.orEmpty()

    @SuppressLint("MissingPermission")
    suspend fun host(): MatchConnection = withContext(Dispatchers.IO) {
        val server: BluetoothServerSocket = adapter
            ?.listenUsingRfcommWithServiceRecord("OOXX 对战", serviceUuid)
            ?: error("设备不支持蓝牙")
        try {
            BluetoothConnection(server.accept())
        } finally {
            server.close()
        }
    }

    @SuppressLint("MissingPermission")
    suspend fun connect(device: BluetoothDevice): MatchConnection = withContext(Dispatchers.IO) {
        adapter?.cancelDiscovery()
        val socket = device.createRfcommSocketToServiceRecord(serviceUuid)
        socket.connect()
        BluetoothConnection(socket)
    }
}

private class BluetoothConnection(private val socket: BluetoothSocket) : MatchConnection {
    private val reader = BufferedReader(InputStreamReader(socket.inputStream))
    private val writer = socket.outputStream.bufferedWriter()
    override suspend fun send(message: String) = withContext(Dispatchers.IO) {
        writer.write(message.replace("\n", ""))
        writer.newLine()
        writer.flush()
    }
    override suspend fun receive(): String? = withContext(Dispatchers.IO) { reader.readLine() }
    override fun close() = socket.close()
}
