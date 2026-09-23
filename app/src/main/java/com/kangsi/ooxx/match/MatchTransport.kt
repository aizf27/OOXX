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
import kotlinx.coroutines.withContext
import java.io.BufferedReader
import java.io.Closeable
import java.io.InputStreamReader
import java.net.Socket
import java.util.UUID

interface MatchConnection : Closeable {
    suspend fun send(message: String)
    suspend fun receive(): String?
}

class TcpMatchClient {
    suspend fun connect(roomCode: String): MatchConnection = withContext(Dispatchers.IO) {
        val socket = Socket(BuildConfig.MATCH_HOST, BuildConfig.MATCH_PORT)
        SocketConnection(socket).also { it.send("JOIN|$roomCode") }
    }
}

private class SocketConnection(private val socket: Socket) : MatchConnection {
    private val reader = BufferedReader(InputStreamReader(socket.getInputStream()))
    private val writer = socket.getOutputStream().bufferedWriter()
    override suspend fun send(message: String) = withContext(Dispatchers.IO) {
        writer.write(message.replace("\n", ""))
        writer.newLine()
        writer.flush()
    }
    override suspend fun receive(): String? = withContext(Dispatchers.IO) { reader.readLine() }
    override fun close() = socket.close()
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
