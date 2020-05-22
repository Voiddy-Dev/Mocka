import java.util.Collections;
import java.util.Comparator;
import java.util.List;

final boolean SHORT_ROUNDS = false;

final int THREE_SECONDS = 3*60;
final int FIVE_SECONDS = 5*60;
final int TWO_MINUTES = 120*60;
final int STARTGAME_COUNTDOWN = SHORT_ROUNDS ? 30 : THREE_SECONDS;
final int DEFAULT_LIFE = SHORT_ROUNDS ? 30 : TWO_MINUTES;

// CTF
final boolean CTF_DO_DEADLOCK = true;
final boolean CTF_DO_FLAG_THEFT = true;
final boolean CTF_DO_FLAG_RELAY = true;
final boolean CTF_DO_AUTO_PLACE_BASES = true;
final int CTF_THEFT_COOLDOWN = 40;

color[] TEAM_COLORS_GLOBAL = {
  #F01818, #3655FF, #0ACE22, #FFCC24
};

float BASE_RADIUS = 50;

Gamemode gamemode;

void setGamemode(Gamemode newgamemode) {
  gamemode = newgamemode;
  TCP_SEND_ALL_CLIENTS(NOTIFY_START_GAMEMODE());
  println("Set gamemode to "+gamemode.getClass());
}

interface Gamemode {
  byte GAME_ID();
  int PACKET_SIZE();
  void PUT_DATA(ByteBuffer data);
  void INTERPRET(Player p, ByteBuffer data);
  void update();
  void playerAdd(Player p);
  void playerRemove(Player p);
  void respawn(Player p);
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
  void respawn(Player p) {
  }
}

CTF startCTF(String[] args) {
  if (args.length == 0) return new CTF(2);
  else {
    int teams = int(args[0]);
    return new CTF(teams);
  }
}

public class CTF implements Gamemode {
  boolean ready = CTF_DO_AUTO_PLACE_BASES;
  int NUM_TEAMS;
  Team[] teams;

  int startgame_countdown;

  HashMap<Integer, PlayerStatus> status;

  CTF(int NUM_TEAMS, color[] TEAM_COLORS) {
    startgame_countdown = THREE_SECONDS;
    this.NUM_TEAMS = NUM_TEAMS;
    teams = new Team[NUM_TEAMS];
    for (int i = 0; i < NUM_TEAMS; i++) teams[i] = new Team(i, TEAM_COLORS[i]);

    if (CTF_DO_AUTO_PLACE_BASES) {
      float x1 = WIDTH*0.25;
      float x3 = 3*x1;
      float y1 = HEIGHT*0.25;
      float y2 = 2*y1;
      float y3 = 3*y1;
      if (NUM_TEAMS == 2) {
        teams[0].y = teams[1].y = y2;
        teams[0].x = x1;
        teams[1].x = x3;
      } else {
        teams[0].y = teams[1].y = y1;
        teams[2].y = teams[3].y = y3;
        teams[0].x = teams[2].x = x1;
        teams[1].x = teams[3].x = x3;
      }
    }

    status = new HashMap<Integer, PlayerStatus>(players.size());
    for (Player p : players.values()) status.put(p.UUID, new PlayerStatus(p));
  }
  CTF(int NUM_TEAMS) {
    this(NUM_TEAMS, subset(TEAM_COLORS_GLOBAL, 0, NUM_TEAMS));
  }

  class Team {
    byte id;
    boolean ready = false;
    color col;
    boolean flag_at_home;
    int flag_bearer_UUID;
    float x, y;

    Team(int id, color col) {
      this.id = (byte)id;
      this.col = col;
      x = -999; //random(WIDTH);
      y = -999; //random(HEIGHT);
      flag_at_home = true;
    }
  }
  byte computeRelation(PlayerStatus myStatus, PlayerStatus oStatus) {
    if (myStatus == null) return (byte)0;
    if (myStatus == oStatus) return (byte)0;
    Team myTeam = teams[myStatus.team];
    Team oTeam = teams[oStatus.team];
    int myVulnerability = 0;
    int oVulnerability = 0;
    if (oStatus.hasOwnFlag) oVulnerability += 8;
    if (myStatus.hasOwnFlag) myVulnerability += 8;
    if (!myTeam.flag_at_home && myTeam.flag_bearer_UUID == oStatus.p.UUID) oVulnerability += 4;
    if (!oTeam.flag_at_home && oTeam.flag_bearer_UUID == myStatus.p.UUID) myVulnerability += 4;
    if (oStatus.loc == myStatus.team) oVulnerability += 2;
    if (myStatus.loc == oStatus.team) myVulnerability += 2;
    if (!oStatus.isAtHome) oVulnerability ++;
    if (!myStatus.isAtHome) myVulnerability ++;
    if (myVulnerability > oVulnerability) return (byte)-2;
    if (myVulnerability < oVulnerability) return (byte)2;
    if (oStatus.flagCount < myStatus.flagCount) return (byte)-1;
    if (oStatus.flagCount > myStatus.flagCount) return (byte)1;
    return (byte)0;
  }
  class PlayerStatus {
    Player p;

    byte team, loc;
    int capture_count, protected_count, jailed_count, jailing_count;

    boolean hasOwnFlag, isAtHome;
    byte flagCount;

    int theft_cooldown = 0;

    PlayerStatus(Player p) {
      this.p = p;
    }

    void updateStatus() {
      hasOwnFlag = !teams[team].flag_at_home && teams[team].flag_bearer_UUID == p.UUID;
      isAtHome = loc == team;
      flagCount = 0;
      for (Team t : teams) if (!t.flag_at_home && t.flag_bearer_UUID == p.UUID) flagCount++;
    }
  }
  int PlayerStatus_PACKET_SIZE() {
    return 4 + 1+1+16;
  }

  byte GAME_ID() {
    return 5;
  }
  int PACKET_SIZE() {
    return 1+4+4+4 + 17*NUM_TEAMS + 4+status.size()*PlayerStatus_PACKET_SIZE();
  }
  void PUT_DATA(ByteBuffer data) {
    byte mask = 0;
    if (ready) mask += 1;
    if (CTF_DO_FLAG_THEFT) mask += 2;
    if (CTF_DO_FLAG_RELAY) mask += 4;
    data.put(mask);
    data.putInt(startgame_countdown);
    data.putFloat(BASE_RADIUS);

    data.putInt(NUM_TEAMS);
    for (Team t : teams) {
      data.putInt(t.col);
      data.putFloat(t.x);
      data.putFloat(t.y);
      data.put(t.flag_at_home ? (byte)1 : (byte)0);
      data.putInt(t.flag_bearer_UUID);
    }

    data.putInt(status.size());
    for (PlayerStatus s : status.values()) {
      data.putInt(s.p.UUID);
      data.put(s.team);
      data.put(s.loc);
      data.putInt(s.capture_count);
      data.putInt(s.protected_count);
      data.putInt(s.jailed_count);
      data.putInt(s.jailing_count);
    }
  }

  ByteBuffer NOTIFY_P_TEAM(PlayerStatus s) {
    ByteBuffer data = ByteBuffer.allocate(7);
    data.put((byte)8);
    data.put((byte)0);
    data.putInt(s.p.UUID);
    data.put(s.team);
    return data;
  }
  ByteBuffer NOTIFY_T_LOC(Team t) {
    ByteBuffer data = ByteBuffer.allocate(11);
    data.put((byte)8);
    data.put((byte)1);
    data.put(t.id);
    data.putFloat(t.x);
    data.putFloat(t.y);
    return data;
  }
  ByteBuffer NOTIFY_P_LOC(PlayerStatus s) {
    ByteBuffer data = ByteBuffer.allocate(7);
    data.put((byte)8);
    data.put((byte)2);
    data.putInt(s.p.UUID);
    data.put(s.loc);
    return data;
  }
  ByteBuffer NOTIFY_T_FLAG(Team t) {
    ByteBuffer data = ByteBuffer.allocate(8);
    data.put((byte)8);
    data.put((byte)3);
    data.put(t.id);
    data.put(t.flag_at_home ? (byte)1 : (byte)0);
    data.putInt(t.flag_bearer_UUID);
    return data;
  }
  ByteBuffer NOTIFY_CTF_READY() {
    ByteBuffer data = ByteBuffer.allocate(7);
    data.put((byte)8);
    data.put((byte)4);
    data.put(ready ? (byte)1 : (byte)0);
    data.putInt(startgame_countdown);
    return data;
  }

  void INTERPRET(Player p, ByteBuffer data) {
    byte MSG_ID = data.get();
    println("SERVER: CTF: received message of type "+MSG_ID);
    if (MSG_ID == 0) INTERPRET_MYTEAM(p, data);
    else if (MSG_ID == 1) INTERPRET_BASE_LOC(p, data);
    else if (MSG_ID == 2) INTERPRET_LOC(p, data);
    else if (MSG_ID == 3) INTERPRET_THEFT(p, data);
    else if (MSG_ID == 4) INTERPRET_MURDER(p, data);
    else if (MSG_ID == 5) INTERPRET_TOUCHED_BASE(p, data);
  }

  void INTERPRET_MYTEAM(Player p, ByteBuffer data) {
    byte team = data.get();
    PlayerStatus s = status.get(p.UUID);
    if (s == null) return;
    s.team = team;
    s.loc = team;
    s.updateStatus();
    TCP_SEND_ALL_CLIENTS(NOTIFY_P_TEAM(s));
    s.p.INTERPRET_SET_COLOR_ALL(teams[team].col);
  }

  void INTERPRET_BASE_LOC(Player p, ByteBuffer data) {
    float x = data.getFloat();
    float y = data.getFloat();
    PlayerStatus s = status.get(p.UUID);
    if (s == null) return;
    Team t = teams[s.team];
    t.x = x;
    t.y = y;
    t.ready = true;
    ready = true;
    for (Team tt : teams) if (!tt.ready) ready = false;
    TCP_SEND_ALL_CLIENTS(NOTIFY_T_LOC(t));
    TCP_SEND_ALL_CLIENTS(NOTIFY_CTF_READY());
  }

  void INTERPRET_LOC(Player p, ByteBuffer data) {
    byte loc = data.get();
    PlayerStatus s = status.get(p.UUID);
    if (s == null) return;
    s.loc = loc;
    s.updateStatus();
    TCP_SEND_ALL_CLIENTS(NOTIFY_P_LOC(s));
  }

  void INTERPRET_THEFT(Player p, ByteBuffer data) {
    println("SERVER: CTF: Theft packet received");
    int perpetrator_UUID = data.getInt();
    int victim_UUID = data.getInt();
    if (p.UUID != perpetrator_UUID && p.UUID != victim_UUID)  return;
    PlayerStatus theif_s = status.get(perpetrator_UUID);
    PlayerStatus victim_s = status.get(victim_UUID);
    if (theif_s == null || victim_s == null) return;
    println("SERVER: CTF: theft claim: perpetrator: "+theif_s.p.name+" victim: "+victim_s.p.name);
    if (victim_s.theft_cooldown > 0) return;
    println("SERVER: CTF: relation: "+computeRelation(victim_s, theif_s));
    if (computeRelation(victim_s, theif_s) != (byte)-1) return;
    for (Team t : teams) if (!t.flag_at_home && t.flag_bearer_UUID == victim_UUID) {
      t.flag_bearer_UUID = perpetrator_UUID;
      TCP_SEND_ALL_CLIENTS(NOTIFY_T_FLAG(t));
    }
    theif_s.updateStatus();
    victim_s.updateStatus();
    victim_s.theft_cooldown = CTF_THEFT_COOLDOWN;
  }
  void INTERPRET_MURDER(Player p, ByteBuffer data) {
    int perpetratorUUID = data.getInt();
    int victimUUID = data.getInt();
    if (p.UUID != perpetratorUUID && p.UUID != perpetratorUUID)  return;

    PlayerStatus perpetratorStatus = status.get(perpetratorUUID);
    PlayerStatus victimStatus = status.get(victimUUID);
    if (perpetratorStatus == null || victimStatus == null) return;
    if (computeRelation(victimStatus, perpetratorStatus) != (byte)-2) return;
    for (Team t : teams) if (!t.flag_at_home && t.flag_bearer_UUID == victimUUID) {
      t.flag_bearer_UUID = perpetratorUUID;
      TCP_SEND_ALL_CLIENTS(NOTIFY_T_FLAG(t));
    }
    victimStatus.p.TCP_SEND(NOTIFY_RESPAWN());
    perpetratorStatus.updateStatus();
    victimStatus.updateStatus();
  }
  void INTERPRET_TOUCHED_BASE(Player p, ByteBuffer data) {
    byte team_id = data.get();
    if (startgame_countdown > 0) return;
    Team team = teams[team_id];
    PlayerStatus s = status.get(p.UUID);
    if (s == null) return;
    if (team_id == s.team) {
      // Back home: flags captured
      if (CTF_DO_DEADLOCK) if (!team.flag_at_home && team.flag_bearer_UUID != p.UUID) return;
      for (Team t : teams) if (!t.flag_at_home && t.flag_bearer_UUID == p.UUID) {
        t.flag_at_home = true;
        TCP_SEND_ALL_CLIENTS(NOTIFY_T_FLAG(t));
      }
      s.updateStatus();
    } else {
      // Capture other teams' flags
      if (!team.flag_at_home) return;
      team.flag_at_home = false;
      team.flag_bearer_UUID = p.UUID;
      TCP_SEND_ALL_CLIENTS(NOTIFY_T_FLAG(team));
      s.updateStatus();
    }
  }

  void update() {
    if (!ready) return;
    if (startgame_countdown > 0) startgame_countdown--;
    else {
      for (PlayerStatus s : status.values()) if (s.theft_cooldown > 0) s.theft_cooldown--;
    }
  }
  void playerAdd(Player p) {
  }
  void playerRemove(Player p) {
    if (players.size() == 0) {
      setGamemode(new Freeplay());
      return;
    }
    for (Team t : teams) if (t.flag_bearer_UUID == p.UUID) t.flag_at_home = true;
    status.remove(p.UUID);
    TCP_SEND_ALL_CLIENTS(NOTIFY_START_GAMEMODE());
  }
  void respawn(Player p) {
    if (startgame_countdown > 0) return;
    PlayerStatus s = status.get(p.UUID);
    if (s == null) return;
    for (Team t : teams) if (!t.flag_at_home && t.flag_bearer_UUID == p.UUID) {
      t.flag_at_home = true;
      TCP_SEND_ALL_CLIENTS(NOTIFY_T_FLAG(t));
    }
  }
}

class Leaderboard implements Gamemode {
  boolean is_fresh = true;
  Earning[] earnings;
  Leaderboard() {
    // create earnings
    earnings = new Earning[players.size()];
    int i = 0;
    for (Player p : players.values()) {
      earnings[i] = new Earning(p.UUID, p.points - p.points_, p.place_ - p.place);
      i++;
    }
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
  void respawn(Player p) {
  }
  class Earning {
    int UUID, points_won, places_won;
    Earning(int UUID, int points_won, int places_won) {
      this.UUID = UUID;
      this.points_won = points_won;
      this.places_won = places_won;
      // we've taken note of progress, reset for next match
      Player p = players.get(UUID);
      p.points_ = p.points;
      p.place_ = p.place;
    }
  }
}

class Crowning implements Gamemode {
  Player winner;
  int celebrateTime = SHORT_ROUNDS ? 60 : 4*60;
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
  void respawn(Player p) {
  }
}


//  ______ _             _    _____                      
// |  ____| |           | |  / ____|                     
// | |__  | | ___   __ _| |_| |  __  __ _ _ __ ___   ___ 
// |  __| | |/ _ \ / _` | __| | |_ |/ _` | '_ ` _ \ / _ \
// | |    | | (_) | (_| | |_| |__| | (_| | | | | | |  __/
// |_|    |_|\___/ \__,_|\__|\_____|\__,_|_| |_| |_|\___|



class FloatGame implements Gamemode {
  int life_goal;

  int startgame_countdown;
  HashMap<Integer, PlayerStatus> scores;

  FloatGame(int life_goal) {
    this.life_goal = life_goal;
    startgame_countdown = STARTGAME_COUNTDOWN;
    scores = new HashMap<Integer, PlayerStatus>();
    for (Player p : players.values()) scores.put(p.UUID, new PlayerStatus());
  }

  FloatGame(String[] args) {
    this(DEFAULT_LIFE);
  }

  class PlayerStatus {
    int place; // used at end

    boolean in_air = false;
    int life;
    PlayerStatus() {
    }
  }

  void update() {
    if (startgame_countdown > 0) startgame_countdown--;
    else {
      for (PlayerStatus status : scores.values()) if (status.in_air) status.life++;
      for (PlayerStatus status : scores.values()) if (status.life >= life_goal) {
        finishGame();
        break;
      }
    }
  }

  void finishGame() {
    if (scores.size() == 0) {
      setGamemode(new Freeplay());
      return;
    }
    // Sort scores, in decreasing order
    List<Map.Entry<Integer, PlayerStatus>> scores_sorted = new ArrayList(scores.entrySet());
    Collections.sort(scores_sorted, new Comparator<Map.Entry<Integer, PlayerStatus>>() {
      public int compare(Map.Entry<Integer, PlayerStatus> o1, Map.Entry<Integer, PlayerStatus> o2) {
        return o2.getValue().life - o1.getValue().life;
      }
    }
    );

    Player winner = players.get(scores_sorted.get(0).getKey());
    // compute leaderboards, attribute scores
    scores_sorted.get(0).getValue().place = 1;
    winner.points += scores.size() - 1; // Give points!!
    for (int i = 1; i < scores_sorted.size(); i++) {
      PlayerStatus status = scores_sorted.get(i).getValue();
      PlayerStatus status_player_infront = scores_sorted.get(i-1).getValue();
      if (status.life == status_player_infront.life) status.place = status_player_infront.place;
      else status.place = 1+i;
      Player p = players.get(scores_sorted.get(i).getKey());
      p.points += scores.size() - status.place; // Give points!!
    }

    println("SERVER: scores for this game:");
    for (int i = 0; i < scores_sorted.size(); i++) {
      PlayerStatus status = scores_sorted.get(i).getValue();
      Player p = players.get(scores_sorted.get(i).getKey());
      println(i+" "+p.name+" place: "+status.place+" life: "+status.life);
    }

    sortPlayers();
    Leaderboard leaderboard = new Leaderboard();
    setGamemode(new Crowning(winner, leaderboard)); 
    println("SERVER: winner: "+winner.UUID+" "+winner);
  }

  void playerAdd(Player p) {
  }

  void playerRemove(Player p) {
    if (players.size() == 0) {
      setGamemode(new Freeplay());
      return;
    }
    scores.remove(p.UUID);
    TCP_SEND_ALL_CLIENTS(NOTIFY_START_GAMEMODE());
  }

  void respawn(Player p) {
    // Player p has resapwned, punish them hard
    PlayerStatus status = scores.get(p.UUID);
    if (status == null) return;
    status.life = max(status.life - 5*60, 0);
    status.in_air = true;
    TCP_SEND_ALL_CLIENTS(NOTIFY_GAMEMODE_UPDATE());
  }

  void INTERPRET(Player p, ByteBuffer data) {
    byte info = data.get();
    PlayerStatus status = scores.get(p.UUID);
    if (status == null) return;
    status.in_air = info == 0;
    TCP_SEND_ALL_CLIENTS(NOTIFY_GAMEMODE_UPDATE());
  }

  ByteBuffer NOTIFY_GAMEMODE_UPDATE() {
    ByteBuffer data = ByteBuffer.allocate(1+4 + 4+9*scores.size());
    data.put((byte)8);
    data.putInt(startgame_countdown);
    data.putInt(scores.size());
    for (Map.Entry entry : scores.entrySet()) {
      data.putInt((int)entry.getKey());
      PlayerStatus status = (PlayerStatus)entry.getValue();
      data.putInt(status.life);
      data.put(status.in_air ? (byte)1 : (byte)0);
    }
    return data;
  }

  byte GAME_ID() {
    return 4;
  }
  int PACKET_SIZE() {
    return 4+4 + 4+9*scores.size();
  }
  void PUT_DATA(ByteBuffer data) {
    data.putInt(life_goal);
    data.putInt(startgame_countdown);
    data.putInt(scores.size());
    for (Map.Entry entry : scores.entrySet()) {
      data.putInt((int)entry.getKey());
      PlayerStatus status = (PlayerStatus)entry.getValue();
      data.putInt(status.life);
      data.put(status.in_air ? (byte)1 : (byte)0);
    }
  }
}



// _______           _____                      
//|__   __|         / ____|                     
//   | | __ _  __ _| |  __  __ _ _ __ ___   ___ 
//   | |/ _` |/ _` | | |_ |/ _` | '_ ` _ \ / _ \
//   | | (_| | (_| | |__| | (_| | | | | | |  __/
//   |_|\__,_|\__, |\_____|\__,_|_| |_| |_|\___|
//             __/ |                            
//            |___/                             




class TagGame implements Gamemode {
  final int IMMUNE_TIME = 150;
  final int INACTIVE_TIME = 60;
  final int INACTIVE_RESPAWN_TIME = 150;

  int startLife;
  int startgame_countdown;
  int UUID_it;
  HashMap<Integer, PlayerStatus> scores;

  TagGame(int startLife) {
    this.startLife = startLife;
    startgame_countdown = STARTGAME_COUNTDOWN;
    UUID_it = lastPlayer().UUID;
    scores = new HashMap<Integer, PlayerStatus>();
    for (Player p : players.values()) scores.put(p.UUID, new PlayerStatus(startLife, (p.UUID != UUID_it) ? IMMUNE_TIME : 0, (p.UUID == UUID_it) ? INACTIVE_TIME : 0));
  }

  TagGame(String[] args) {
    this(DEFAULT_LIFE);
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
      else finishGame();
    }
  }

  void finishGame() {
    if (scores.size() == 0) {
      setGamemode(new Freeplay());
      return;
    }
    // Sort scores, in decreasing order
    List<Map.Entry<Integer, PlayerStatus>> scores_sorted = new ArrayList(scores.entrySet());
    Collections.sort(scores_sorted, new Comparator<Map.Entry<Integer, PlayerStatus>>() {
      public int compare(Map.Entry<Integer, PlayerStatus> o1, Map.Entry<Integer, PlayerStatus> o2) {
        return o2.getValue().life - o1.getValue().life;
      }
    }
    );

    Player winner = players.get(scores_sorted.get(0).getKey());
    // compute leaderboards, attribute scores
    scores_sorted.get(0).getValue().place = 1;
    winner.points += scores.size() - 1; // Give points!!
    for (int i = 1; i < scores_sorted.size(); i++) {
      PlayerStatus status = scores_sorted.get(i).getValue();
      PlayerStatus status_player_infront = scores_sorted.get(i-1).getValue();
      if (status.life == status_player_infront.life) status.place = status_player_infront.place;
      else status.place = 1+i;
      Player p = players.get(scores_sorted.get(i).getKey());
      p.points += scores.size() - status.place; // Give points!!
    }

    println("SERVER: scores for this game:");
    for (int i = 0; i < scores_sorted.size(); i++) {
      PlayerStatus status = scores_sorted.get(i).getValue();
      Player p = players.get(scores_sorted.get(i).getKey());
      println(i+" "+p.name+" place: "+status.place+" life: "+status.life);
    }

    sortPlayers();
    Leaderboard leaderboard = new Leaderboard();
    setGamemode(new Crowning(winner, leaderboard)); 
    println("SERVER: winner: "+winner.UUID+" "+winner);
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

  void respawn(Player p) {
    // Player p has resapwned, punish them hard
    PlayerStatus status_p = scores.get(p.UUID);
    if (status_p == null) return;
    PlayerStatus status_it = scores.get(UUID_it);
    status_it.immune = IMMUNE_TIME;
    status_p.inactive = INACTIVE_RESPAWN_TIME;
    UUID_it = p.UUID;
    TCP_SEND_ALL_CLIENTS(NOTIFY_GAMEMODE_UPDATE());
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
      int UUID_other = data.getInt();
      int UUID_tagger = (p.UUID == UUID_it) ? p.UUID : UUID_other;
      int UUID_tagged = (p.UUID == UUID_it) ? UUID_other : p.UUID;
      if (UUID_tagger != UUID_it) break;
      if (scores.get(UUID_tagger).inactive > 0) break;
      if (scores.get(UUID_tagged) == null) break;
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
