import processing.net.*;

import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.InetAddress;

import java.util.Set;
import java.util.HashSet;
import java.util.Map;
import java.util.Iterator;

DatagramSocket SERVER_UDP_SOCKET;
Server SERVER_TCP_SERVER;

final int SERVER_TCP_PORT = 25577;
final int SERVER_UDP_PORT_A_LAN = 16440;
final int SERVER_UDP_PORT_A_WAN = 16440;
final int SERVER_UDP_PORT_B_LAN = 16441;
final int SERVER_UDP_PORT_B_WAN = 16441;

final InetAddress GATEWAY = InetAddressByName("192.168.0.1");
final InetAddress WAN = InetAddressByName("91.160.183.12");

void setup() {
  size(0, 0); 

  randomizeTerrain();

  SERVER_TCP_SERVER = new Server(this, SERVER_TCP_PORT);
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
  updateHoles();
}

// (TCP) run when a new client connects to a server
void serverEvent(Server serv, Client myClient) {
  int UUID = getFreeUUID();
  Player myPlayer = new Player(myClient, UUID);
  players.put(UUID, myPlayer);
  TCP_SEND_ALL_CLIENTS_EXCEPT(NOTIFY_NEW_PLAYER(UUID), UUID);
}

InetAddress InetAddressByName(String ip) {
  try {
    return InetAddress.getByName(ip);
  } 
  catch(Exception e) {
    return null;
  }
}
