HashMap<Integer, Player> players = new HashMap<Integer, Player>();

class Player {
  Client TCP_CLIENT;
  int UUID;
  color col;
  String name;

  int points, points_;
  int place, place_;

  Player(Client client_, int UUID_) {
    name = randomName();
    col = color(random(0, 255), random(0, 255), random(0, 255));
    points_ = points = 0;
    Player last = lastPlayer();
    if (last == null) place = 1;
    else if (last.points == points) place = last.place;
    else place = last.place + 1;
    place_ = place;

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
      if (PACKET_ID == 2) INTERPRET_GAMEMODE_UPDATE();
      if (PACKET_ID == 3) gamemode.respawn(this);
      if (PACKET_ID == 4) INTERPRET_CHAT();
      if (PACKET_ID == 5) note_missing_hole(network_data.getInt(), UUID);
    }
  }

  void INTERPRET_SET_COLOR(color col) { // 
    this.col = col;
    TCP_SEND_ALL_CLIENTS_EXCEPT(NOTIFY_PLAYER_INFO(this), UUID);
  }
  void INTERPRET_SET_COLOR_ALL(color col) { // 
    this.col = col;
    TCP_SEND_ALL_CLIENTS(NOTIFY_PLAYER_INFO(this));
  }

  void INTERPRET_GAMEMODE_UPDATE() {
    byte GAME_ID = network_data.get();
    short len = network_data.getShort();
    if (GAME_ID == gamemode.GAME_ID()) gamemode.INTERPRET(this, network_data);
    else {
      // oops! received a packet which is meant to be read by a gamemode which is no longer the current one
      // discard, whilst being carefull to read just the bytes that need to be
      for (int i = 0; i < len; i++) network_data.get();
    }
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
        if (split[0].equals("/freeplay")) setGamemode(new Freeplay());
        if (split[0].equals("/tag")) setGamemode(new TagGame(args));
        if (split[0].equals("/float")) setGamemode(new FloatGame(args));
        if (split[0].equals("/name")) setName(NAMIFY(split[1]));
        if (split[0].equals("/terrain")) randomizeTerrain(int(split[1]));
        if (split[0].equals("/color")) INTERPRET_SET_COLOR_ALL(COLORIFY(split[1]));
        if (split[0].equals("/ctf")) setGamemode(new CTF(args));
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

  color COLORIFY(String str_col) {
    return unhex("FF" + str_col);
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
  for (Player p : players.values()) p.updateNetwork();
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

void sortPlayers() {
  if (players.size() == 0) return;
  // update places
  List<Player> players_sorted = new ArrayList(players.values());
  players_sorted.sort(new Comparator<Player>() {
    public int compare(Player p1, Player p2) {
      return p2.points - p1.points;
    }
  }
  );
  players_sorted.get(0).place = 1;
  TCP_SEND_ALL_CLIENTS(NOTIFY_PLAYER_INFO(players_sorted.get(0)));
  for (int i = 1; i < players_sorted.size(); i++) {
    Player p = players_sorted.get(i);
    Player above = players_sorted.get(i-1);
    if (p.points == above.points) p.place = above.place;
    else p.place = 1+i;
    TCP_SEND_ALL_CLIENTS(NOTIFY_PLAYER_INFO(p));
  }
  println("SERVER: sorted players:");
  for (int i = 0; i < players_sorted.size(); i++) {
    Player p = players_sorted.get(i);
    println(i+" "+p.name+" place: "+p.place+" points: "+p.points);
  }
}

Player lastPlayer() {
  Player last = null;
  for (Player p : players.values()) if (last == null || p.points < last.points) last = p;
  return last;
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
