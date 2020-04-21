import java.nio.ByteBuffer;

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

ByteBuffer PLEASE_OPEN_UDP(int port) {
  ByteBuffer data = ByteBuffer.allocate(5);
  data.put((byte)2);
  data.putInt(port);
  return data;
}
