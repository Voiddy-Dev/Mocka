import java.util.Collections;
import java.util.Comparator;
import java.util.Arrays;

Gamemode gamemode;

void setGamemode(Gamemode newgamemode) {
  respawnPos = new PVector(WIDTH/2, HEIGHT/2);
  if (DEBUG_GAMEMODE) println("client: setting gamemode to "+newgamemode.getClass().getSimpleName());
  if (gamemode != null) gamemode.kill();
  gamemode = newgamemode;
}

interface Gamemode {
  byte GAME_ID();
  void update();
  void respawn();
  void beginContact(Contact cp);
  void endContact(Contact cp);
  void INTERPRET(ByteBuffer data);
  void hud();
  void decoratePre(Rocket r);
  void decoratePost(Rocket r);
  void kill();
}

class CTF implements Gamemode {
  boolean DO_FLAG_STEALING, DO_FLAG_RELAY;

  boolean ready;
  int startgame_countdown;
  float BASE_RADIUS;

  int NUM_TEAMS;
  Team[] teams;

  PlayerStatus myStatus;

  HashMap<Integer, PlayerStatus> status;

  byte GAME_ID() {
    return 5;
  }
  CTF(ByteBuffer data) {
    byte mask = data.get();
    ready = (mask & 1) != 0;
    DO_FLAG_STEALING = (mask & 2) != 0;
    DO_FLAG_RELAY = (mask & 3) != 0;
    startgame_countdown = data.getInt();
    BASE_RADIUS = data.getFloat();

    NUM_TEAMS = data.getInt();
    teams = new Team[NUM_TEAMS];
    for (int i = 0; i < NUM_TEAMS; i++) teams[i] = new Team(data, i);

    int size = data.getInt();
    status = new HashMap<Integer, PlayerStatus>(size);
    for (int i = 0; i < size; i++) {
      int UUID = data.getInt();
      status.put(UUID, new PlayerStatus(UUID, data));
    }
    myStatus = status.get(myRocket.UUID);
    updateRelations();
    setRespawnPoint();
  }
  void setRespawnPoint() {
    if (startgame_countdown > 0) return;
    PlayerStatus myStatus = status.get(myRocket.UUID);
    if (myStatus == null) return;
    Team myTeam = teams[myStatus.team];
    respawnPos = new PVector(myTeam.x, myTeam.y - BASE_RADIUS - 15);
  }
  void kill() {
    for (Team t : teams) box2d.destroyBody(t.body);
  }

  class Team {
    byte id;
    color col;
    boolean flag_at_home;
    int flag_bearer_UUID;
    Body body;
    float x, y;

    Team(ByteBuffer data, int id) {
      this.id = (byte)id;
      col = data.getInt();
      x = data.getFloat();
      y = data.getFloat();
      flag_at_home = data.get() != 0;
      flag_bearer_UUID = data.getInt();

      // Create body
      CircleShape sd = new CircleShape();
      float b2dr = box2d.scalarPixelsToWorld(BASE_RADIUS);
      sd.setRadius(b2dr);
      BodyDef bd = new BodyDef();
      bd.type = BodyType.STATIC;
      bd.position.set(box2d.coordPixelsToWorld(x, y));
      body = box2d.createBody(bd);
      body.createFixture(sd, 1);
      body.getFixtureList().setSensor(true);

      body.setUserData(this);
    }
    void setPos(float x, float y) {
      this.x = x;
      this.y = y;
      body.setTransform(box2d.coordPixelsToWorld(x, y), 0);
    }
    int activecount = 0;
    public void show() {
      pushMatrix();
      translate(x, y);
      if (flag_at_home) activecount++;
      scale(1 + 0.01*sin(activecount/18.));
      noStroke();
      if (flag_at_home) fill(col, 120);
      else fill(col, 30);
      ellipse(0, 0, 2*BASE_RADIUS, 2*BASE_RADIUS);

      if (flag_at_home) {
        pushMatrix();
        scale(0.18);
        //fill(255);
        //ellipse(0, 0, 320, 320);
        fill(col);
        noStroke();
        translate(-50, 65); // center of hublot
        //rotate(radians(30)*sin(degrees(30*activecount)+frameCount/18.));
        rectMode(CENTER);
        rect(50, -160+40-4, 100, 80);
        stroke(0);
        strokeWeight(20);
        line(0, 0, 0, -160);
        popMatrix();
      }

      rotate(activecount/180.);
      int ARC_COUNT = 9;
      float ARC_SIZE = PI / ARC_COUNT;
      noFill();
      if (flag_at_home) stroke(col);
      else stroke(col, 80);
      strokeWeight(4);
      for (int i = 0; i < ARC_COUNT; i++) { // make this a PShape preferably?
        arc(0, 0, 2*BASE_RADIUS, 2*BASE_RADIUS, 0, ARC_SIZE);
        rotate(2*ARC_SIZE);
      }
      popMatrix();
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
    if (!myTeam.flag_at_home && myTeam.flag_bearer_UUID == oStatus.UUID) oVulnerability += 4;
    if (!oTeam.flag_at_home && oTeam.flag_bearer_UUID == myStatus.UUID) myVulnerability += 4;
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
    //Rocket r;
    int UUID;

    byte team, loc;
    int capture_count, protected_count, jailed_count, jailing_count;

    boolean hasOwnFlag, isAtHome;
    byte flagCount;
    byte relation = 0;
    // -2: they'll murder us (don't collide)
    // -1: they'll steal from us
    //  0: nothing - just neutral
    //  1: we'll steal from them
    //  2: we'll murder them (don't collide)

    PlayerStatus(int UUID, ByteBuffer data) {
      this.UUID = UUID;
      //r = getRocket(UUID);
      team = data.get();
      loc = data.get();
      capture_count = data.getInt();
      protected_count = data.getInt();
      jailed_count = data.getInt();
      jailing_count = data.getInt();
    }

    void updateStatus() {
      hasOwnFlag = !teams[team].flag_at_home && teams[team].flag_bearer_UUID == UUID;
      isAtHome = loc == team;
      flagCount = 0;
      for (Team t : teams) if (!t.flag_at_home && t.flag_bearer_UUID == UUID) flagCount++;
      if (DEBUG_GAMEMODE) println("client: CTF: Updated status for player "+UUID+" hasOwnFlag = "+hasOwnFlag+"  isAtHome = "+isAtHome+"   flagCount = "+flagCount);
    }
    void updateRelation() {
      relation = computeRelation(myStatus, this);
      if (DEBUG_GAMEMODE) println("client: CTF: Updated relation for player "+UUID+" relation = "+relation);
      //if (DEBUG_GAMEMODE) println("RELATION: myVuln = "+myVulnerability+"      oVuln = "+oVulnerability);

      Rocket r = getRocket(UUID);
      if (r == null) return;
      r.body.getFixtureList().setSensor(relation == (byte)2);
    }
  }

  void updateRelations() {
    PlayerStatus myStatus = status.get(myRocket.UUID);
    if (myStatus == null) return;
    if (DEBUG_GAMEMODE) println("clinet: CTF: updating relations");
    for (PlayerStatus oStatus : status.values()) oStatus.updateRelation();
  }

  byte loc = -1, loc_ = -1;

  void update() {
    loc = 0;
    if (myRocket.x >= WIDTH/2) loc++;
    if (NUM_TEAMS == 4 && myRocket.y >= HEIGHT/2) loc += 2;
    if (loc != loc_) {
      loc_ = loc;
      if (startgame_countdown > 0) NOTIFY_MYTEAM(loc);
      NOTIFY_LOC(loc);
    }

    if (!ready) return;
    if (startgame_countdown > 0) {
      startgame_countdown--;
      if (startgame_countdown == 0) setRespawnPoint();
    } else {
    }
  }

  void NOTIFY_MYTEAM(byte loc) {
    client.write(new byte[]{(byte)2, GAME_ID(), (byte)0, (byte)2, (byte)0, loc});
  }
  void NOTIFY_LOC(byte loc) {
    client.write(new byte[]{(byte)2, GAME_ID(), (byte)0, (byte)2, (byte)2, loc});
  }
  void NOTIFY_BASE_LOC() {
    ByteBuffer data = ByteBuffer.allocate(13);
    data.put((byte)2);          // Packet ID for GAMEMODE_UPDATE
    data.put(GAME_ID());        // Byte for Gamemode ID
    data.putShort((short)9);    // Length of message
    data.put((byte)1);          // Message ID (specific to this gamemode)
    data.putFloat(myRocket.x);
    data.putFloat(myRocket.y);
    client.write(data.array());
  }

  void respawn() {
    if (startgame_countdown > 0) NOTIFY_BASE_LOC();
  }
  void beginContact(Contact cp) {
    if (startgame_countdown > 0) return;
    Object o1 = cp.getFixtureA().getBody().getUserData();
    Object o2 = cp.getFixtureB().getBody().getUserData();
    if (o1 != myRocket && o2 != myRocket) return; // does not concern us (ie our player-local simulation)
    Object other;
    if (o1 == myRocket) other = o2;
    else other = o1;
    if (other instanceof Team) {
      Team t = (Team)other;
      client.write(new byte[]{2, GAME_ID(), 0, 2, 5, t.id});
    } else if (other instanceof EnemyRocket) {
      EnemyRocket enemy = (EnemyRocket)other;
      PlayerStatus myStatus = status.get(myRocket.UUID);
      PlayerStatus enemyStatus = status.get(enemy.UUID);
      if (myStatus == null || enemyStatus == null) return;
      if (DEBUG_GAMEMODE) println("client: CTF: Contact with enemy: relation : "+enemyStatus.relation);
      if (enemyStatus.relation == (byte)-1) NOTIFY_THEFT(enemy.UUID, myRocket.UUID);
      if (enemyStatus.relation == (byte)1) NOTIFY_THEFT(myRocket.UUID, enemy.UUID);
      if (enemyStatus.relation == (byte)-2) NOTIFY_MURDER(enemy.UUID, myRocket.UUID);
      if (enemyStatus.relation == (byte)2) NOTIFY_MURDER(myRocket.UUID, enemy.UUID);
    }
  }

  void NOTIFY_THEFT(int theif_UUID, int victim_UUID) {
    ByteBuffer data = ByteBuffer.allocate(13);
    data.put((byte)2);       // GAMEMODE_UPDATE packet ID
    data.put(GAME_ID());     // gamemode ID
    data.putShort((short)8); // message length
    data.put((byte)3);       // message ID (NOTIFY_THEFT)
    data.putInt(theif_UUID);
    data.putInt(victim_UUID);
    client.write(data.array());
  }

  void NOTIFY_MURDER(int murderer_UUID, int victim_UUID) {
    ByteBuffer data = ByteBuffer.allocate(13);
    data.put((byte)2);       // GAMEMODE_UPDATE packet ID
    data.put(GAME_ID());     // gamemode ID
    data.putShort((short)8); // message length
    data.put((byte)4);       // message ID (NOTIFY_THEFT)
    data.putInt(murderer_UUID);
    data.putInt(victim_UUID);
    client.write(data.array());
  }

  void endContact(Contact cp) {
  }

  void INTERPRET(ByteBuffer data) {
    byte MSG_ID = data.get();
    if (MSG_ID == 0) INTERPRET_P_TEAM(data);
    else if (MSG_ID == 1) INTERPRET_T_LOC(data);
    else if (MSG_ID == 2) INTERPRET_P_LOC(data);
    else if (MSG_ID == 3) INTERPRET_T_FLAG(data);
    else if (MSG_ID == 4) INTERPRET_CTF_READY(data);
  }
  void INTERPRET_P_TEAM(ByteBuffer data) {
    int UUID = data.getInt();
    PlayerStatus s = status.get(UUID);
    s.team = data.get();
    s.updateStatus();
    if (s == myStatus) updateRelations();
    else s.updateRelation();
  }
  void INTERPRET_T_LOC(ByteBuffer data) {
    Team team = teams[data.get()];
    float x = data.getFloat();
    float y = data.getFloat();
    team.setPos(x, y);
    if (DEBUG_GAMEMODE) println("client: CTF: team "+team.id+"'s base is now at "+x+","+y);
  }
  void INTERPRET_P_LOC(ByteBuffer data) {
    int UUID = data.getInt();
    PlayerStatus s = status.get(UUID);
    s.loc = data.get();
    if (DEBUG_GAMEMODE) println("client: CTF: "+UUID+" is now loc = "+s.loc);
    s.updateStatus();
    if (s == myStatus) updateRelations();
    else s.updateRelation();
  }
  void INTERPRET_T_FLAG(ByteBuffer data) {
    Team team = teams[data.get()];
    PlayerStatus old_bearer = !team.flag_at_home ? status.get(team.flag_bearer_UUID) : null;
    team.flag_at_home = data.get() != 0;
    team.flag_bearer_UUID = data.getInt();
    PlayerStatus new_bearer = !team.flag_at_home ? status.get(team.flag_bearer_UUID) : null;
    if (old_bearer != null) old_bearer.updateStatus();
    if (new_bearer != null) new_bearer.updateStatus();
    if (old_bearer == myStatus ||new_bearer == myStatus) updateRelations();
    else {
      if (old_bearer != null) old_bearer.updateRelation();
      if (new_bearer != null) new_bearer.updateRelation();
    }
  }
  void INTERPRET_CTF_READY(ByteBuffer data) {
    ready = data.get() != 0;
    startgame_countdown = data.getInt();
  }

  void hud() {
    rectMode(CORNER);
    noStroke();
    if (NUM_TEAMS == 2) {
      fill(teams[0].col, 10);
      rect(0, 0, WIDTH/2, HEIGHT);
      fill(teams[1].col, 10);
      rect(WIDTH/2, 0, WIDTH/2, HEIGHT);
    } else {
      fill(teams[0].col, 10);
      rect(0, 0, WIDTH/2, HEIGHT/2);
      fill(teams[1].col, 10);
      rect(WIDTH/2, 0, WIDTH/2, HEIGHT/2);
      fill(teams[2].col, 10);
      rect(0, HEIGHT/2, WIDTH/2, HEIGHT/2);
      fill(teams[3].col, 10);
      rect(WIDTH/2, HEIGHT/2, WIDTH/2, HEIGHT/2);
    }
    strokeWeight(5);
    stroke(128, 50);
    line(WIDTH/2, 0, WIDTH/2, HEIGHT);
    if (NUM_TEAMS == 4) line(0, HEIGHT/2, WIDTH, HEIGHT/2);

    for (Team t : teams) t.show();

    if (startgame_countdown > 0) {
      textAlign(CENTER, CENTER);
      textSize(100);
      fill(100); // start game counter is gray
      String text;
      if (ready) text = ""+(1+(startgame_countdown/60));
      else {
        text = "Place all bases to begin";
        textSize(30);
      }
      text(text, WIDTH/2, HEIGHT/2);
    }
  }

  void decoratePre(Rocket r) {
    PlayerStatus s = status.get(r.UUID);
    if (s == null) return;

    color col = teams[s.team].col;
    strokeWeight(15);
    stroke(col);
    fill(col, 50);
    ellipse(0, 0, 320, 320);
  }
  void decoratePost(Rocket r) {
    // Overlay flags on rocket
    int count = 0; // offset flags if carrying multiples
    for (Team t : teams) {
      if (t.flag_at_home) continue;
      if (t.flag_bearer_UUID != r.UUID) continue;
      pushMatrix();
      fill(t.col);
      noStroke();
      translate(0, -45); // center of hublot
      rotate(radians(30)*sin(degrees(30*count)+frameCount/18.));
      rect(50, -160+40-4, 100, 80);
      stroke(0);
      strokeWeight(20);
      line(0, 0, 0, -160);
      popMatrix();
      count ++;
    }

    PlayerStatus s = status.get(r.UUID);
    if (s == null) return;
    // visual representation of relation
    rotate(r.angle);
    float timeAngle = frameCount/30. + r.UUID;
    float angle = radians(15)*sin(timeAngle);
    rotate(angle);
    if (s.relation == (byte)2) shape(targetShape);
    if (s.relation == (byte)-2) shape(angerShape);
  }
}

class Disconnected implements Gamemode {
  byte GAME_ID() {
    return -1;
  }
  void update() {
  }
  void respawn() {
  }
  void beginContact(Contact cp) {
  }
  void endContact(Contact cp) {
  }
  void INTERPRET(ByteBuffer data) {
  }
  void hud() {
    pushMatrix();
    fill(255, 0, 0); // Red error text
    textAlign(CENTER);
    translate(WIDTH/2, HEIGHT/2);
    text("Disconnected...\nServer is probably offline!", 0, 0);
    popMatrix();
  }
  void decoratePre(Rocket r) {
  }
  void decoratePost(Rocket r) {
  }
  void kill() {
  }
}

class Leaderboard implements Gamemode {
  byte GAME_ID() {
    return 3;
  }
  Earning[] earnings;
  Leaderboard(ByteBuffer data) {
    boolean is_fresh = data.get() != (byte)0;
    int size = data.getInt();
    earnings = new Earning[size];
    for (int i = 0; i < earnings.length; i++) earnings[i] = new Earning(is_fresh, data.getInt(), data.getInt(), data.getInt());
    Arrays.sort(earnings, new Comparator<Earning>() {
      public int compare(Earning e1, Earning e2) {
        return e2.points - e1.points;
      }
    }
    );
  }
  void update() {
  }
  void respawn() {
  }
  void beginContact(Contact cp) {
  }
  void endContact(Contact cp) {
  }
  void INTERPRET(ByteBuffer data) {
  }
  void hud() {
    pushMatrix();
    translate(WIDTH/2, HEIGHT/2);

    // outer box
    rectMode(CENTER);
    //color of background
    fill(0, 255, 0, 30);
    stroke(0); // surround it
    strokeWeight(2);
    rect(0, 0, 400, 50 * earnings.length);

    // boxes inside big box
    for (int i = 0; i < earnings.length; i++) {
      // get specific player
      Earning e = earnings[i];
      Rocket r = e.r;
      if (r == null) continue; // make sure he exists

      stroke(0);
      // Find outer box of name and place and everything
      pushMatrix();
      translate(0, (50 * i) - (25*earnings.length) + 25);
      fill(0, 255, 0, 30);
      rect(0, 0, 400, 50); // outer box withing big box

      fill(0, 0, 255, 50);
      rect(-175, 0, 50, 50);  // draw place box in blue
      fill(0);
      textSize(30);
      // writing place text
      text(String.valueOf(r.place), -175, -5, 50, 50 + 5); // 7 --> small offset to make it better

      // going up or down
      fill(255);
      rect(-120, 0, 60, 50); // going up or down
      pushMatrix();
      translate(-138, 0);
      noStroke();
      if (e.places_won < 0) {
        fill(255, 0, 0);
        triangle(-7, -5, 7, -5, 0, 5); // red triangle
      } else if (e.places_won > 0) {
        fill(0, 255, 0);
        triangle(-7, 5, 7, 5, 0, -5); // green triangle
      } else {
        fill(128);
        rect(0, 0, 14, 4);
      }
      popMatrix();
      fill(0);
      textSize(15);
      // printing out places
      if (e.places_won > 0) text("+" + String.valueOf(e.places_won), -110, -3, 40, 50);
      else text(String.valueOf(e.places_won), -110, -3, 40, 50);

      // adding colors to name
      fill(e.r.col);
      ellipse(-70, 0, 20, 20);

      stroke(0);

      // Adding Points and scores
      fill(255);
      rect(155, 0, 75, 40, 40); // added rounded rectangle
      textSize(25);
      fill(0);
      text(String.valueOf(e.r.points), 140, -4, 50, 40); // adding points
      textSize(15);
      if (e.points_won > 0) text("+" + String.valueOf(e.points_won), 170, -3, 50, 40);
      else text(String.valueOf(e.points_won), 170, -3, 50, 40);

      // Adding name
      textSize(30);
      text(e.r.name, -10, -4, 100, 50);

      popMatrix();
    }
    popMatrix();
  }
  void decoratePre(Rocket r) {
  }
  void decoratePost(Rocket r) {
  }
  class Earning {
    int UUID, points_won, places_won;
    Rocket r;
    int points;
    Earning(boolean is_fresh, int UUID, int points_won, int places_won) {
      this.UUID = UUID;
      this.points_won = points_won;
      this.places_won = places_won;
      r = getRocket(UUID);
      if (r == null) points = 0;
      else {
        if (is_fresh) {
          //r.points += points_won;
          //r.place += places_won;
        }
        points = r.points;
      }
    }
  }
  void kill() {
  }
}

class Freeplay implements Gamemode {
  byte GAME_ID() {
    return 0;
  }
  void update() {
  }
  void respawn() {
  }
  void beginContact(Contact cp) {
  }
  void endContact(Contact cp) {
  }
  void INTERPRET(ByteBuffer data) {
  }
  void hud() {
    fill(255); // White text on black background
    textAlign(LEFT, TOP);
    text("Freeplay", 0, 0);
    text(round(frameRate), 0, 20);
  }
  void decoratePre(Rocket r) {
  }
  void decoratePost(Rocket r) {
  }
  void kill() {
  }
}

class Crowning implements Gamemode {
  byte GAME_ID() {
    return 2;
  }
  Rocket victor;
  Crowning(ByteBuffer data) {
    int UUID = data.getInt();
    println(UUID);
    this.victor = getRocket(UUID);
  }
  void update() {
  }
  void respawn() {
  }
  void beginContact(Contact cp) {
  }
  void endContact(Contact cp) {
  }
  void INTERPRET(ByteBuffer data) {
  }
  void hud() {
  }
  int FRAMES = 0;
  void decoratePre(Rocket r) {
  }
  void decoratePost(Rocket r) {
    pushStyle();
    if (r != victor) return;
    FRAMES--;
    if (FRAMES <= 0) {
      FRAMES = (int)random(10, 45);
      PVector pos = new PVector(random(WIDTH), random(HEIGHT - 100));
      for (int i = 0; i < 40; i++) {
        PVector vel = new PVector(0.3, 0).rotate(random(TAU));
        r.exhaust.turnOn(pos, vel, new PVector(0, 0));
      }
    }
    // Crown time!
    noStroke();
    fill(212, 175, 55);
    translate(0, -114);
    //translate(0, -154);
    beginShape();
    vertex(62, 15);
    vertex(87, -40);
    vertex(24, -21);
    vertex(0, -80);
    vertex(-24, -21);
    vertex(-87, -40);
    vertex(-62, 15);
    endShape(CLOSE);
    // emerald
    translate(0, -10);
    rectMode(CENTER);
    fill(r.col);
    rotate(QUARTER_PI);
    rect(0, 0, 33, 33);
    popStyle();
  }
  void kill() {
  }
}



//  ______ _             _    _____
// |  ____| |           | |  / ____|
// | |__  | | ___   __ _| |_| |  __  __ _ _ __ ___   ___
// |  __| | |/ _ \ / _` | __| | |_ |/ _` | '_ ` _ \ / _ \
// | |    | | (_) | (_| | |_| |__| | (_| | | | | | |  __/
// |_|    |_|\___/ \__,_|\__|\_____|\__,_|_| |_| |_|\___|


class FloatGame implements Gamemode {
  byte GAME_ID() {
    return 4;
  }
  int life_goal;
  int startgame_countdown;

  HashMap<Integer, PlayerStatus> scores;

  FloatGame(ByteBuffer data) {
    life_goal = data.getInt();
    startgame_countdown = data.getInt();
    int size = data.getInt();
    scores = new HashMap<Integer, PlayerStatus>();
    PlayerStatus prev = null;
    for (int i = 0; i < size; i++) scores.put(data.getInt(), prev = new PlayerStatus(prev, data));
    if (DEBUG_GAMEMODE) println("client: finished setting up Taggame!");
    NOTIFY_TOUCHING_PLATFORMS(myRocket.TOUCHING_PLATFORMS);
  }

  class PlayerStatus {
    int place;
    int pos;
    float pos_ = 0;
    PlayerStatus prev, next;

    boolean in_air;
    int life;
    PlayerStatus(PlayerStatus prev, ByteBuffer data) {
      place = 1;
      next = null;
      this.prev = prev;
      if (prev == null) pos = 0;
      else {
        pos = prev.pos + 1;
        prev.next = this;
      }
      life = data.getInt();
      in_air = data.get() != 0;
    }
  }

  void update() {
    if (startgame_countdown > 0) startgame_countdown--;
    else {
      for (PlayerStatus status : scores.values()) if (status.in_air) status.life++;
    }
  }

  void respawn() {
    NOTIFY_TOUCHING_PLATFORMS(myRocket.TOUCHING_PLATFORMS);
  }

  void beginContact(Contact cp) {
    NOTIFY_TOUCHING_PLATFORMS(myRocket.TOUCHING_PLATFORMS);
  }
  void endContact(Contact cp) {
    NOTIFY_TOUCHING_PLATFORMS(myRocket.TOUCHING_PLATFORMS);
  }

  void NOTIFY_TOUCHING_PLATFORMS(int count) {
    client.write(new byte[]{(byte)2, GAME_ID(), (byte)0, (byte)1, (byte)count});
  }

  void INTERPRET(ByteBuffer data) {
    println("Interpretting and update.......");
    startgame_countdown = data.getInt();
    int size = data.getInt();
    for (int i = 0; i < size; i++) {
      int UUID = data.getInt();
      PlayerStatus status = scores.get(UUID);
      status.life = data.getInt();
      status.in_air = data.get() != 0;
    }
  }

  void decoratePre(Rocket r) {
  }
  void decoratePost(Rocket r) {
    PlayerStatus status = scores.get(r.UUID);
    if (status == null) return;
    strokeWeight(30);
    if (status.in_air) stroke(r.col);
    else stroke(r.col, 100);
    noFill();
    rotate(r.body.getAngle());
    float angle = status.life * HALF_PI / 60;
    arc(0, 0, 320, 320, angle, angle+QUARTER_PI);
    arc(0, 0, 320, 320, angle+HALF_PI, angle+3*QUARTER_PI);
    arc(0, 0, 320, 320, angle+PI, angle+PI+QUARTER_PI);
    arc(0, 0, 320, 320, angle+3*HALF_PI, angle+TAU-QUARTER_PI);
  }

  void hud() {
    if (startgame_countdown > 0) {
      textAlign(CENTER, CENTER);
      textSize(100);
      fill(100); // Start game counter is gray
      text(1+(startgame_countdown/60), WIDTH/2, HEIGHT/2);
    }

    rectMode(CORNER);
    textAlign(LEFT, CENTER);
    textSize(18);

    fill(255, 64); // I guess a transparent white background box is fine
    noStroke();
    rect(0, 0, 180, 24 * scores.size());

    int textvertcenter = 10;
    //for (PlayerStatus status : scores.values()) {
    for (Map.Entry entry : scores.entrySet()) {
      int UUID = (int)entry.getKey();
      PlayerStatus status = (PlayerStatus)entry.getValue();
      Rocket r = getRocket(UUID);
      if (r == null) continue;

      if (status.prev != null && status.prev.life < status.life) {
        PlayerStatus status_next = status.next;
        PlayerStatus status_prev = status.prev;
        PlayerStatus status_prev_prev = status_prev.prev;
        // prev pointers
        status.prev = status_prev_prev;
        status_prev.prev = status;
        if (status_next != null) status_next.prev = status_prev;
        // next pointers
        status_prev.next = status_next;
        status.next = status_prev;
        if (status_prev_prev != null) status_prev_prev.next = status;
        // vertical pos
        status.pos -= 1;
        status_prev.pos += 1;
        // place
        status.place = status_prev.place;
        PlayerStatus s = status_prev;
        while (s.prev != null) {
          s.place = s.prev.place + ((s.prev.life == s.life) ? 0 : 0);
          s = s.prev;
        }
      }
      status.pos_ += (status.pos - status.pos_) * 0.2;

      pushMatrix();
      translate(0, status.pos_ * 24);
      /*if (UUID == UUID_it) {
       noStroke();
       fill(255, 0, 0, 32);
       rect(0, 0, 80 + 100, 24);
       }*/
      fill(255); // White text I guess
      text(status.place, 3, textvertcenter);
      text(r.name, 20, textvertcenter);
      //if (status.prev != null) text(status.prev.pos, 220, textvertcenter);

      int gap = 2;
      translate(80, 0);
      noStroke();
      fill(r.col);
      float w = map(status.life, 0, life_goal, 0, 100 - 2*gap);
      rect(gap, gap, w, 24 - 2*gap);
      fill(255); // Again white text I guess
      text(status.life/60, 6, textvertcenter);
      popMatrix();
    }
  }
  void kill() {
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
  byte GAME_ID() {
    return 1;
  }
  int startLife, immuneTime, inactiveTime;
  int startgame_countdown;

  int UUID_it;
  HashMap<Integer, PlayerStatus> scores;

  TagGame(ByteBuffer data) {
    startLife = data.getInt();
    immuneTime = data.getInt();
    inactiveTime = data.getInt();
    startgame_countdown = data.getInt();
    UUID_it = data.getInt();
    int size = data.getInt();
    scores = new HashMap<Integer, PlayerStatus>();
    PlayerStatus prev = null;
    for (int i = 0; i < size; i++) scores.put(data.getInt(), prev = new PlayerStatus(prev, data));
    if (DEBUG_GAMEMODE) println("client: finished setting up Taggame!");
  }

  class PlayerStatus {
    int place;
    int pos;
    float pos_ = 0;
    PlayerStatus prev, next;

    int life;
    int immune = 0;
    int inactive = 0;
    PlayerStatus(PlayerStatus prev, ByteBuffer data) {
      place = 1;
      next = null;
      this.prev = prev;
      if (prev == null) pos = 0;
      else {
        pos = prev.pos + 1;
        prev.next = this;
      }
      life = data.getInt();
      immune = data.getInt();
      inactive = data.getInt();
    }
  }

  void update() {
    if (startgame_countdown > 0) startgame_countdown--;
    else {
      PlayerStatus status_it = scores.get(UUID_it);
      if (status_it != null && status_it.life > 0) status_it.life--;
      for (PlayerStatus status : scores.values()) {
        if (status.immune > 0) status.immune--;
        if (status.inactive > 0) status.inactive--;
      }
    }
  }

  void respawn() {
  }

  void beginContact(Contact cp) {
    Object o1 = cp.getFixtureA().getBody().getUserData();
    Object o2 = cp.getFixtureB().getBody().getUserData();
    if (o1 != myRocket && o2 != myRocket) return; // does not concern us (ie our player-local simulation)
    EnemyRocket enemy;
    if (o1 instanceof EnemyRocket) enemy = (EnemyRocket) o1;
    else if (o2 instanceof EnemyRocket) enemy = (EnemyRocket) o2;
    else return;
    //println(enemy.UUID);
    PlayerStatus myStatus = scores.get(myRocket.UUID);
    if (myStatus == null) return;
    PlayerStatus otherStatus = scores.get(enemy.UUID);
    if (otherStatus == null) return;
    if (myRocket.UUID == UUID_it && myStatus.inactive == 0 && otherStatus.immune == 0) NOTIFY_TAGGED_OTHER(enemy.UUID);
    else if (enemy.UUID == UUID_it && otherStatus.inactive == 0 && myStatus.immune == 0) NOTIFY_TAGGED_OTHER(enemy.UUID);
  }
  void endContact(Contact cp) {
  }

  void NOTIFY_TAGGED_OTHER(int UUID) {
    ByteBuffer data = ByteBuffer.allocate(9);
    data.put((byte)2);
    data.put(GAME_ID());
    data.putShort((short)5);
    data.put((byte)1);
    data.putInt(UUID);
    client.write(data.array());
  }

  void NOTIFY_CAPITULATE() {
    client.write(new byte[]{(byte)2, GAME_ID(), (byte)0, (byte)1, (byte)0});
  }

  void INTERPRET(ByteBuffer data) {
    println("Interpretting and update.......");
    UUID_it = data.getInt();
    int size = data.getInt();
    for (int i = 0; i < size; i++) {
      int UUID = data.getInt();
      PlayerStatus status = scores.get(UUID);
      status.life = data.getInt();
      status.immune = data.getInt();
      status.inactive = data.getInt();
    }
  }

  void decoratePre(Rocket r) {
  }
  void decoratePost(Rocket r) {
    PlayerStatus status = scores.get(r.UUID);
    if (status == null) return;
    if (r.UUID == UUID_it) {
      strokeWeight(15);
      stroke(255, 0, 0); // Red outline
      fill(255, 0, 0, 50); // Red transparent fill - because this player is IT so show it with a menacing red color
      ellipse(0, 0, 320, 320);
      noStroke();
      fill(255, 0, 0, 20); // Again yet more red
      ellipse(0, 0, 520, 520);
      if (status.inactive > 0) {
        float angle = map(status.inactive, 0, inactiveTime, 0, PI);
        noFill();
        stroke(0); // Yeah I think this is good enough for now
        strokeWeight(3*10);
        arc(0, 0, 320, 320, -HALF_PI-angle, -HALF_PI+angle);
      }
    } else if (status.immune > 0) {
      float angle = map(status.immune, 0, immuneTime, 0, PI);
      noFill();
      stroke(#66D62B); // You're immune so you're green
      strokeWeight(3*10);
      arc(0, 0, 320, 320, -HALF_PI-angle, -HALF_PI+angle);
    }
  }

  void hud() {
    if (startgame_countdown > 0) {
      textAlign(CENTER, CENTER);
      textSize(100);
      fill(100); // Again gray countdown
      text(1+(startgame_countdown/60), WIDTH/2, HEIGHT/2);
    }

    rectMode(CORNER);
    textAlign(LEFT, CENTER);
    textSize(18);

    fill(255, 64); // Fine I guess
    noStroke();
    rect(0, 0, 180, 24 * scores.size());

    int textvertcenter = 10;
    //for (PlayerStatus status : scores.values()) {
    for (Map.Entry entry : scores.entrySet()) {
      int UUID = (int)entry.getKey();
      PlayerStatus status = (PlayerStatus)entry.getValue();
      Rocket r = getRocket(UUID);
      if (r == null) continue;

      if (status.prev != null && status.prev.life < status.life) {
        PlayerStatus status_next = status.next;
        PlayerStatus status_prev = status.prev;
        PlayerStatus status_prev_prev = status_prev.prev;
        // prev pointers
        status.prev = status_prev_prev;
        status_prev.prev = status;
        if (status_next != null) status_next.prev = status_prev;
        // next pointers
        status_prev.next = status_next;
        status.next = status_prev;
        if (status_prev_prev != null) status_prev_prev.next = status;
        // vertical pos
        status.pos -= 1;
        status_prev.pos += 1;
        // place
        status.place = status_prev.place;
        PlayerStatus s = status_prev;
        while (s.prev != null) {
          s.place = s.prev.place + ((s.prev.life == s.life) ? 0 : 0);
          s = s.prev;
        }
      }
      status.pos_ += (status.pos - status.pos_) * 0.2;

      pushMatrix();
      translate(0, status.pos_ * 24);
      if (UUID == UUID_it) {
        noStroke();
        fill(255, 0, 0, 32);
        rect(0, 0, 80 + 100, 24);
      }
      fill(255); // White text on black background
      text(status.place, 3, textvertcenter);
      text(r.name, 20, textvertcenter);
      //if (status.prev != null) text(status.prev.pos, 220, textvertcenter);

      int gap = 2;
      translate(80, 0);
      noStroke();
      fill(r.col);
      float w = map(status.life, 0, startLife, 0, 100 - 2*gap);
      rect(gap, gap, w, 24 - 2*gap);
      fill(255); // White text
      text(status.life/60, 6, textvertcenter);
      popMatrix();
    }
  }
  void kill() {
  }
}

//  _____
// |  __ \
// | |__) |   _ _ __  _ __   ___ _ __
// |  _  / | | | '_ \| '_ \ / _ \ '__|
// | | \ \ |_| | | | | | | |  __/ |
// |_|  \_\__,_|_| |_|_| |_|\___|_|

class Runner implements Gamemode {
  Runner(ByteBuffer data) {
  }
  byte GAME_ID() {
    return 7;
  }
  void update() {
  }
  void respawn() {
  }
  void beginContact(Contact cp) {
  }
  void endContact(Contact cp) {
  }
  void INTERPRET(ByteBuffer data) {
  }
  void hud() {
  }
  void decoratePre(Rocket r) {
  }
  void decoratePost(Rocket r) {
  }
  void kill() {
  }
}
