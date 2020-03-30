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
  float acc_x = -1, acc_y = -1;
  float vel_x = -1, vel_y = -1;
  int up;

  Player(Client client_) {
    client = client_;
    UUID = UUID_available;
    UUID_available++;
  }

  void setValues(float x, float y, float ang, int sup, float acc_x, float acc_y, float vel_x, float vel_y) {
    this.x = x;
    this.y = y;
    this.ang = ang;
    this.up = sup;
    this.acc_x = acc_x;
    this.acc_y = acc_y;
    this.vel_x = vel_x;
    this.vel_y = vel_y;
  }

  // 4 btyes per float
  byte[] createByteArray() {
    byte[] message = new byte[MAX_PACKET_LENGTH];
    byte[] msg_x = float2ByteArray(this.x);
    byte[] msg_y = float2ByteArray(this.y);
    byte[] msg_angle = float2ByteArray(this.ang);
    System.arraycopy(msg_x, 0, message, 0, 4); // copy first 4 bytes
    System.arraycopy(msg_y, 0, message, 4, 4);
    System.arraycopy(msg_angle, 0, message, 8, 4);
    if (UUID >= 0 && UUID <= 255) message[12] = (byte) UUID;
    else message[12] = -1;

    message[13] = (byte) up;

    byte[] msg_acc_x = float2ByteArray(this.acc_x); // 4 bytes
    byte[] msg_acc_y = float2ByteArray(this.acc_y); // 4
    byte[] msg_vel_x = float2ByteArray(this.vel_x); // 4
    byte[] msg_vel_y = float2ByteArray(this.vel_y); // 4
    System.arraycopy(msg_acc_x, 0, message, 14, 4);
    System.arraycopy(msg_acc_y, 0, message, 18, 4);
    System.arraycopy(msg_vel_x, 0, message, 22, 4);
    System.arraycopy(msg_vel_y, 0, message, 26, 4);

    return message;
  }

  void update() {
  }
}
