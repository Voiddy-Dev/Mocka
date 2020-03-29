import java.nio.ByteBuffer;

Client client;
UDP udp;

// TCP

void clientEvent(Client someClient) {
  UUID = client.read();
  
  println("UUID: "  + UUID);
}


// UDP

// This handler is necessary for UDP
// void receive( byte[] data ) {       // <-- default handler
void receive( byte[] data, String ip, int port ) {  // <-- extended handler
  String message = new String( data );

  // print the result
  println( "receive: \""+message+"\" from "+ip+" on port "+port );
}

String serv_ip_udp = "localhost";  // the remote IP address
int serv_port_udp = 6000;    // the destination port

// Reminder a float is 4 bytes
void send_udp_to_server() {
  // 4 bytes for x
  // 4 bytes for y
  // 4 bytes for angle
  // 1 byte for UUID
  // = 13 bytes
  byte[] message = new byte[13];
  byte[] msg_x = float2ByteArray(rock.pos.x);
  byte[] msg_y = float2ByteArray(rock.pos.y);
  byte[] msg_angle = float2ByteArray(rock.posRot);
  System.arraycopy(msg_x, 0, message, 0, 4); // copy first 4 bytes
  System.arraycopy(msg_y, 0, message, 4, 4);
  System.arraycopy(msg_angle, 0, message, 8, 4);
  if (UUID >= 0 && UUID <= 255) message[12] = (byte) UUID;
  else message[12] = -1;
  
  // Send the message now
  udp.send(message, serv_ip_udp, serv_port_udp);
}

// I <3 StackOverflow
public static byte[] float2ByteArray (float value) {  
  return ByteBuffer.allocate(4).putFloat(value).array();
}

public static float convertToFloat(byte[] array) {
  ByteBuffer buffer = ByteBuffer.wrap(array);
  return buffer.getFloat();
}
