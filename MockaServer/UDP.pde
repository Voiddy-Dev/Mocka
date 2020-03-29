import java.nio.ByteBuffer;

UDP udp;

float rocket_x = 0;
float rocket_y = 0;
float rocket_ang = 0;

// This handler is necessary for UDP
// void receive( byte[] data ) {       // <-- default handler
void receive( byte[] data, String ip, int port ) {  // <-- extended handler
  rocket_x = convertToFloat(subset(data, 0, 4));
  rocket_y = convertToFloat(subset(data, 4, 4));
  rocket_ang = convertToFloat(subset(data, 8, 4));

  //String message = "x: " + x + ", y: " + y + ", ang: " + ang;

  //// print the result
  //println( "receive: \""+message+"\" from "+ip+" on port "+port );
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
