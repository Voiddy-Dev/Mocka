import processing.net.*;
import hypermedia.net.*;
import java.nio.ByteBuffer;

int UUID = -1;

String serv_ip = "lmhleetmcgang.ddns.net";  // the remote IP address

HashMap<Integer, Enemy> enemies = new HashMap();

Client client;
UDP udp;

int MAX_PACKET_LENGTH = 30;

void setupNetworking() {
  // setting up 
  client = new Client(this, serv_ip, 25567);

  // create a new datagram connection on port 6100
  // and wait for incomming message
  udp = new UDP(this, 16441);
  //udp.log(true);     // <-- printout the connection activity
  udp.listen( true );
}

// TCP
void clientEvent(Client someClient) {
  int data = client.read();
  if (UUID == -1) {
    UUID = data;
    println("UUID: "  + UUID);
  } else {
    enemies.remove(data);
  }
}

// UDP

void parseUDPData(byte[] data) {
  int nb = data.length / MAX_PACKET_LENGTH;

  int index = 0;
  for (int i = 0; i < nb; i ++) {
    float rocket_x = convertToFloat(subset(data, index, 4));
    float rocket_y = convertToFloat(subset(data, index + 4, 4));
    float rocket_ang = convertToFloat(subset(data, index + 8, 4));

    //println(rocket_x, rocket_y, rocket_ang);

    int senderUUID = (int) data[index + 12];
    int sup = (int) data[index + 13];

    float rocket_acc_x = convertToFloat(subset(data, index + 14, 4));
    float rocket_acc_y = convertToFloat(subset(data, index + 18, 4));

    float rocket_vel_x = convertToFloat(subset(data, index + 22, 4));
    float rocket_vel_y = convertToFloat(subset(data, index + 26, 4));

    // checks if we already know this enemy 
    if (enemies.containsKey(senderUUID)) {
      // update its values if we do know the enemy
      enemies.get(senderUUID).setValues(rocket_x, rocket_y, rocket_ang, sup, rocket_acc_x, rocket_acc_y, rocket_vel_x, rocket_vel_y);
    } else {
      // create the new enemy if we dont know
      Enemy newEnemy = new Enemy(senderUUID);
      newEnemy.setValues(rocket_x, rocket_y, rocket_ang, sup, rocket_acc_x, rocket_acc_y, rocket_vel_x, rocket_vel_y);
      enemies.put(senderUUID, newEnemy);
    } 

    index += MAX_PACKET_LENGTH;
  }
}

// This handler is necessary for UDP
// void receive( byte[] data ) {       // <-- default handler
void receive( byte[] data, String ip, int port ) {  // <-- extended handler
  //println("--");
  if (data.length != 0 && data.length % MAX_PACKET_LENGTH == 0) {
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
  // = MAX_PACKET_LENGTH bytes
  byte[] message = new byte[MAX_PACKET_LENGTH];
  byte[] msg_x = float2ByteArray(rock.body.getPosition().x);
  byte[] msg_y = float2ByteArray(rock.body.getPosition().y);
  byte[] msg_angle = float2ByteArray(rock.body.getAngle());
  System.arraycopy(msg_x, 0, message, 0, 4); // copy first 4 bytes
  System.arraycopy(msg_y, 0, message, 4, 4);
  System.arraycopy(msg_angle, 0, message, 8, 4);
  if (UUID >= 0 && UUID <= 255) message[12] = (byte) UUID;
  else message[12] = -1;

  if (up) message[13] = 0;
  else message[13] = 1;

  //byte[] msg_acc_x = float2ByteArray(rock.acc.x); // 4 bytes
  //byte[] msg_acc_y = float2ByteArray(rock.acc.y); // 4
  //byte[] msg_vel_x = float2ByteArray(rock.vel.x); // 4
  //byte[] msg_vel_y = float2ByteArray(rock.vel.y); // 4
  //System.arraycopy(msg_acc_x, 0, message, 14, 4);
  //System.arraycopy(msg_acc_y, 0, message, 18, 4);
  //System.arraycopy(msg_vel_x, 0, message, 22, 4);
  //System.arraycopy(msg_vel_y, 0, message, 26, 4);

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
