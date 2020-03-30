import java.nio.ByteBuffer;

UDP udp;

int UDP_CLIENT_PORT = 16441;

// This handler is necessary for UDP
// void receive( byte[] data ) {       // <-- default handler
void receive( byte[] data, String ip, int port ) {  // <-- extended handler
  float rocket_x = convertToFloat(subset(data, 0, 4));
  float rocket_y = convertToFloat(subset(data, 4, 4));
  float rocket_ang = convertToFloat(subset(data, 8, 4));

  int senderUUID = (int) data[12];

  udp.send(createPongMessage(rocket_x, rocket_y, rocket_ang, senderUUID), ip, port);
}

byte[] createPongMessage(float rX, float rY, float rAng, int sUUID) {
  // 13 bytes for each player except the one sending the message
  byte[] ret = new byte[13 * (players.size())];
  int index = 0;
  for (Player p : players) {
    if (p.UUID == sUUID) { // i
      p.setValues(rX, rY, rAng);
    }

    byte[] pMsg = p.createByteArray(); 
    System.arraycopy(pMsg, 0, ret, index, 13);

    index += 13;
  }

  //println(ret.length);

  return ret;
}

public static float convertToFloat(byte[] array) {
  ByteBuffer buffer = ByteBuffer.wrap(array);
  return buffer.getFloat();
}


// TESTING STUFF
PShape rocketBody;

void setupRocketBody() {
  rocketBody = createShape();
  rocketBody.beginShape();
  rocketBody.noFill();
  rocketBody.strokeWeight(0.1);
  rocketBody.stroke(0);
  //rocketBody.vertex(0, POINT_HEIGHT);
  //rocketBody.vertex(LEGS_WIDTH, LEGS_HEIGHT);
  //rocketBody.vertex(-LEGS_WIDTH, LEGS_HEIGHT);
  rocketBody.vertex(-.6, -1.3);
  rocketBody.vertex(-.5, -1.5);
  rocketBody.vertex(0, -1.8);
  rocketBody.vertex(.5, -1.5);
  rocketBody.vertex(.6, -1.3);
  rocketBody.vertex(1.2, .7);
  rocketBody.vertex(.9, 1.8);
  rocketBody.vertex(-.9, 1.8);
  rocketBody.vertex(-1.2, .7);
  rocketBody.endShape(CLOSE);
  rocketBody.scale(10);
}

// I <3 StackOverflow
public static byte[] float2ByteArray (float value) {  
  return ByteBuffer.allocate(4).putFloat(value).array();
}
