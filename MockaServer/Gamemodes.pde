Gamemode gamemode;

void setGamemode(Gamemode newgamemode) {
  gamemode = newgamemode;
  TCP_SEND_ALL_CLIENTS(NOTIFY_START_GAMEMODE());
}

interface Gamemode {
  byte GAME_ID();
  int PACKET_SIZE();
  void PUT_DATA(ByteBuffer data);
  void INTERPRET(Player p, ByteBuffer data);
  void update();
  void playerAdd(Player p);
  void playerRemove(Player p);
}

class Freeplay implements Gamemode {
  byte GAME_ID() {
    return 0;
  }
  int PACKET_SIZE() {
    return 0;
  }
  void PUT_DATA(ByteBuffer data) {
  }
  void INTERPRET(Player p, ByteBuffer data) {
  }
  void update() {
  }
  void playerAdd(Player p) {
  }
  void playerRemove(Player p) {
  }
}

class TagGame implements Gamemode {
  final int IMMUNE_TIME = 150;
  final int INACTIVE_TIME = 60;

  int startLife;
  int startgame_countdown;
  int UUID_it;
  HashMap<Integer, PlayerStatus> scores;

  TagGame(int startLife) {
    this.startLife = startLife;
    startgame_countdown = 3*60 - 1;
    UUID_it = randomPlayer().UUID;
    scores = new HashMap<Integer, PlayerStatus>();
    for (Player p : players.values()) scores.put(p.UUID, new PlayerStatus(startLife));
  }

  TagGame(String[] args) {
    this(120 * 60);
  }

  class PlayerStatus {
    int life;
    int immune = 0;
    int inactive = 0;
    PlayerStatus(int life) {
      this.life = life;
    }
  }

  void update() {
    if (startgame_countdown > 0) startgame_countdown--;
    else {
      for (PlayerStatus status : scores.values()) {
        if (status.immune > 0) status.immune--;
        if (status.inactive > 0) status.inactive--;
      }
      PlayerStatus status_it = scores.get(UUID_it); 
      if (status_it.life > 0) status_it.life--;
      else {
        println("we done");
      }
    }
  }

  void playerAdd(Player p) {
  }

  void playerRemove(Player p) {
    if (players.size() == 0) {
      setGamemode(new Freeplay());
      return;
    }
    if (p.UUID == UUID_it) UUID_it = randomPlayer().UUID;
    scores.remove(p.UUID);
    TCP_SEND_ALL_CLIENTS(NOTIFY_START_GAMEMODE());
  }

  void INTERPRET(Player p, ByteBuffer data) {
    int MSG_ID = data.get();
    switch (MSG_ID) {
    case 0: // Capitulate
      if (scores.get(p.UUID) == null) break;
      UUID_it = p.UUID;
      scores.get(UUID_it).inactive = INACTIVE_TIME;
      TCP_SEND_ALL_CLIENTS(NOTIFY_GAMEMODE_UPDATE());
      break;
    case 1: // contact claim
      println("--- TAGGING ");
      int UUID_other = data.getInt();
      int UUID_tagger = (p.UUID == UUID_it) ? p.UUID : UUID_other;
      int UUID_tagged = (p.UUID == UUID_it) ? UUID_other : p.UUID;
      if (UUID_tagger != UUID_it) break;
      println(scores.get(UUID_tagger).inactive);
      if (scores.get(UUID_tagger).inactive > 0) break;
      if (scores.get(UUID_tagged) == null) break;
      println(scores.get(UUID_tagged).immune);
      if (scores.get(UUID_tagged).immune > 0) break;
      scores.get(UUID_tagger).immune = IMMUNE_TIME;
      scores.get(UUID_tagged).inactive = INACTIVE_TIME;
      UUID_it = UUID_tagged;
      TCP_SEND_ALL_CLIENTS(NOTIFY_GAMEMODE_UPDATE());
      break;
    }
  }

  ByteBuffer NOTIFY_GAMEMODE_UPDATE() {
    ByteBuffer data = ByteBuffer.allocate(1+4 + 4+16*scores.size());
    data.put((byte)8);
    data.putInt(UUID_it);
    data.putInt(scores.size());
    for (Map.Entry entry : scores.entrySet()) {
      data.putInt((int)entry.getKey());
      PlayerStatus status = (PlayerStatus)entry.getValue();
      data.putInt(status.life);
      data.putInt(status.immune);
      data.putInt(status.inactive);
    }
    return data;
  }

  byte GAME_ID() {
    return 1;
  }
  int PACKET_SIZE() {
    return 4+4+4+4+4 + 4+16*scores.size();
  }
  void PUT_DATA(ByteBuffer data) {
    data.putInt(startLife);
    data.putInt(IMMUNE_TIME);
    data.putInt(INACTIVE_TIME);
    data.putInt(startgame_countdown);
    data.putInt(UUID_it);
    data.putInt(scores.size());
    for (Map.Entry entry : scores.entrySet()) {
      data.putInt((int)entry.getKey());
      PlayerStatus status = (PlayerStatus)entry.getValue();
      data.putInt(status.life);
      data.putInt(status.immune);
      data.putInt(status.inactive);
    }
  }
}
