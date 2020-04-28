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
