ArrayList<Player> players;
int UUID_available = 0;

void updatePlayers() {  
  for (int i = players.size()-1; i >= 0; i--) {
    Player p = players.get(i);

    if (!p.client.active()) {
      players.remove(i);
    }
  }

  // Display connect UUID
  StringBuilder str = new StringBuilder();

  for (Player p : players) {
    str.append("Connected Client: ").append(p.client.ip());
    str.append(" - UUID: ").append(p.UUID);
    str.append("\n");
  }

  textSize(25);
  fill(0);
  text(str.toString(), 50, 50, width - 50, height - 50);
}

class Player {
  Client client;
  int UUID;
  float x = -1, y = -1, ang = -1;

  Player(Client client_) {
    client = client_;
    UUID = UUID_available;
    UUID_available++;
  }

  void setValues(float x, float y, float ang) {
    this.x = x;
    this.y = y;
    this.ang = ang;

    //println("Set: ", x, y, ang);
  }

  byte[] createByteArray() {
    // 4 bytes for x
    // 4 bytes for y
    // 4 bytes for angle
    // 1 byte for UUID
    // = 13 bytes
    byte[] message = new byte[13];
    byte[] msg_x = float2ByteArray(this.x);
    byte[] msg_y = float2ByteArray(this.y);
    byte[] msg_angle = float2ByteArray(this.ang);
    System.arraycopy(msg_x, 0, message, 0, 4); // copy first 4 bytes
    System.arraycopy(msg_y, 0, message, 4, 4);
    System.arraycopy(msg_angle, 0, message, 8, 4);
    if (UUID >= 0 && UUID <= 255) message[12] = (byte) UUID;
    else message[12] = -1;

    //println(message);

    return message;
  }

  void update() {
  }
}
