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

final int WIDTH = 1200; // Okay so I guess this is kind of locked in place now?
final int HEIGHT = 790;

final int SERVER_TCP_PORT = 25577;
final int SERVER_UDP_PORT_A_LAN = 16440;
final int SERVER_UDP_PORT_A_WAN = 16440;
final int SERVER_UDP_PORT_B_LAN = 16441;
final int SERVER_UDP_PORT_B_WAN = 16441;

final InetAddress[] GATEWAYS = {
  InetAddressByName("192.168.0.1"),
  InetAddressByName("192.168.1.1")
};
boolean isIPaGateway(InetAddress ip) {
  for (InetAddress gateway : GATEWAYS) if (gateway.equals(ip)) return true;
  return false;
}
final InetAddress WAN = InetAddressByName("91.160.183.12");

void keyPressed() {
  randomizeTerrain(8);
}

void setup() {
  size(0, 0);

  randomizeTerrain(8);
  setGamemode(new Freeplay());
  //setGamemode(new Runner());

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
  gamemode.update();
  updateCamPos();
  removeInactivePlayers();
  updatePlayers();
  updateHoles();
}

boolean SOMEONES_IT = false;

// (TCP) run when a new client connects to a server
void serverEvent(Server serv, Client myClient) {
  int UUID = getFreeUUID();
  TCP_SEND_ALL_CLIENTS(NOTIFY_NEW_PLAYER(UUID));
  Player myPlayer = new Player(myClient, UUID);
  players.put(UUID, myPlayer);
  myPlayer.synchronize();
}

InetAddress InetAddressByName(String ip) {
  try {
    return InetAddress.getByName(ip);
  }
  catch(Exception e) {
    return null;
  }
}

void updateCamPos() {
  if (frameCount%3==0)TCP_SEND_ALL_CLIENTS(NOTIFY_CAM_POS());
}
