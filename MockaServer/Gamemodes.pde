import java.util.Collections;
import java.util.Comparator;
import java.util.List;

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

class Leaderboard implements Gamemode {
  boolean is_fresh = true;
  Earning[] earnings;
  Leaderboard(Earning[] earnings) {
    this.earnings = earnings;
  }
  byte GAME_ID() {
    return 3;
  }
  int PACKET_SIZE() {
    return 5 + earnings.length*12;
  }
  void PUT_DATA(ByteBuffer data) {
    data.put(is_fresh ? (byte)1 : (byte)0);
    data.putInt(earnings.length);
    for (int i = 0; i < earnings.length; i++) {
      Earning e = earnings[i];
      data.putInt(e.UUID);
      data.putInt(e.points_won);
      data.putInt(e.places_won);
    }
    is_fresh = false;
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
class Earning {
  int UUID, points_won, places_won;
  Earning(int UUID, int points_won, int places_won) {
    this.UUID = UUID;
    this.points_won = points_won;
    this.places_won = places_won;
  }
}

class Crowning implements Gamemode {
  Player winner;
  int celebrateTime = 60; //4*60;
  Gamemode leaderboard;
  Crowning(Player winner, Gamemode leaderboard) {
    this.winner = winner;
    this.leaderboard = leaderboard;
  }
  byte GAME_ID() {
    return 2;
  }
  int PACKET_SIZE() {
    return 4;
  }
  void PUT_DATA(ByteBuffer data) {
    data.putInt(winner.UUID);
  }
  void INTERPRET(Player p, ByteBuffer data) {
  }
  void update() {
    celebrateTime--;
    if (celebrateTime < 0) setGamemode(leaderboard);
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
    startgame_countdown = 30;//3*60 - 1;
    UUID_it = randomPlayer().UUID;
    scores = new HashMap<Integer, PlayerStatus>();
    for (Player p : players.values()) scores.put(p.UUID, new PlayerStatus(startLife, (p.UUID != UUID_it) ? startgame_countdown : 0, (p.UUID == UUID_it) ? startgame_countdown : 0));
  }

  TagGame(String[] args) {
    this(5);//120 * 60);
  }

  class PlayerStatus {
    int place; // used at end

    int life, immune, inactive;
    PlayerStatus(int life) {
      this(life, 0, 0);
    }
    PlayerStatus(int life, int immune, int inactive) {
      this.life = life;
      this.immune = immune;
      this.inactive = inactive;
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
      if (status_it != null && status_it.life > 0) status_it.life--;
      else {
        int UUID_winner = 0;
        int life_winner = -1;
        for (Map.Entry entry : scores.entrySet()) {
          int life = ((PlayerStatus)entry.getValue()).life;
          if (life > life_winner) {
            UUID_winner = (int)entry.getKey();
            life_winner = life;
          }
        }
        Player winner = players.get(UUID_winner);
        // compute leaderboards


        // Sort place for this round
        List<Map.Entry<Integer, PlayerStatus>> scores_sorted = new ArrayList(scores.entrySet());
        Collections.sort(scores_sorted, new Comparator<Map.Entry<Integer, PlayerStatus>>() {
          public int compare(Map.Entry<Integer, PlayerStatus> o1, Map.Entry<Integer, PlayerStatus> o2) {
            return o2.getValue().life - o1.getValue().life;
          }
        }
        );
        if (scores_sorted.size() > 0) scores_sorted.get(0).getValue().place = 1;
        for (int i = 1; i < scores_sorted.size(); i++) {
          PlayerStatus p = scores_sorted.get(i).getValue();
          PlayerStatus above = scores_sorted.get(i-1).getValue();
          p.place = above.place + ((p.life == above.life) ? 0 : 1);
        }
        // note where players stood in leaderboards before
        for (Player p : players.values()) {
          p.place_ = p.place;
          p.points_ = p.points;
        }
        // update points
        for (Map.Entry entry : scores.entrySet()) {
          int UUID = (int)entry.getKey();
          Player p = players.get(UUID);
          PlayerStatus status = (PlayerStatus)entry.getValue();
          if (p != null) p.points += scores.size() - status.place; // Give points!!
        }
        // update places
        List<Player> players_sorted = new ArrayList(players.values());
        players_sorted.sort(new Comparator<Player>() {
          public int compare(Player p1, Player p2) {
            return p2.points - p1.points;
          }
        }
        );
        if (players_sorted.size() > 0) players_sorted.get(0).place = 1;
        for (int i = 1; i < players_sorted.size(); i++) {
          Player p = players_sorted.get(i);
          Player above = players_sorted.get(i-1);
          if (p.points == above.points) p.place = above.place;
          else p.place = 1+i;
        }
        for (int i = 0; i < players_sorted.size(); i++) {
          Player p = players_sorted.get(i);
          println(p.name+ " points "+p.points+" ("+p.points_+") place "+p.place+" ("+p.place_+")");
        }
        // create earnings
        Earning[] earnings = new Earning[players.size()];
        int i = 0;
        for (Player p : players.values()) {
          earnings[i] = new Earning(p.UUID, p.points - p.points_, p.place_ - p.place);
          i++;
        }
        Leaderboard leaderboard = new Leaderboard(earnings);
        setGamemode(new Crowning(winner, leaderboard)); 
        println("SERVER: winner: "+UUID_winner+" "+winner);
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
    case 0 : // Capitulate
      if (scores.get(p.UUID) == null) break;
      UUID_it = p.UUID;
      scores.get(UUID_it).inactive = INACTIVE_TIME;
      TCP_SEND_ALL_CLIENTS(NOTIFY_GAMEMODE_UPDATE());
      break;
    case 1 : // contact claim
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
