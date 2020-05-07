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
  still_punching = true;
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
    H_player_a.TCP_SEND(NOTIFY_OPEN_UDP(SERVER_UDP_PORT_A_WAN, H_player_b.UUID));
    H_player_b.TCP_SEND(NOTIFY_OPEN_UDP(SERVER_UDP_PORT_B_WAN, H_player_a.UUID));

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
    int A_PUBLIC_PORT_STUN, B_PUBLIC_PORT_STUN;
    InetAddress[] A_PRIVATE_IPS, B_PRIVATE_IPS;
    String A_PRIVATE_IPS_STRING, B_PRIVATE_IPS_STRING;
    try {
      String[] splitResponseA = new String(receivePacketA.getData()).split("-");
      String[] splitResponseB = new String(receivePacketB.getData()).split("-");
      A_PRIVATE_IPS_STRING = splitResponseA[0];
      B_PRIVATE_IPS_STRING = splitResponseB[0];
      printArray(splitResponseA);
      printArray(splitResponseB);
      String[] A_PRIVATE_IPS_SPLIT = A_PRIVATE_IPS_STRING.split(";");
      String[] B_PRIVATE_IPS_SPLIT = B_PRIVATE_IPS_STRING.split(";");
      printArray(A_PRIVATE_IPS_SPLIT);
      printArray(B_PRIVATE_IPS_SPLIT);
      A_PRIVATE_IPS = new InetAddress[A_PRIVATE_IPS_SPLIT.length];
      B_PRIVATE_IPS = new InetAddress[B_PRIVATE_IPS_SPLIT.length];
      for (int i = 0; i < A_PRIVATE_IPS.length; i++) A_PRIVATE_IPS[i] = InetAddress.getByName(A_PRIVATE_IPS_SPLIT[i].substring(1));
      for (int i = 0; i < B_PRIVATE_IPS.length; i++) B_PRIVATE_IPS[i] = InetAddress.getByName(B_PRIVATE_IPS_SPLIT[i].substring(1));
      printArray(A_PRIVATE_IPS);
      printArray(B_PRIVATE_IPS);
      A_PRIVATE_PORT = Integer.parseInt(splitResponseA[1]);
      B_PRIVATE_PORT = Integer.parseInt(splitResponseB[1]);
      A_PUBLIC_PORT_STUN = Integer.parseInt(splitResponseA[2]);
      B_PUBLIC_PORT_STUN = Integer.parseInt(splitResponseB[2]);
    } 
    catch(Exception e) {
      println("SERVER: ERROR: could not convert private IP of player to InetAddress");
      println(e);
      throw new Exception();
    }
    boolean A_IS_LOCAL = isIPaGateway(A_PUBLIC_IP);
    boolean B_IS_LOCAL = isIPaGateway(B_PUBLIC_IP);
    InetAddress A_PUBLIC_IP_ = A_IS_LOCAL ? WAN : A_PUBLIC_IP;
    InetAddress B_PUBLIC_IP_ = B_IS_LOCAL ? WAN : B_PUBLIC_IP;
    if (!A_IS_LOCAL && A_PUBLIC_PORT != A_PUBLIC_PORT_STUN) println("SERVER: A's public and STUN ports don't match up! I don't know which port to use for remote so yikes. (public/STUN: "+A_PUBLIC_PORT+" / "+A_PUBLIC_PORT_STUN+")");
    if (!B_IS_LOCAL && B_PUBLIC_PORT != B_PUBLIC_PORT_STUN) println("SERVER: B's public and STUN ports don't match up! I don't know which port to use for remote so yikes. (public/STUN: "+B_PUBLIC_PORT+" / "+B_PUBLIC_PORT_STUN+")");
    int A_PUBLIC_PORT_ADVERTISED = A_IS_LOCAL ? A_PUBLIC_PORT_STUN : A_PUBLIC_PORT;
    int B_PUBLIC_PORT_ADVERTISED = B_IS_LOCAL ? B_PUBLIC_PORT_STUN : B_PUBLIC_PORT;

    println();
    println("SERVER: A private: "+A_PRIVATE_IPS_STRING+":"+A_PRIVATE_PORT);
    println("SERVER: A public:  "+A_PUBLIC_IP+":"+A_PUBLIC_PORT);
    println();
    println("SERVER: B private: "+B_PRIVATE_IPS_STRING+":"+B_PRIVATE_PORT);
    println("SERVER: B public:  "+B_PUBLIC_IP+":"+B_PUBLIC_PORT);
    println();

    String locdataA = A_PUBLIC_IP_ + "-" + A_PUBLIC_PORT_ADVERTISED + "-" + A_PRIVATE_IPS_STRING + "-" + A_PRIVATE_PORT + "-" + (B_IS_LOCAL ? 1 : 0) + "-" + (A_IS_LOCAL ? 1 : 0) + "-";
    String locdataB = B_PUBLIC_IP_ + "-" + B_PUBLIC_PORT_ADVERTISED + "-" + B_PRIVATE_IPS_STRING + "-" + B_PRIVATE_PORT + "-" + (A_IS_LOCAL ? 1 : 0) + "-" + (B_IS_LOCAL ? 1 : 0) + "-";

    try {
      UDP_SOCKET_A.send(new DatagramPacket(locdataB.getBytes(), locdataB.getBytes().length, A_PUBLIC_IP, A_PUBLIC_PORT));
      UDP_SOCKET_B.send(new DatagramPacket(locdataA.getBytes(), locdataA.getBytes().length, B_PUBLIC_IP, B_PUBLIC_PORT));

      UDP_SOCKET_A.close();
      UDP_SOCKET_B.close();
    } 
    catch (Exception e) {
      println("SERVER: error: could not send data thru UDP when punching holes...");
      println(e);
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
  still_punching = false;
  println("SERVER: no longer punching");
}
