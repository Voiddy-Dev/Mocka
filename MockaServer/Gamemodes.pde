Gamemode gamemode;

void setGamemode(Gamemode newgamemode) {
  gamemode = newgamemode;
  TCP_SEND_ALL_CLIENTS(NOTIFY_GAMEMODE_STATE());
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
      PlayerStatus status = scores.get(UUID_it); 
      if (status.life > 0) status.life--;
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
    TCP_SEND_ALL_CLIENTS(NOTIFY_GAMEMODE_STATE());
  }

  void INTERPRET(Player p, ByteBuffer data) {
    int MSG_ID = data.get();
    switch (MSG_ID) {
    case 0: // Capitulate
      UUID_it = p.UUID;
      TCP_SEND_ALL_CLIENTS(NOTIFY_GAMEMODE_STATE());
      break;
    case 1: // Got other
      UUID_it = data.getInt();
      TCP_SEND_ALL_CLIENTS(NOTIFY_GAMEMODE_STATE());
    }
  }

  byte GAME_ID() {
    return 1;
  }
  int PACKET_SIZE() {
    return 4+4+4 + 4+16*scores.size();
  }
  void PUT_DATA(ByteBuffer data) {
    data.putInt(startLife);
    data.putInt(startgame_countdown);
    data.putInt(UUID_it);
    data.putInt(scores.size());
    for (int UUID : scores.keySet()) {
      data.putInt(UUID);
      PlayerStatus status = scores.get(UUID);
      data.putInt(status.life);
      data.putInt(status.immune);
      data.putInt(status.inactive);
    }
  }
}
