Gamemode gamemode;

void setGamemode(Gamemode newgamemode) {
  if (DEBUG_GAMEMODE) println("client: setting gamemode to "+newgamemode.getClass().getSimpleName());
  gamemode = newgamemode;
}

interface Gamemode {
  void update();
  void respawn();
  void beginContact(Contact cp);
  void INTERPRET(ByteBuffer data);
  void hud();
  void decorate(Rocket r);
}

class Disconnected implements Gamemode {
  void update() {
  }
  void respawn() {
  }
  void beginContact(Contact cp) {
  }
  void INTERPRET(ByteBuffer data) {
  }
  void hud() {
    fill(0);
    textAlign(LEFT, TOP);
    text("Disconnected...", 0, 0);
  }
  void decorate(Rocket r) {
  }
}

class Freeplay implements Gamemode {
  void update() {
  }
  void respawn() {
  }
  void beginContact(Contact cp) {
  }
  void INTERPRET(ByteBuffer data) {
  }
  void hud() {
    fill(0);
    textAlign(LEFT, TOP);
    text("Freeplay", 0, 0);
  }
  void decorate(Rocket r) {
  }
}

class TagGame implements Gamemode {
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
    int pos;
    float pos_ = 0;
    PlayerStatus prev;

    int life;
    int immune = 0;
    int inactive = 0;
    PlayerStatus(PlayerStatus prev, ByteBuffer data) {
      this.prev = prev;
      if (prev == null) pos = 0; 
      else pos = prev.pos + 1;
      println(pos, prev);
      prev = this;

      life = data.getInt();
      immune = data.getInt();
      inactive = data.getInt();
    }
  }

  void update() {
    if (startgame_countdown > 0) startgame_countdown--;
    else {
      PlayerStatus status_it = scores.get(UUID_it); 
      if (status_it.life > 0) status_it.life--;
      for (PlayerStatus status : scores.values()) {
        if (status.immune > 0) status.immune--;
        if (status.inactive > 0) status.inactive--;
      }
    }
  }

  void respawn() {
    client.write(new byte[]{(byte) 2, (byte)0});
  }

  void beginContact(Contact cp) {
    Fixture f1 = cp.getFixtureA();
    Fixture f2 = cp.getFixtureB();
    Body b1 = f1.getBody();
    Body b2 = f2.getBody();
    // Get objects that reference these bodies
    Object o1 = b1.getUserData();
    Object o2 = b2.getUserData();
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

  void NOTIFY_TAGGED_OTHER(int UUID) {
    ByteBuffer data = ByteBuffer.allocate(6);
    data.put((byte)2);
    data.put((byte)1);
    data.putInt(UUID);
    client.write(data.array());
  }

  void NOTIFY_CAPITULATE() {
    client.write(new byte[]{(byte)2, (byte)0});
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

  void decorate(Rocket r) {
    PlayerStatus status = scores.get(r.UUID);
    if (status == null) return;
    if (r.UUID == UUID_it) {
      noStroke();
      fill(255, 0, 0, 32);
      ellipse(0, 0, 320, 320);
      if (status.inactive > 0) {
        float angle = map(status.inactive, 0, inactiveTime, 0, PI);
        noFill();
        stroke(0);
        strokeWeight(3*10);
        arc(0, 0, 320, 320, -HALF_PI-angle, -HALF_PI+angle);
      }
    } else if (status.immune > 0) {
      float angle = map(status.immune, 0, immuneTime, 0, PI);
      noFill();
      stroke(#66D62B);
      strokeWeight(3*10);
      arc(0, 0, 320, 320, -HALF_PI-angle, -HALF_PI+angle);
    }
  }

  void hud() {
    if (startgame_countdown > 0) {
      textAlign(CENTER, CENTER);
      textSize(100);
      fill(0);
      text(1+(startgame_countdown/60), width/2, height/2);
    }

    pushMatrix();
    rectMode(CORNER);
    textAlign(LEFT, CENTER);
    textSize(18);
    int textvertcenter = 10;
    //for (PlayerStatus status : scores.values()) {
    for (Map.Entry entry : scores.entrySet()) {
      int UUID = (int)entry.getKey();
      PlayerStatus status = (PlayerStatus)entry.getValue();
      Rocket r = getRocket(UUID);
      if (r == null) continue;

      if (status.prev != null && status.prev.life < status.life) {
        status.pos -= 1;
        status.prev.pos += 1;
        PlayerStatus tmp = status.prev.prev;
        status.prev.prev = status;
        status.prev = tmp;
      }
      status.pos_ += (status.pos - status.pos_) * 0.2;

      pushMatrix();
      translate(0, status.pos_ * 24);
      if (UUID == UUID_it) {
        noStroke();
        fill(255, 0, 0, 32);
        rect(0, 0, 80 + 100, 24);
      }
      fill(0);
      text(status.pos+1, 3, textvertcenter);
      text(r.name, 20, textvertcenter);
      if (status.prev != null) text(status.prev.pos, 220, textvertcenter);

      int gap = 2;
      translate(80, 0);
      noStroke();
      fill(r.col);
      float w = map(status.life, 0, startLife, 0, 100 - 2*gap); 
      rect(gap, gap, w, 24 - 2*gap);
      fill(0);
      text(status.life/60, 6, textvertcenter);
      popMatrix();
    }
    popMatrix();
  }
}