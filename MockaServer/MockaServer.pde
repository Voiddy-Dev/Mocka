import processing.net.*;

import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.InetAddress;

DatagramSocket SERVER_UDP_SOCKET;
Server SERVER_TCP_SERVER;

final int SERVER_TCP_PORT = 25567;
final int SERVER_UDP_PORT = 16440;

void setup() {
  size(0, 0); 

  SERVER_TCP_SERVER = new Server(this, SERVER_TCP_PORT);
  try {
    SERVER_UDP_SOCKET = new DatagramSocket(SERVER_UDP_PORT);
  } 
  catch(Exception e) {
    println("SERVER: ERROR: server could not open UDP socket on port "+SERVER_UDP_PORT);
    exit();
  }

  println("SERVER: Starting server");
}

void draw() {
  if (!SERVER_TCP_SERVER.active()) {
    println("SERVER: Trouble! Server is no longer processing-active. Stopping.");
    // Probably graciously notify all clients if possible
    SERVER_TCP_SERVER.stop();
    SERVER_UDP_SOCKET.close();
    stop();
  }
  removeInactivePlayers();
  updatePlayers();
}

// (TCP) run when a new client connects to a server
void serverEvent(Server serv, Client myClient) {
  int UUID = getFreeUUID();
  Player myPlayer = new Player(myClient, UUID);
  players.put(UUID, myPlayer);
  TCP_SEND_ALL_CLIENTS_EXCEPT(NOTIFY_NEW_PLAYER(UUID), UUID);
}
