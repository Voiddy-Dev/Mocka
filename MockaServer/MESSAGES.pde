import java.nio.ByteBuffer;

void TCP_SEND_ALL_CLIENTS_EXCEPT(ByteBuffer buffer, int UUID) {
  byte[] data = buffer.array();
  for (Map.Entry entry : players.entrySet()) {
    Player p = (Player)entry.getValue();
    if (p.UUID != UUID || true) {
      p.TCP_CLIENT.write(data);
    }
  }
}

void NOTIFY_NEW_PLAYER(int UUID) {
  ByteBuffer data = ByteBuffer.allocate(5);
  data.put((byte)0);
  data.putInt(UUID);
  TCP_SEND_ALL_CLIENTS_EXCEPT(data, UUID);
}
