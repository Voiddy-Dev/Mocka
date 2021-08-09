import processing.net.*;
import java.nio.ByteBuffer;

import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.InetAddress;
import java.net.NetworkInterface;
import java.net.UnknownHostException;

import java.util.Enumeration;

String SERVER_IP = "localhost";
//String SERVER_IP = "lmhleetmcgang.ddns.net";
int SERVER_TCP_PORT = 25577;

Client client;

void setupNetworking() {
  client = new Client(this, SERVER_IP, SERVER_TCP_PORT);
}

void NOTIFY_MY_COLOR(color col) {
  ByteBuffer data = ByteBuffer.allocate(5);
  data.put((byte)0);
  data.putInt(col);
  client.write(data.array());
}

void NOTIFY_NEW_TERRAIN() {
  client.write(new byte[]{(byte)1});
}

void NOTIFY_RESPAWN() {
  client.write(new byte[]{(byte)3});
}

void NOTIFY_CHAT(String msg) {
  ByteBuffer data = ByteBuffer.allocate(1+4+2*msg.length());
  data.put((byte)4);
  putString(data, msg);
  client.write(data.array());
}

void NOTIFY_PUNCHING_FAILED(int UUID) {
  ByteBuffer data = ByteBuffer.allocate(5);
  data.put((byte)5);
  data.putInt(UUID);
  client.write(data.array());
}

void NOTIFY_MAP_CHANGE_REQUEST(int plat_id) {
  Platform p = platforms.get(plat_id);
  ByteBuffer data = ByteBuffer.allocate(5 + p.size());
  data.put((byte)6);
  data.putInt(plat_id);
  p.putLocalData(data);
  client.write(data.array());
}

void NOTIFY_MAP_DELETE_REQUEST(int plat_id) {
  ByteBuffer data = ByteBuffer.allocate(5);
  data.put((byte)7);
  data.putInt(plat_id);
  client.write(data.array());
}


ByteBuffer network_data = ByteBuffer.allocate(0);

void updateNetwork() {
  readNetwork();
  interpretNetwork();
}

void interpretNetwork() {
  if (network_data.remaining()>0) {
    byte PACKET_ID = network_data.get();
    if (DEBUG_PACKETS) println("client: received from tcp server PACKET_ID: "+PACKET_ID);
    if (PACKET_ID == 0) INTERPRET_NEW_PLAYER();
    if (PACKET_ID == 1) INTERPRET_DED_PLAYER();
    if (PACKET_ID == 2) INTERPRET_OPEN_UDP();
    if (PACKET_ID == 3) INTERPRET_YOUR_UUID();
    if (PACKET_ID == 4) INTERPRET_TERRAIN();
    if (PACKET_ID == 5) INTERPRET_PLAYER_INFO();
    if (PACKET_ID == 6) INTERPRET_GAMEMODE_START();
    if (PACKET_ID == 7) INTERPRET_CHAT();
    if (PACKET_ID == 8) INTERPRET_GAMEMODE_UPDATE();
    if (PACKET_ID == 9) INTERPRET_RESPAWN();
    if (PACKET_ID == 10) INTERPRET_MAP_UPDATE();
    if (PACKET_ID == 11) INTERPRET_MAP_DELETE();
  }
}

void INTERPRET_NEW_PLAYER() {
  int new_UUID = network_data.getInt();
  EnemyRocket enemy = new EnemyRocket(new_UUID);
  enemies.put(new_UUID, enemy);
  if (DEBUG_PACKETS) println("client: new player, UUID: "+new_UUID);
}

void INTERPRET_DED_PLAYER() {
  int ded_UUID = network_data.getInt();
  removeEnemy(ded_UUID);
  if (DEBUG_PACKETS) println("client: player ded, UUID: "+ded_UUID);
}

void INTERPRET_YOUR_UUID() {
  myRocket.UUID = network_data.getInt();
}

void INTERPRET_TERRAIN() {
  killTerrain();
  platforms = getPlatforms(network_data);
}

void INTERPRET_PLAYER_INFO() {
  int UUID = network_data.getInt();
  if (DEBUG_PACKETS) println("PLAYER INFO "+UUID);
  color col = network_data.getInt();
  int points = network_data.getInt();
  int place = network_data.getInt();
  String name = getString(network_data);
  Rocket r = getRocket(UUID);
  if (r != null) {
    r.setColor(col);
    r.setName(name);
    r.points = points;
    r.place = place;
  }
}

void INTERPRET_GAMEMODE_START() {
  int MODE_ID = network_data.get();
  if (MODE_ID == 0) setGamemode(new Freeplay());
  if (MODE_ID == 1) setGamemode(new TagGame(network_data));
  if (MODE_ID == 2) setGamemode(new Crowning(network_data));
  if (MODE_ID == 3) setGamemode(new Leaderboard(network_data));
  if (MODE_ID == 4) setGamemode(new FloatGame(network_data));
  if (MODE_ID == 5) setGamemode(new CTF(network_data));
  if (MODE_ID == 6) setGamemode(new Editor(network_data));
}

void INTERPRET_CHAT() {
  String msg = getString(network_data);
  addToChatHistory(msg);
}

void INTERPRET_GAMEMODE_UPDATE() {
  gamemode.INTERPRET(network_data);
}

void INTERPRET_RESPAWN() {
  myRocket.respawnRocket();
}

void INTERPRET_MAP_UPDATE() {
  int plat_id = network_data.getInt();
  platforms.get(plat_id).getChanges(network_data);
  myRocket.body.applyTorque(0); // wake
}

void INTERPRET_MAP_DELETE() {
  int plat_id = network_data.getInt();
  Platform p = platforms.get(plat_id);
  p.killBody();
  platforms.remove(plat_id);
  myRocket.body.applyTorque(0); // wake
  if (gamemode instanceof Editor) ((Editor)gamemode).NOTIFY_platform_deleted(p);
}

int SERVER_UDP_PORT;
int INCOMING_ENEMY_UUID;

void INTERPRET_OPEN_UDP() {
  SERVER_UDP_PORT = network_data.getInt();
  INCOMING_ENEMY_UUID = network_data.getInt();

  if (DEBUG_PUNCHING) println("client: initiating hole punching for player "+INCOMING_ENEMY_UUID+" port "+SERVER_UDP_PORT);
  thread("punch_hole");
}

void punch_hole() {
  DatagramSocket CLIENT_UDP_PRIVATE_SOCKET = null;
  try {
    CLIENT_UDP_PRIVATE_SOCKET = new DatagramSocket();
    Object[] CLIENT_UDP_PRIVATE_IPS = GET_PRIVATE_IP();
    String[] CLIENT_UDP_PRIVATE_IPS_ = new String[CLIENT_UDP_PRIVATE_IPS.length];
    for (int i = 0; i < CLIENT_UDP_PRIVATE_IPS.length; i++) CLIENT_UDP_PRIVATE_IPS_[i] = CLIENT_UDP_PRIVATE_IPS[i].toString();
    String CLIENT_UDP_PRIVATE_IPS_STRING = join(CLIENT_UDP_PRIVATE_IPS_, ";");
    int CLIENT_UDP_PRIVATE_PORT = CLIENT_UDP_PRIVATE_SOCKET.getLocalPort();
    int CLIENT_UDP_PUBLIC_PORT = getExternalPort(CLIENT_UDP_PRIVATE_SOCKET);

    if (DEBUG_PUNCHING) println("client: local UDP socket open IP / port: "+CLIENT_UDP_PRIVATE_IPS_STRING+" / "+CLIENT_UDP_PRIVATE_PORT+" / (STUN) "+CLIENT_UDP_PUBLIC_PORT);
    byte[] sendData = (CLIENT_UDP_PRIVATE_IPS_STRING+"-"+CLIENT_UDP_PRIVATE_PORT+"-"+CLIENT_UDP_PUBLIC_PORT+"-").getBytes();
    DatagramPacket SEND_PACKET = new DatagramPacket(sendData, sendData.length, InetAddress.getByName(SERVER_IP), SERVER_UDP_PORT);
    CLIENT_UDP_PRIVATE_SOCKET.send(SEND_PACKET);
    if (DEBUG_PUNCHING) println("client: Sent packet to "+SERVER_IP+" : "+SERVER_UDP_PORT+" containing "+new String(sendData));

    try {
      DatagramPacket receivePacket = new DatagramPacket(new byte[1024], 1024);
      if (DEBUG_PUNCHING) println("client: Waiting to receive data packet...");
      CLIENT_UDP_PRIVATE_SOCKET.receive(receivePacket);

      String[] splitResponse = new String(receivePacket.getData()).split("-");
      InetAddress ENEMY_PUBLIC_IP = InetAddress.getByName(splitResponse[0].substring(1));
      String ENEMY_PRIVATE_IPS_STRING = splitResponse[2];
      String[] ENEMY_PRIVATE_IPS_STRING_SPLIT = ENEMY_PRIVATE_IPS_STRING.split(";");
      InetAddress[] ENEMY_PRIVATE_IPS = new InetAddress[ENEMY_PRIVATE_IPS_STRING_SPLIT.length];
      for (int i = 0; i < ENEMY_PRIVATE_IPS.length; i++) ENEMY_PRIVATE_IPS[i] = InetAddress.getByName(ENEMY_PRIVATE_IPS_STRING_SPLIT[i].substring(1));
      int ENEMY_PUBLIC_PORT = int(splitResponse[1]);
      int ENEMY_PRIVATE_PORT = int(splitResponse[3]);
      boolean CLIENT_IS_LOCAL = int(splitResponse[4]) == 1;
      boolean ENEMY_IS_LOCAL = int(splitResponse[5]) == 1;
      if (DEBUG_PUNCHING) println("client: server has answered with enemy's location. btw, CLIENT_IS_LOCAL = "+CLIENT_IS_LOCAL);

      if (DEBUG_PUNCHING) println("client: Enemy public  at "+ENEMY_PUBLIC_IP+" / "+ENEMY_PUBLIC_PORT);
      if (DEBUG_PUNCHING) println("client: Enemy private at "+ENEMY_PRIVATE_IPS_STRING+" / "+ENEMY_PRIVATE_PORT+" / on server LAN: "+ENEMY_IS_LOCAL);

      CLIENT_UDP_PRIVATE_SOCKET.close();

      EnemyRocket enemy = enemies.get(INCOMING_ENEMY_UUID);
      DatagramSocket socket;

      if (CLIENT_IS_LOCAL == ENEMY_IS_LOCAL) {
        socket = attempUDPconnection("[LAN]", CLIENT_UDP_PRIVATE_PORT, ENEMY_PRIVATE_IPS_STRING, ENEMY_PRIVATE_IPS, ENEMY_PRIVATE_PORT, 30, 100);
        if (socket != null) {
          enemy.setSocket(socket);
          return;
        }
        socket = attempUDPconnection("[WAN]", CLIENT_UDP_PRIVATE_PORT, ENEMY_PUBLIC_IP.toString(), new InetAddress[]{ENEMY_PUBLIC_IP}, ENEMY_PUBLIC_PORT, 1000, 100);
        if (socket != null) {
          enemy.setSocket(socket);
          return;
        }
      } else {
        socket = attempUDPconnection("[WAN]", CLIENT_UDP_PRIVATE_PORT, ENEMY_PUBLIC_IP.toString(), new InetAddress[]{ENEMY_PUBLIC_IP}, ENEMY_PUBLIC_PORT, 1000, 100);
        if (socket != null) {
          enemy.setSocket(socket);
          return;
        }
      }

      //SEND_PACKET = new DatagramPacket(sendData, sendData.length, ENEMY_PUBLIC_IP, ENEMY_PUBLIC_PORT);
      //CLIENT_UDP_PRIVATE_SOCKET.send(SEND_PACKET);
    }
    catch(Exception e) {
      println("client: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
      println(e);
      NOTIFY_PUNCHING_FAILED(INCOMING_ENEMY_UUID);
    }
  }
  catch(Exception e) {
    println("client: failed to punch hole! (yikes) Notifying server...");
    println(e);
    NOTIFY_PUNCHING_FAILED(INCOMING_ENEMY_UUID);
  }
  finally {
    try {
      CLIENT_UDP_PRIVATE_SOCKET.close();
    }
    catch(Exception e) {
    }
  }
}

DatagramSocket attempUDPconnection(String CONNECTION_NAME, int LOCAL_PORT, String REMOTE_IPS_STRING, InetAddress[] REMOTE_IPS, int REMOTE_PORT, int TIMEOUT, int SLEEPTIME) {
  DatagramSocket socket = null;
  try {
    if (DEBUG_PUNCHING) println();
    if (DEBUG_PUNCHING) println("client: attempting to connnect over "+CONNECTION_NAME+" "+REMOTE_IPS_STRING+" / "+REMOTE_PORT);
    if (DEBUG_PUNCHING) printArray(REMOTE_IPS);
    try {
      socket = new DatagramSocket(LOCAL_PORT);
      socket.setSoTimeout(TIMEOUT); // What is an acceptable ping on LAN? (Wifi?)
      //CLIENT_UDP_PRIVATE_SOCKET.connect(REMOTE_IP, REMOTE_PORT);
    }
    catch(Exception e) {
      println("client: failed to open local port "+LOCAL_PORT);
      throw new Exception();
    }
    if (DEBUG_PUNCHING)  println("client: socket open on local port "+LOCAL_PORT);

    // wait for a bit, to make sure the other party has had time to set up their socket...
    Thread.sleep(SLEEPTIME);

    if (DEBUG_PUNCHING) println("client: waking up, sending packet to "+REMOTE_IPS_STRING+" / "+REMOTE_PORT);
    int RECEPTION_LEVEL = -1;
    InetAddress REMOTE_IP_CONFIRMED = null;
    while (RECEPTION_LEVEL < 1) {
      byte[] sendData = new byte[1];
      sendData[0] = (byte)(RECEPTION_LEVEL+1);
      DatagramPacket SEND_PACKET = new DatagramPacket(sendData, sendData.length);
      DatagramPacket receivePacket = new DatagramPacket(new byte[1], 1);
      boolean received = false;
      for (int i = 0; i < 10; i++) {
        try {
          if (REMOTE_IP_CONFIRMED != null) {
            if (DEBUG_PUNCHING) println("client: pinging to confirmed: "+REMOTE_IP_CONFIRMED);
            socket.send(SEND_PACKET);
          } else {
            for (int ip = 0; ip < REMOTE_IPS.length; ip++) {
              if (DEBUG_PUNCHING) println("client: pinging to "+REMOTE_IPS[ip]);
              SEND_PACKET.setAddress(REMOTE_IPS[ip]);
              SEND_PACKET.setPort(REMOTE_PORT);
              socket.send(SEND_PACKET);
            }
          }
        }
        catch (Exception e) {
          println("client: "+CONNECTION_NAME+" failed to send packet");
          throw new Exception();
        }
        try {
          socket.receive(receivePacket);
          if (REMOTE_IP_CONFIRMED == null) {
            REMOTE_IP_CONFIRMED = receivePacket.getAddress();
            if (DEBUG_PUNCHING) println("client: Enemy responded! from ip :"+REMOTE_IP_CONFIRMED);
            if (receivePacket.getPort() != REMOTE_PORT) {
              REMOTE_PORT = receivePacket.getPort();
              if (DEBUG_PUNCHING) println("client: Response comes from an unexpected port! ("+REMOTE_PORT+") Possible second NAT on network? Attempting to continue.");
            }
            socket.connect(REMOTE_IP_CONFIRMED, REMOTE_PORT);
          }
          received = true;
          break;
        }
        catch(Exception e) {
          if (DEBUG_PUNCHING) print("-");
        }
      }
      if (!received) {
        println("client: Enemy timed out");
        throw new Exception();
      }
      RECEPTION_LEVEL = receivePacket.getData()[0];
      if (DEBUG_PUNCHING) println("client: RECEPTION_LEVEL: "+RECEPTION_LEVEL);
      if (RECEPTION_LEVEL != 0) RECEPTION_LEVEL = 1;
    }

    if (DEBUG_PUNCHING) println("client: "+CONNECTION_NAME+" Hole successfully punched!");
    return socket;
  }
  catch(Exception e) {
    println("client: Failed to connect over "+CONNECTION_NAME);
    socket.close();
    return null;
  }
}


void readNetwork() {
  if (client.available()>0) {
    if (DEBUG_PACKETS) println("client: Reading "+client.available()+" bytes from TCP server");
    // Processing's methods for reading from server is not great
    // I'm using nio.ByteBuffer instead.
    // My concern is that in one 'client.available' session, there could
    // be some leftover data for the next packet, which we don't want to
    // discard. So all the data goes into a global 'server_data' ByteBuffer,
    // to which data is added successively, here.
    byte[] data_from_network = new byte[client.available()];
    client.readBytes(data_from_network);
    byte[] data_from_buffer = network_data.array();
    byte[] data_combined = new byte[data_from_network.length + data_from_buffer.length - network_data.position()];
    System.arraycopy(data_from_buffer, network_data.position(), data_combined, 0, data_from_buffer.length - network_data.position());
    System.arraycopy(data_from_network, 0, data_combined, data_from_buffer.length - network_data.position(), data_from_network.length);
    network_data = ByteBuffer.wrap(data_combined);
  }
}

int getExternalPort(DatagramSocket socket) throws Exception {
  // Use a well know STUN server to discover what the external port of 'socket' is
  byte[] data = new byte[20];
  data[0] = (byte) 0; // STUN Message Type
  data[1] = (byte) 1;
  data[2] = (byte) 0; // Message Length
  data[3] = (byte) 0;
  InetAddress STUNserver = null;
  try {
    STUNserver = InetAddress.getByName("stun.l.google.com");
    socket.setSoTimeout(1000);
  }
  catch (Exception e) {
    println("client: Could not resolve the address of stun.l.google.com!");
    println(e);
    throw e;
  }
  for (int i = 4; i < 20; i++) data[i] = (byte) random(0, 255);
  DatagramPacket packet = new DatagramPacket(data, data.length, STUNserver, 19302);
  DatagramPacket receive = new DatagramPacket(new byte[1024], 1024);

  for (int i = 0; i < 10; i++) {
    try {
      socket.send(packet);
      socket.receive(receive);
      int external_port = (receive.getData()[26] & 0xff) << 8 | (receive.getData()[27] & 0xff);
      return external_port;
    }
    catch(Exception e) { // retry
    }
  }
  throw new Exception("client: ERROR finding external port; too many attempts to contact stun.l.google.com failed");
}

// copy pasted off stack overflow. THX!
// https://stackoverflow.com/questions/9481865/getting-the-ip-address-of-the-current-machine-using-java
Object[] GET_PRIVATE_IP() {
  try {
    ArrayList<InetAddress> validAddresses = new ArrayList<InetAddress>();
    ArrayList<InetAddress> candidateAddress = new ArrayList<InetAddress>();
    // Iterate all NICs (network interface cards)...
    for (Enumeration ifaces = NetworkInterface.getNetworkInterfaces(); ifaces.hasMoreElements(); ) {
      NetworkInterface iface = (NetworkInterface) ifaces.nextElement();
      // Iterate all IP addresses assigned to each card...
      for (Enumeration inetAddrs = iface.getInetAddresses(); inetAddrs.hasMoreElements(); ) {
        InetAddress inetAddr = (InetAddress) inetAddrs.nextElement();
        if (!inetAddr.isLoopbackAddress()) {
          if (inetAddr.isSiteLocalAddress()) {
            // Found non-loopback site-local address. (Return it immediately...?)
            validAddresses.add(inetAddr);
          } else {
            // Found non-loopback address, but not necessarily site-local.
            // Store it as a candidate to be returned if site-local address is not subsequently found...
            candidateAddress.add(inetAddr);
            // Note that we don't repeatedly assign non-loopback non-site-local addresses as candidates,
            // only the first. For subsequent iterations, candidate will be non-null.
          }
        }
      }
    }
    if (!validAddresses.isEmpty()) {
      return validAddresses.toArray();
    }
    if (candidateAddress.isEmpty()) {
      // We did not find a site-local address, but we found some other non-loopback address.
      // Server might have a non-site-local address assigned to its NIC (or it might be running
      // IPv6 which deprecates the "site-local" concept).
      // Return this non-loopback candidate address...
      return candidateAddress.toArray();
    }
    // At this point, we did not find a non-loopback address.
    // Fall back to returning whatever InetAddress.getLocalHost() returns...
    InetAddress jdkSuppliedAddress = InetAddress.getLocalHost();
    if (jdkSuppliedAddress == null) {
      throw new UnknownHostException("The JDK InetAddress.getLocalHost() method unexpectedly returned null.");
    }
    return new InetAddress[]{jdkSuppliedAddress};
  }
  catch(Exception e) {
    return null;
  }
}

void putString(ByteBuffer data, String str) {
  data.putInt(str.length());
  for (int i = 0; i < str.length(); i++) data.putChar(str.charAt(i));
}

String getString(ByteBuffer data) {
  int len = data.getInt();
  String msg = "";
  for (int i = 0; i < len; i++) msg += data.getChar();
  return msg;
}
