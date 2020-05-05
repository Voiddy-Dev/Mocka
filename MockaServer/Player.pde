HashMap<Integer, Player> players = new HashMap<Integer, Player>();

class Player {
  Client TCP_CLIENT;
  int UUID;
  color col;
  String name;

  Player(Client client_, int UUID_) {
    name = randomName();
    col = color(random(0, 255), random(0, 255), random(0, 255));

    TCP_CLIENT = client_;
    UUID = UUID_;
    TCP_SEND(NOTIFY_YOUR_UUID(UUID));
    TCP_SEND(NOTIFY_TERRAIN(platforms));
    TCP_SEND(NOTIFY_START_GAMEMODE());
    println("SERVER: new TCP connection. ip: "+TCP_CLIENT.ip()+" UUID: "+UUID);
  }

  void synchronize() {
    TCP_SEND_ALL_CLIENTS(NOTIFY_PLAYER_INFO(this));
    // Notify this new player about all existing players
    for (Map.Entry entry : players.entrySet()) {
      Player p = (Player)entry.getValue();
      if (p == this) continue;
      TCP_SEND(NOTIFY_NEW_PLAYER(p.UUID));
      TCP_SEND(NOTIFY_PLAYER_INFO(p)); 
      note_missing_hole(UUID, p.UUID);
    }
  }

  void TCP_SEND(ByteBuffer buf) {
    TCP_CLIENT.write(buf.array());
  }

  ByteBuffer network_data = ByteBuffer.allocate(0);

  void updateNetwork() {
    readNetwork();
    interpretNetwork();
  }

  void interpretNetwork() {
    if (network_data.remaining()>0) {
      byte PACKET_ID = network_data.get();
      println("SERVER: Reading packet from "+UUID+" PACKET: "+PACKET_ID);
      if (PACKET_ID == 0) INTERPRET_SET_COLOR(network_data.getInt());
      //if (PACKET_ID == 1) randomizeTerrain();
      if (PACKET_ID == 2) gamemode.INTERPRET(this, network_data);
      if (PACKET_ID == 4) INTERPRET_CHAT();
    }
  }

  void INTERPRET_SET_COLOR(color col) { // 
    this.col = col;
    TCP_SEND_ALL_CLIENTS_EXCEPT(NOTIFY_PLAYER_INFO(this), UUID);
  }

  void INTERPRET_CHAT() {
    try {
      String msg = getString(network_data);
      println("SERVER: CHAT "+msg);
      INTERPRET_msg(msg);
    } 
    catch(Exception e) {
      println("Error while parsing input from chat (danger danger danger)");
      println(e);
    }
  }

  void INTERPRET_msg(String msg) {
    if (msg.length() == 0) return;
    boolean command = msg.charAt(0) == '/';
    if (!command) TCP_SEND_ALL_CLIENTS(NOTIFY_CHAT(msg));
    else {
      println("SERVER: Interpreting a command");
      String[] split = msg.split(" ");
      String[] args = subset(split, 1);
      try {
        if (split[0].equals("/newgame")) setGamemode(new TagGame(args));
        if (split[0].equals("/name")) setName(NAMIFY(split[1]));
        if (split[0].equals("/terrain")) randomizeTerrain(int(split[1])+1);
      } 
      catch (Exception e) {
        println("SERVER: failed to interpret command from client");
      }
    }
  }

  void setName(String name) {
    println("setting name");
    println(name);
    this.name = name;
    TCP_SEND_ALL_CLIENTS(NOTIFY_PLAYER_INFO(this));
  }

  String NAMIFY(String name) {
    return name.toUpperCase().substring(0, 3);
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

void updatePlayers() {
  for (Map.Entry entry : players.entrySet()) {
    Player p = (Player)entry.getValue();
    p.updateNetwork();
  }
}

void removeInactivePlayers() {
  Iterator<Map.Entry<Integer, Player>> iter = players.entrySet().iterator();
  while (iter.hasNext()) {
    Map.Entry<Integer, Player> entry = iter.next();
    Player p = entry.getValue();
    if (!p.TCP_CLIENT.active()) {
      iter.remove();
      TCP_SEND_ALL_CLIENTS(NOTIFY_DED_PLAYER(p.UUID));
      gamemode.playerRemove(p);
      println("SERVER: player with UUID "+p.UUID+" is no longer active, disconnecting");
    }
  }
}

Player randomPlayer() {
  Object[] values = players.values().toArray();
  return (Player)values[int(random(values.length))];
}

int getFreeUUID() {
  int MAX_UUID = 256;
  int UUID;

  do {
    UUID = (int)random(MAX_UUID);
  } while (players.containsKey(UUID));
  return UUID;
}

String randomName() {
  return "" + randomChar() + randomChar() + randomChar();
}

char randomChar() {
  return char(int(random(int('A'), int('Z'))));
}
