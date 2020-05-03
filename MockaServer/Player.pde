HashMap<Integer, Player> players = new HashMap<Integer, Player>();

enum State {
  normal, it;
  static byte getValue(State state) {
    if (state == normal) return (byte)0;
    if (state == it) return (byte)1;
    return (byte)(-1);
  }
}

class Player {
  Client TCP_CLIENT;
  int UUID;
  color col = color(0);
  String name;

  State state = State.normal;
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
        TCP_SEND(NOTIFY_PLAYER_INFO(p.UUID, p.col));
        TCP_SEND(NOTIFY_PLAYER_STATE(p.UUID, p.state));
        note_missing_hole(UUID, p.UUID);
      }
    }
  }

  void setColor(color col) {
    this.col = col;
    TCP_SEND_ALL_CLIENTS_EXCEPT(NOTIFY_PLAYER_INFO(UUID, col), UUID);
  }

  void setState(State state) {
    //println("SERVER: setting state of player "+UUID+" to "+state);
    this.state = state;
    TCP_SEND_ALL_CLIENTS(NOTIFY_PLAYER_STATE(UUID, state));
    if (state == State.it) imunity_counter = 60;
    else imunity_counter = 0;
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
      //if (PACKET_ID == 1) randomizeTerrain();
      if (PACKET_ID == 2) INTERPRET_TAGGED_OTHER(network_data.getInt());
      if (PACKET_ID == 3) INTERPRET_CAPITULATE();
    }
  }

  void INTERPRET_TAGGED_OTHER(int other_UUID) {
    Player other =  players.get(other_UUID);
    if (state == State.it && imunity_counter == 0 && other.state != State.it) {
      setState(State.normal);
      other.setState(State.it);
    }
  }

  void INTERPRET_CAPITULATE() {
    if (state == State.it) return;
    for (Map.Entry entry : players.entrySet()) {
      Player p = (Player)entry.getValue();
      if (p == this) continue;
      if (p.state == State.it) {
        if (p.imunity_counter != 0) return;
        setState(State.it);
        p.setState(State.normal);
        return;
      }
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

void removeInactivePlayers() {
  Iterator<Map.Entry<Integer, Player>> iter = players.entrySet().iterator();
  while (iter.hasNext()) {
    Map.Entry<Integer, Player> entry = iter.next();
    Player p = entry.getValue();
    if (!p.TCP_CLIENT.active()) {
      if (p.state == State.it) SOMEONES_IT = false;
      iter.remove();
      TCP_SEND_ALL_CLIENTS(NOTIFY_DED_PLAYER(p.UUID));
      println("SERVER: player with UUID "+p.UUID+" is no longer active, disconnecting");
    }
  }
  if (!SOMEONES_IT && !players.isEmpty()) {
    iter = players.entrySet().iterator();
    Map.Entry<Integer, Player> entry = iter.next();
    Player p = entry.getValue();
    p.setState(State.it);
    SOMEONES_IT = true;
  }
}

void updatePlayers() {
  for (Map.Entry entry : players.entrySet()) {
    Player p = (Player)entry.getValue();
    p.updateNetwork();
  }
}

int getFreeUUID() {
  int MAX_UUID = 256;
  int UUID;

  do {
    UUID = (int)random(MAX_UUID);
  } while (players.containsKey(UUID));
  return UUID;
}
