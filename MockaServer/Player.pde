HashMap<Integer, Player> players = new HashMap<Integer, Player>();

int getFreeUUID() {
  int MAX_UUID = 256;
  int UUID;
  do {
    UUID = (int)random(MAX_UUID);
  } while (players.containsKey(UUID));
  return UUID;
}

void removeInactivePlayers() {
  Iterator<Map.Entry<Integer, Player>> iter = players.entrySet().iterator();
  while (iter.hasNext()) {
    Map.Entry<Integer, Player> entry = iter.next();
    Player p = entry.getValue();
    if (!p.TCP_CLIENT.active()) {
      if (p.state == STATE_IS_IT) SOMEONES_IT = false;
      iter.remove();
      TCP_SEND_ALL_CLIENTS(NOTIFY_DED_PLAYER(p.UUID));
      println("SERVER: player with UUID "+p.UUID+" is no longer active, disconnecting");
    }
  }
  if (!SOMEONES_IT && !players.isEmpty()) {
    iter = players.entrySet().iterator();
    Map.Entry<Integer, Player> entry = iter.next();
    Player p = entry.getValue();
    p.setState(STATE_IS_IT);
    SOMEONES_IT = true;
  }
}

void updatePlayers() {
  for (Map.Entry entry : players.entrySet()) {
    Player p = (Player)entry.getValue();
    p.updateNetwork();
  }
}

final byte STATE_NORMAL = 0;
final byte STATE_IS_IT = 1;

class Player {
  Client TCP_CLIENT;
  int UUID;
  color col = color(0);

  byte state = STATE_NORMAL;
  int imunity_counter = 0;

  Player(Client client_, int UUID_) {
    TCP_CLIENT = client_;
    UUID = UUID_;
    println("SERVER: new TCP connection. ip: "+TCP_CLIENT.ip()+" UUID: "+UUID);

    TCP_SEND(NOTIFY_YOUR_UUID(UUID));
    TCP_SEND(NOTIFY_TERRAIN(platforms));
    //note_missing_hole(UUID, UUID);
    // Notify this new player about all existing players
    for (Map.Entry entry : players.entrySet()) {
      Player p = (Player)entry.getValue();
      if (p.UUID != UUID) {
        TCP_SEND(NOTIFY_NEW_PLAYER(p.UUID));
        TCP_SEND(NOTIFY_PLAYER_COLOR(p.UUID, p.col));
        TCP_SEND(NOTIFY_PLAYER_STATE(p.UUID, p.state));
        note_missing_hole(UUID, p.UUID);
      }
    }
  }

  void setColor(color col) {
    this.col = col;
    TCP_SEND_ALL_CLIENTS_EXCEPT(NOTIFY_PLAYER_COLOR(UUID, col), UUID);
  }

  void setState(byte state) {
    println("SERVER: setting state of player "+UUID+" to "+state);
    this.state = state;
    TCP_SEND_ALL_CLIENTS(NOTIFY_PLAYER_STATE(UUID, state));
    if (state == STATE_IS_IT) imunity_counter = 30;
  }

  void TCP_SEND(ByteBuffer buf) {
    TCP_CLIENT.write(buf.array());
  }

  ByteBuffer network_data = ByteBuffer.allocate(0);

  void updateNetwork() {
    if (imunity_counter > 0) imunity_counter--;
    readNetwork();
    interpretNetwork();
  }

  void interpretNetwork() {
    if (network_data.remaining()>0) {
      byte PACKET_ID = network_data.get();
      println("SERVER: Reading packet from "+UUID+" PACKET: "+PACKET_ID);
      if (PACKET_ID == 0) setColor(network_data.getInt());
      if (PACKET_ID == 1) randomizeTerrain();
      if (PACKET_ID == 2) INTERPRET_TAGGED_OTHER(network_data.getInt());
    }
  }

  void INTERPRET_TAGGED_OTHER(int other_UUID) {
    Player other =  players.get(other_UUID);
    if (state == STATE_IS_IT && other.state != STATE_IS_IT && imunity_counter == 0) {
      setState(STATE_NORMAL);
      other.setState(STATE_IS_IT);
    }
  }

  void readNetwork() {
    if (TCP_CLIENT.available()>0) {
      println("SEVER: Reading "+TCP_CLIENT.available()+" bytes from TCP server");
      // Processing's methods for reading from server is not great
      // I'm using nio.ByteBuffer instead.
      // My concern is that in one 'client.available' session, there could
      // be some leftover data for the next packet, which we don't want to
      // discard. So all the data goes into a global 'server_data' ByteBuffer,
      // to which data is added successively, here.
      byte[] data_from_network = new byte[TCP_CLIENT.available()];
      TCP_CLIENT.readBytes(data_from_network);
      byte[] data_from_buffer = network_data.array();
      byte[] data_combined = new byte[data_from_network.length + data_from_buffer.length - network_data.position()];
      System.arraycopy(data_from_buffer, network_data.position(), data_combined, 0, data_from_buffer.length - network_data.position());
      System.arraycopy(data_from_network, 0, data_combined, data_from_buffer.length - network_data.position(), data_from_network.length);
      network_data = ByteBuffer.wrap(data_combined);
    }
  }
}
