import processing.net.*;
import java.nio.ByteBuffer;

import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.InetAddress;
import java.net.NetworkInterface;
import java.net.UnknownHostException;

import java.util.Enumeration;

int UUID = -1;

//String SERVER_IP = "192.168.0.17";
//String SERVER_IP = "192.168.0.1";
String SERVER_IP = "91.160.183.12";
//String SERVER_IP = "lmhleetmcgang.ddns.net";
int SERVER_TCP_PORT = 25567;
//int SERVER_TCP_PORT = 25567;

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
    println("client: PACKET: "+PACKET_ID);
    if (PACKET_ID == 0) NOTIFY_NEW_PLAYER();
    if (PACKET_ID == 1) NOTIFY_DED_PLAYER();
    if (PACKET_ID == 2) PLEASE_OPEN_UDP();
  }
}

void NOTIFY_NEW_PLAYER() {
  int new_UUID = network_data.getInt();
  Enemy enemy = new Enemy(width/2, height/2, new_UUID);
  enemies.put(new_UUID, enemy);
  println("client: new player notification, UUID: "+new_UUID);
}

void NOTIFY_DED_PLAYER() {
  int ded_UUID = network_data.getInt();
  enemies.remove(ded_UUID);
  println("client: player ded notification, UUID: "+ded_UUID);
}

int SERVER_UDP_PORT;

void PLEASE_OPEN_UDP() {
  SERVER_UDP_PORT = network_data.getInt();
  println("client: server asking for UDP hole-punching on server-port "+SERVER_UDP_PORT);
  thread("punch_hole");
}

void punch_hole() {
  DatagramSocket CLIENT_UDP_PRIVATE_SOCKET = null;
  try {
    CLIENT_UDP_PRIVATE_SOCKET = new DatagramSocket();
    InetAddress CLIENT_UDP_PRIVATE_IP = GET_PRIVATE_IP();
    int CLIENT_UDP_PRIVATE_PORT = CLIENT_UDP_PRIVATE_SOCKET.getLocalPort();

    println("client: UDP socket open on local IP/port: "+CLIENT_UDP_PRIVATE_IP+" / "+CLIENT_UDP_PRIVATE_PORT);
    byte[] sendData = (CLIENT_UDP_PRIVATE_IP+"-"+CLIENT_UDP_PRIVATE_PORT+"-").getBytes();
    DatagramPacket SEND_PACKET = new DatagramPacket(sendData, sendData.length, InetAddress.getByName(SERVER_IP), SERVER_UDP_PORT);
    CLIENT_UDP_PRIVATE_SOCKET.send(SEND_PACKET);

    DatagramPacket receivePacket = new DatagramPacket(new byte[1024], 1024);
    CLIENT_UDP_PRIVATE_SOCKET.receive(receivePacket);

    String[] splitResponse = new String(receivePacket.getData()).split("-");
    InetAddress ENEMY_PUBLIC_IP = InetAddress.getByName(splitResponse[0].substring(1));
    InetAddress ENEMY_PRIVATE_IP = InetAddress.getByName(splitResponse[2].substring(1));
    int ENEMY_PUBLIC_PORT = int(splitResponse[1]);
    int ENEMY_PRIVATE_PORT = int(splitResponse[3]);
    boolean CLIENT_IS_LOCAL = int(splitResponse[4]) == 1;
    boolean ENEMY_IS_LOCAL = int(splitResponse[5]) == 1;
    println("client: server has answered with enemy's location. btw, CLIENT_IS_LOCAL = "+CLIENT_IS_LOCAL);

    println("client: Enemy public  at "+ENEMY_PUBLIC_IP+" / "+ENEMY_PUBLIC_PORT);
    println("client: Enemy private at "+ENEMY_PRIVATE_IP+" / "+ENEMY_PRIVATE_PORT+" / on server LAN: "+ENEMY_IS_LOCAL);

    CLIENT_UDP_PRIVATE_SOCKET.close();

    if (CLIENT_IS_LOCAL == ENEMY_IS_LOCAL) {   
      attempUDPconnection("[LAN]", CLIENT_UDP_PRIVATE_PORT, ENEMY_PRIVATE_IP, ENEMY_PRIVATE_PORT, 1000, 100);
      attempUDPconnection("[WAN]", CLIENT_UDP_PRIVATE_PORT, ENEMY_PUBLIC_IP, ENEMY_PUBLIC_PORT, 5000, 1000);
    } else {
      //if (CLIENT_IS_LOCAL) attempUDPconnection("[WAN]", CLIENT_UDP_PRIVATE_PORT, ENEMY_PUBLIC_IP, ENEMY_PUBLIC_PORT, 5000, 1000);
      //else attemptAsymmetricUDPconnection("[WAN]", CLIENT_UDP_PRIVATE_PORT, ENEMY_PUBLIC_IP, 5000, 1000);
      attempUDPconnection("[WAN]", CLIENT_UDP_PRIVATE_PORT, ENEMY_PUBLIC_IP, ENEMY_PUBLIC_PORT, 5000, 1000);
    }

    //SEND_PACKET = new DatagramPacket(sendData, sendData.length, ENEMY_PUBLIC_IP, ENEMY_PUBLIC_PORT);
    //CLIENT_UDP_PRIVATE_SOCKET.send(SEND_PACKET);
  } 
  catch(Exception e) {
  } 
  finally {
    try {
      CLIENT_UDP_PRIVATE_SOCKET.close();
    } 
    catch(Exception e) {
    }
  }
}

void attempUDPconnection(String CONNECTION_NAME, int LOCAL_PORT, InetAddress REMOTE_IP, int REMOTE_PORT, int TIMEOUT, int SLEEPTIME) {
  DatagramSocket CLIENT_UDP_PRIVATE_SOCKET = null;
  try {
    println("client: attempting to connnect over "+CONNECTION_NAME+" "+REMOTE_IP+" / "+REMOTE_PORT);
    try {
      CLIENT_UDP_PRIVATE_SOCKET = new DatagramSocket(LOCAL_PORT);
      CLIENT_UDP_PRIVATE_SOCKET.setSoTimeout(TIMEOUT); // What is an acceptable ping on LAN? (Wifi?)
    } 
    catch(Exception e) {
      println("client: failed to open local port "+LOCAL_PORT);
      throw new Exception();
    }
    println("client: socket open on local port "+LOCAL_PORT);

    // wait for a bit, to make sure the other party has had time to set up their socket...
    Thread.sleep(SLEEPTIME);

    println("client: waking up, sending packet to "+REMOTE_IP+" / "+REMOTE_PORT);
    byte[] sendData = new byte[1];
    sendData[0] = (byte)0;
    DatagramPacket SEND_PACKET = new DatagramPacket(sendData, sendData.length, REMOTE_IP, REMOTE_PORT);
    try {
      CLIENT_UDP_PRIVATE_SOCKET.send(SEND_PACKET);
    }
    catch (Exception e) {
      println("client: "+CONNECTION_NAME+" failed to send packet");
      throw new Exception();
    }

    DatagramPacket receivePacket = new DatagramPacket(new byte[1024], 1024);
    receivePacket.setData(new byte[1]);
    try {
      CLIENT_UDP_PRIVATE_SOCKET.receive(receivePacket);
    } 
    catch(Exception e) {
      println("client: "+CONNECTION_NAME+" timed out...");
      throw new Exception();
    }
    if (receivePacket.getData()[0] != (byte)0) {
      println("client: "+CONNECTION_NAME+" Received data from enemy, but not what was expected...");
      println(receivePacket.getData()[0]);
      throw new Exception();
    }

    println("client: "+CONNECTION_NAME+" reached by enemy! Acknoledging...");
    sendData[0] = (byte)1;
    SEND_PACKET = new DatagramPacket(sendData, sendData.length, REMOTE_IP, REMOTE_PORT);
    try {
      CLIENT_UDP_PRIVATE_SOCKET.send(SEND_PACKET);
    }
    catch (Exception e) {
      println("client: "+CONNECTION_NAME+" failed to send packet");
      throw new Exception();
    }

    receivePacket.setData(new byte[1]);
    try {
      CLIENT_UDP_PRIVATE_SOCKET.receive(receivePacket);
    } 
    catch(Exception e) {
      println("client: "+CONNECTION_NAME+" timed out...");
      throw new Exception();
    }
    if (receivePacket.getData()[0] != ((byte)1)) {
      println("Received data from enemy on LAN, but not what was expected...");
      println(receivePacket.getData()[0]);
      throw new Exception();
    }
    println("client: "+CONNECTION_NAME+" LAN Enemy reached us and we reached enemy! Success!!!!!!!!!!!!!!");
    return; // do seomthing??
  } 
  catch(Exception e) {
    println("client: Failed to connect over "+CONNECTION_NAME);
    CLIENT_UDP_PRIVATE_SOCKET.close();
    return;
  }
}



void attemptAsymmetricUDPconnection(String CONNECTION_NAME, int LOCAL_PORT, InetAddress REMOTE_IP, int TIMEOUT, int SLEEPTIME) {
  DatagramSocket CLIENT_UDP_PRIVATE_SOCKET = null;
  try {
    println("client: performing asymmetric connection to "+CONNECTION_NAME+" "+REMOTE_IP);
    try {
      CLIENT_UDP_PRIVATE_SOCKET = new DatagramSocket(LOCAL_PORT);
      CLIENT_UDP_PRIVATE_SOCKET.setSoTimeout(TIMEOUT); // What is an acceptable ping on LAN? (Wifi?)
    } 
    catch(Exception e) {
      println("client: failed to open local port "+LOCAL_PORT);
      throw new Exception();
    }
    println("client: socket open on local port "+LOCAL_PORT);

    // wait for a bit, to make sure the other party has had time to set up their socket...
    Thread.sleep(SLEEPTIME);

    println("client: waking up, trying to read packets");
    DatagramPacket receivePacket = new DatagramPacket(new byte[1024], 1024);
    receivePacket.setData(new byte[1]);
    try {
      CLIENT_UDP_PRIVATE_SOCKET.receive(receivePacket);
    } 
    catch(Exception e) {
      println("client: "+CONNECTION_NAME+" timed out...");
      throw new Exception();
    }
    if (receivePacket.getData()[0] != (byte)0) {
      println("client: "+CONNECTION_NAME+" Received data from enemy, but not what was expected...");
      println(receivePacket.getData()[0]);
      throw new Exception();
    }
    int REMOTE_PORT = receivePacket.getPort();
    println("client: REMOTE_PORT: "+REMOTE_PORT);


    byte[] sendData = new byte[1];
    sendData[0] = (byte)0;
    DatagramPacket SEND_PACKET = new DatagramPacket(sendData, sendData.length, REMOTE_IP, REMOTE_PORT);
    try {
      CLIENT_UDP_PRIVATE_SOCKET.send(SEND_PACKET);
    }
    catch (Exception e) {
      println("client: "+CONNECTION_NAME+" failed to send packet");
      throw new Exception();
    }


    println("client: "+CONNECTION_NAME+" reached by enemy! Acknoledging...");
    sendData[0] = (byte)1;
    SEND_PACKET = new DatagramPacket(sendData, sendData.length, REMOTE_IP, REMOTE_PORT);
    try {
      CLIENT_UDP_PRIVATE_SOCKET.send(SEND_PACKET);
    }
    catch (Exception e) {
      println("client: "+CONNECTION_NAME+" failed to send packet");
      throw new Exception();
    }

    receivePacket.setData(new byte[1]);
    try {
      CLIENT_UDP_PRIVATE_SOCKET.receive(receivePacket);
    } 
    catch(Exception e) {
      println("client: "+CONNECTION_NAME+" timed out...");
      throw new Exception();
    }
    if (receivePacket.getData()[0] != ((byte)1)) {
      println("Received data from enemy on LAN, but not what was expected...");
      println(receivePacket.getData()[0]);
      throw new Exception();
    }
    println("client: "+CONNECTION_NAME+" LAN Enemy reached us and we reached enemy! Success!!!!!!!!!!!!!!");
    return; // do seomthing??
  } 
  catch(Exception e) {
    println("client: Failed to connect over "+CONNECTION_NAME);
    CLIENT_UDP_PRIVATE_SOCKET.close();
    return;
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

// copy pasted off stack overflow. THX!
// https://stackoverflow.com/questions/9481865/getting-the-ip-address-of-the-current-machine-using-java
InetAddress GET_PRIVATE_IP() {
  ArrayList<InetAddress> validAddresses = new ArrayList<InetAddress>();
  try {
    InetAddress candidateAddress = null;
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
          } else if (candidateAddress == null) {
            // Found non-loopback address, but not necessarily site-local.
            // Store it as a candidate to be returned if site-local address is not subsequently found...
            candidateAddress = inetAddr;
            // Note that we don't repeatedly assign non-loopback non-site-local addresses as candidates,
            // only the first. For subsequent iterations, candidate will be non-null.
          }
        }
      }
    }
    if (!validAddresses.isEmpty()) {
      return validAddresses.get(validAddresses.size()-1); // arbitrary return the last address (fixed things for one of my machines / big bodge, oops)
    }
    if (candidateAddress != null) {
      // We did not find a site-local address, but we found some other non-loopback address.
      // Server might have a non-site-local address assigned to its NIC (or it might be running
      // IPv6 which deprecates the "site-local" concept).
      // Return this non-loopback candidate address...
      return candidateAddress;
    }
    // At this point, we did not find a non-loopback address.
    // Fall back to returning whatever InetAddress.getLocalHost() returns...
    InetAddress jdkSuppliedAddress = InetAddress.getLocalHost();
    if (jdkSuppliedAddress == null) {
      throw new UnknownHostException("The JDK InetAddress.getLocalHost() method unexpectedly returned null.");
    }
    return jdkSuppliedAddress;
  } 
  catch(Exception e) {
    return null;
  }
}
