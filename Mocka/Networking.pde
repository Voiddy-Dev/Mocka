import processing.net.*;
import java.nio.ByteBuffer;

import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.InetAddress;
import java.net.NetworkInterface;
import java.net.UnknownHostException;

import java.util.Enumeration;

int MY_UUID = -1;

String SERVER_IP = "91.160.183.12";
//String SERVER_IP = "lmhleetmcgang.ddns.net";
int SERVER_TCP_PORT = 25567;

Client client;

void setupNetworking() {
  client = new Client(this, SERVER_IP, SERVER_TCP_PORT);
}

ByteBuffer network_data = ByteBuffer.allocate(0);

void updateNetwork() {
  readNetwork();
  interpretNetwork();
}

void interpretNetwork() {
  if (network_data.remaining()>0) {
    byte PACKET_ID = network_data.get();
    //println("client: received from tcp server PACKET_ID: "+PACKET_ID);
    if (PACKET_ID == 0) INTERPRET_NEW_PLAYER();
    if (PACKET_ID == 1) INTERPRET_DED_PLAYER();
    if (PACKET_ID == 2) INTERPRET_OPEN_UDP();
    if (PACKET_ID == 3) INTERPRET_YOUR_UUID();
  }
}

void INTERPRET_NEW_PLAYER() {
  int new_UUID = network_data.getInt();
  EnemyRocket enemy = new EnemyRocket(new_UUID);
  enemies.put(new_UUID, enemy);
  println("client: new player, UUID: "+new_UUID);
}

void INTERPRET_DED_PLAYER() {
  int ded_UUID = network_data.getInt();
  removeEnemy(ded_UUID);
  println("client: player ded, UUID: "+ded_UUID);
}

void INTERPRET_YOUR_UUID() {
  MY_UUID = network_data.getInt();
}

int SERVER_UDP_PORT;
int INCOMING_ENEMY_UUID;

void INTERPRET_OPEN_UDP() {
  SERVER_UDP_PORT = network_data.getInt();
  INCOMING_ENEMY_UUID = network_data.getInt();

  println("client: initiating hole punching for player "+INCOMING_ENEMY_UUID+" port "+SERVER_UDP_PORT);
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

    println("client: local UDP socket open IP / port: "+CLIENT_UDP_PRIVATE_IPS_STRING+" / "+CLIENT_UDP_PRIVATE_PORT+" / (STUN) "+CLIENT_UDP_PUBLIC_PORT);
    byte[] sendData = (CLIENT_UDP_PRIVATE_IPS_STRING+"-"+CLIENT_UDP_PRIVATE_PORT+"-"+CLIENT_UDP_PUBLIC_PORT+"-").getBytes();
    DatagramPacket SEND_PACKET = new DatagramPacket(sendData, sendData.length, InetAddress.getByName(SERVER_IP), SERVER_UDP_PORT);
    CLIENT_UDP_PRIVATE_SOCKET.send(SEND_PACKET);

    DatagramPacket receivePacket = new DatagramPacket(new byte[1024], 1024);
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
    println("client: server has answered with enemy's location. btw, CLIENT_IS_LOCAL = "+CLIENT_IS_LOCAL);

    println("client: Enemy public  at "+ENEMY_PUBLIC_IP+" / "+ENEMY_PUBLIC_PORT);
    println("client: Enemy private at "+ENEMY_PRIVATE_IPS_STRING+" / "+ENEMY_PRIVATE_PORT+" / on server LAN: "+ENEMY_IS_LOCAL);

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
    println("client: failed to punch hole");
    println(e);
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
    println();
    println("client: attempting to connnect over "+CONNECTION_NAME+" "+REMOTE_IPS_STRING+" / "+REMOTE_PORT);
    printArray(REMOTE_IPS);
    try {
      socket = new DatagramSocket(LOCAL_PORT);
      socket.setSoTimeout(TIMEOUT); // What is an acceptable ping on LAN? (Wifi?)
      //CLIENT_UDP_PRIVATE_SOCKET.connect(REMOTE_IP, REMOTE_PORT);
    } 
    catch(Exception e) {
      println("client: failed to open local port "+LOCAL_PORT);
      throw new Exception();
    }
    println("client: socket open on local port "+LOCAL_PORT);

    // wait for a bit, to make sure the other party has had time to set up their socket...
    Thread.sleep(SLEEPTIME);

    println("client: waking up, sending packet to "+REMOTE_IPS_STRING+" / "+REMOTE_PORT);
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
            println("client: pinging to confirmed: "+REMOTE_IP_CONFIRMED);
            socket.send(SEND_PACKET);
          } else {
            for (int ip = 0; ip < REMOTE_IPS.length; ip++) {
              println("client: pinging to "+REMOTE_IPS[ip]);
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
            println("client: Enemy responded! from ip :"+REMOTE_IP_CONFIRMED);
            if (receivePacket.getPort() != REMOTE_PORT) {
              REMOTE_PORT = receivePacket.getPort();
              println("client: Response comes from an unexpected port! ("+REMOTE_PORT+") Possible second NAT on network? Attempting to continue.");
            }
            socket.connect(REMOTE_IP_CONFIRMED, REMOTE_PORT);
          }
          received = true;
          break;
        } 
        catch(Exception e) {
          print("-");
        }
      }
      if (!received) {
        println("client: Enemy timed out");
        throw new Exception();
      }
      RECEPTION_LEVEL = receivePacket.getData()[0];
      println("client: RECEPTION_LEVEL: "+RECEPTION_LEVEL);
      if (RECEPTION_LEVEL != 0) RECEPTION_LEVEL = 1;
    }

    println("client: "+CONNECTION_NAME+" Hole successfully punched!");
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
    println("client: Reading "+client.available()+" bytes from TCP server");
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

int getExternalPort(DatagramSocket socket) {
  try {
    byte[] data = new byte[20];
    data[0] = (byte) 0; // STUN Message Type 
    data[1] = (byte) 1;
    data[2] = (byte) 0; // Message Length
    data[3] = (byte) 0;
    for (int i = 4; i < 20; i++) data[i] = (byte) random(0, 255);
    InetAddress STUNserver = InetAddress.getByName("stun.l.google.com");
    DatagramPacket packet = new DatagramPacket(data, data.length, STUNserver, 19302);
    socket.send(packet);

    socket.setSoTimeout(1000);
    DatagramPacket receive = new DatagramPacket(new byte[1024], 1024);
    socket.receive(receive);

    int port = (receive.getData()[26] & 0xff) << 8 | (receive.getData()[27] & 0xff);
    return port;
  } 
  catch(Exception e) {
    println(e);
    return 0;
  }
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
