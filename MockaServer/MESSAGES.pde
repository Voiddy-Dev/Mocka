import java.nio.ByteBuffer;

// Sending methods

void TCP_SEND_ALL_CLIENTS_EXCEPT(ByteBuffer buffer, int UUID) {
  byte[] data = buffer.array();
  for (Map.Entry entry : players.entrySet()) {
    Player p = (Player)entry.getValue();
    if (p.UUID != UUID) {
      p.TCP_CLIENT.write(data);
    }
  }
}

void TCP_SEND_ALL_CLIENTS(ByteBuffer buffer) {
  byte[] data = buffer.array();
  for (Map.Entry entry : players.entrySet()) {
    Player p = (Player)entry.getValue();
    p.TCP_CLIENT.write(data);
  }
}

// Packets

ByteBuffer NOTIFY_NEW_PLAYER(int UUID) {
  ByteBuffer data = ByteBuffer.allocate(5);
  data.put((byte)0);
  data.putInt(UUID);
  return data;
}

ByteBuffer NOTIFY_DED_PLAYER(int UUID) {
  ByteBuffer data = ByteBuffer.allocate(5);
  data.put((byte)1);
  data.putInt(UUID);
  return data;
}

ByteBuffer NOTIFY_OPEN_UDP(int port, int enemy_UUID) {
  ByteBuffer data = ByteBuffer.allocate(9);
  data.put((byte)2);
  data.putInt(port);
  data.putInt(enemy_UUID);
  return data;
}

ByteBuffer NOTIFY_YOUR_UUID(int UUID) {
  ByteBuffer data = ByteBuffer.allocate(5);
  data.put((byte)3);
  data.putInt(UUID);
  return data;
}

ByteBuffer NOTIFY_TERRAIN(PlatformInfo[] platforms) {
  ByteBuffer data = ByteBuffer.allocate(1+4+16*platforms.length);
  data.put((byte)4);
  writeTerrain(data, platforms);
  return data;
}

ByteBuffer NOTIFY_PLAYER_INFO(Player p) {
  ByteBuffer data = ByteBuffer.allocate(1 + 4 + 4 + 4+2*p.name.length());
  data.put((byte)5);
  data.putInt(p.UUID);
  data.putInt(p.col);
  putString(data, p.name);
  return data;
}

ByteBuffer NOTIFY_PLAYER_STATE(int UUID, State state) {
  ByteBuffer data = ByteBuffer.allocate(6);
  data.put((byte)6);
  data.putInt(UUID);
  data.put(State.getValue(state));
  return data;
}

ByteBuffer NOTIFY_CHAT(String msg) {
  ByteBuffer data = ByteBuffer.allocate(1+4+2*msg.length());
  data.put((byte)7);
  putString(data, msg);
  return data;
}

void putString(ByteBuffer data, String str) {
  data.putInt(str.length());
  for (int i = 0; i < str.length(); i++) data.putChar(str.charAt(i));
}

String getString(ByteBuffer data) {
  int len = data.getInt();
  String msg = "";
  for (int i = 0; i < len; i++) msg += data.getChar();
  return msg;
}
