import java.nio.ByteBuffer;

HashMap<Integer, Enemy> enemies = new HashMap();

Client client;
UDP udp;

// TCP
void clientEvent(Client someClient) {
  UUID = client.read();

  println("UUID: "  + UUID);
}

// UDP

void parseUDPData(byte[] data) {
  int nb = data.length / 13;

  int index = 0;
  for (int i = 0; i < nb; i ++) {
    float rocket_x = convertToFloat(subset(data, index, 4));
    float rocket_y = convertToFloat(subset(data, index + 4, 4));
    float rocket_ang = convertToFloat(subset(data, index + 8, 4));

    println(rocket_x, rocket_y, rocket_ang);

    int senderUUID = (int) data[index + 12];

    println("UUID:", senderUUID);

    // checks if we already know this enemy 
    if (enemies.containsKey(senderUUID)) {
      // update its values if we do know the enemy
      enemies.get(senderUUID).setValues(rocket_x, rocket_y, rocket_ang);
    } else {
      // create the new enemy if we dont know
      Enemy newEnemy = new Enemy(senderUUID);
      newEnemy.setValues(rocket_x, rocket_y, rocket_ang);
      enemies.put(senderUUID, newEnemy);
    } 

    index += 13;
  }
}

// This handler is necessary for UDP
// void receive( byte[] data ) {       // <-- default handler
void receive( byte[] data, String ip, int port ) {  // <-- extended handler
  println("--");
  if (data.length != 0 && data.length % 13 == 0) {
    parseUDPData(data);
  } else {
    println("ERROR IN UDP RECEIVE");
  }
}

int serv_port_udp = 16440;    // the destination port

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
  udp.send(message, serv_ip, serv_port_udp);
}

// I <3 StackOverflow
public static byte[] float2ByteArray (float value) {  
  return ByteBuffer.allocate(4).putFloat(value).array();
}

public static float convertToFloat(byte[] array) {
  ByteBuffer buffer = ByteBuffer.wrap(array);
  return buffer.getFloat();
}
