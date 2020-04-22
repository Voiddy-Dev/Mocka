Set<Long> pending_holes = new HashSet<Long>();

void note_missing_hole(int UUID_a_, int UUID_b_) {
  int UUID_a = min(UUID_a_, UUID_b_);
  int UUID_b = max(UUID_a_, UUID_b_);
  long hole = ((long)UUID_a << 32) | (long)UUID_b;
  pending_holes.add(hole);
}

void updateHoles() {
  if (pending_holes.isEmpty()) return;
  if (still_punching) return;
  long hole = pending_holes.iterator().next();
  pending_holes.remove(hole);
  int UUID_a_ = (int) (hole >> 32) & 0xffffff; 
  int UUID_b_ = (int) hole & 0xffffffff;
  int UUID_a, UUID_b;
  if (random(1) < 0.5) {
    UUID_a = UUID_a_;
    UUID_b = UUID_b_;
  } else {
    UUID_a = UUID_b_;
    UUID_b = UUID_a_;
  }
  H_player_a = players.get(UUID_a);
  H_player_b = players.get(UUID_b);
  thread("punch_hole");
}

boolean still_punching;
Player H_player_a, H_player_b;

/**
 * Created by luka on 29.1.16..
 */

void punch_hole() {
  DatagramSocket UDP_SOCKET_A = null, UDP_SOCKET_B = null;
  try {
    try {
      UDP_SOCKET_A = new DatagramSocket(SERVER_UDP_PORT_A_LAN);
      UDP_SOCKET_B = new DatagramSocket(SERVER_UDP_PORT_B_LAN);
    } 
    catch(Exception e) {
      println("SERVER: ERROR: failed to open port "+SERVER_UDP_PORT_A_LAN+" / "+SERVER_UDP_PORT_B_LAN);
      throw new Exception();
    } 
    H_player_a.TCP_SEND(PLEASE_OPEN_UDP(SERVER_UDP_PORT_A_WAN));
    H_player_b.TCP_SEND(PLEASE_OPEN_UDP(SERVER_UDP_PORT_B_WAN));

    DatagramPacket receivePacketA = new DatagramPacket(new byte[1024], 1024);
    DatagramPacket receivePacketB = new DatagramPacket(new byte[1024], 1024);
    try {
      UDP_SOCKET_A.receive(receivePacketA);
      UDP_SOCKET_B.receive(receivePacketB);
    } 
    catch(Exception e) {
      println("SERVER: ERROR: could not receive... timeout?");
      throw new Exception();
    }

    InetAddress A_PUBLIC_IP = receivePacketA.getAddress();
    InetAddress B_PUBLIC_IP = receivePacketB.getAddress();
    int A_PUBLIC_PORT = receivePacketA.getPort();
    int B_PUBLIC_PORT = receivePacketB.getPort();

    int A_PRIVATE_PORT, B_PRIVATE_PORT;
    InetAddress A_PRIVATE_IP, B_PRIVATE_IP;
    try {
      String[] splitResponseA = new String(receivePacketA.getData()).split("-");
      String[] splitResponseB = new String(receivePacketB.getData()).split("-");
      A_PRIVATE_IP = InetAddress.getByName(splitResponseA[0].substring(1));
      B_PRIVATE_IP = InetAddress.getByName(splitResponseB[0].substring(1));
      A_PRIVATE_PORT = Integer.parseInt(splitResponseA[1]);
      B_PRIVATE_PORT = Integer.parseInt(splitResponseB[1]);
    } 
    catch(Exception e) {
      println("SERVER: ERROR: could not convert private IP of player to InetAddress");
      throw new Exception();
    }
    boolean A_IS_LOCAL = A_PUBLIC_IP.equals(GATEWAY);
    boolean B_IS_LOCAL = B_PUBLIC_IP.equals(GATEWAY);

    println();
    println("SERVER: A private: "+A_PRIVATE_IP+":"+A_PRIVATE_PORT);
    println("SERVER: A public:  "+A_PUBLIC_IP+":"+A_PUBLIC_PORT);
    println();
    println("SERVER: B private: "+B_PRIVATE_IP+":"+B_PRIVATE_PORT);
    println("SERVER: B public:  "+B_PUBLIC_IP+":"+B_PUBLIC_PORT);
    println();

    String locdataA = A_PUBLIC_IP + "-" + A_PUBLIC_PORT + "-" + A_PRIVATE_IP + "-" + A_PRIVATE_PORT + "-" + (B_IS_LOCAL ? 1 : 0) + "-" + (A_IS_LOCAL ? 1 : 0) + "-";
    String locdataB = B_PUBLIC_IP + "-" + B_PUBLIC_PORT + "-" + B_PRIVATE_IP + "-" + B_PRIVATE_PORT + "-" + (A_IS_LOCAL ? 1 : 0) + "-" + (B_IS_LOCAL ? 1 : 0) + "-";

    try {
      UDP_SOCKET_A.send(new DatagramPacket(locdataB.getBytes(), locdataB.getBytes().length, A_PUBLIC_IP, A_PUBLIC_PORT));
      UDP_SOCKET_B.send(new DatagramPacket(locdataA.getBytes(), locdataA.getBytes().length, B_PUBLIC_IP, B_PUBLIC_PORT));
      UDP_SOCKET_A.close();
      UDP_SOCKET_B.close();
    } 
    catch (Exception e) {
      println("SERVER: error: could not send data thru UDP when punching holes...");
      throw new Exception();
    }
    println("SERVER: punched A & B, socket closing");
  } 
  catch(Exception e) {
    println("Server: Failed to punch hole :(");
  } 
  finally {
    try {
      UDP_SOCKET_A.close();
    } 
    catch (Exception e) {
    }
    try {
      UDP_SOCKET_B.close();
    } 
    catch (Exception e) {
    }
  }
}
