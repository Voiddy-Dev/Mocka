Gamemode gamemode;

void setGamemode(Gamemode newgamemode) {
  if (DEBUG_GAMEMODE) println("client: setting gamemode to "+newgamemode.getClass().getSimpleName());
  gamemode = newgamemode;
}

interface Gamemode {
  void update();
  void respawn();
  void hud();
  void decorate(Rocket r);
}

class Disconnected implements Gamemode {
  void update() {
  }
  void respawn() {
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
  void hud() {
    fill(0);
    textAlign(LEFT, TOP);
    text("Freeplay", 0, 0);
  }
  void decorate(Rocket r) {
  }
}

class TagGame implements Gamemode {
  int startLife;
  int startgame_countdown;
  int UUID_it;
  HashMap<Integer, PlayerStatus> scores;

  TagGame(ByteBuffer data) {
    startLife = data.getInt();
    startgame_countdown = data.getInt();
    UUID_it = data.getInt();
    int size = data.getInt();
    scores = new HashMap<Integer, PlayerStatus>();
    PlayerStatus prev = null;
    for (int i = 0; i < size; i++) prev = scores.put(data.getInt(), new PlayerStatus(prev, data));
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

      life = data.getInt();
      immune = data.getInt();
      inactive = data.getInt();
    }
  }

  void update() {
    if (startgame_countdown > 0) startgame_countdown--;
    else {
      PlayerStatus status = scores.get(UUID_it); 
      if (status.life > 0) status.life--;
    }
  }

  void respawn() {
    client.write(new byte[]{(byte) 2, (byte)3});
  }

  void decorate(Rocket r) {
    if (r.UUID == UUID_it) {
      noStroke();
      fill(255, 0, 0, 32);
      ellipse(0, 0, 320, 320);
    }
  }

  void hud() {
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

      if (status.prev != null && status.prev.life < status.life) {
        status.pos -= 1;
        status.prev.pos += 1;
        PlayerStatus tmp = status.prev.prev;
        status.prev = status;
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

  void hud_() {

    pushStyle();
    pushMatrix();
    int num_entries = 1 + enemies.size();
    int rows = 2;
    int cols = max(1, (num_entries - 1) / rows);
    float w = min(300, float(width) / cols);
    float h = float(100) / rows;
    float remaining_width = w - h*2.6;
    Iterator<Rocket> it = allRockets();
    int i = 0;
    int j = 0;
    textSize(16);
    strokeWeight(5);
    translate(0, height-100);
    while (it.hasNext()) {
      Rocket r = it.next();
      PlayerStatus status = scores.get(r.UUID);
      if (status == null) continue;
      color bgcol = r.UUID == UUID_it ? color(255, 222, 222) : color(255);
      pushMatrix();
      translate(i*w, j*h);
      noFill();
      //stroke(128);
      noStroke();
      rect(w/2, h/2, w, h);

      // Leaderboard
      fill(bgcol);
      stroke(r.col);
      ellipse(h*0.5, h*0.5, h*0.75, h*0.75);

      // Name
      translate(h * 0.75, 0);

      pushMatrix();
      translate(h*0.9, h*0.5);

      fill(bgcol);
      stroke(r.col);
      rect(0, 2, h * 1.2, h*0.5);
      fill(0);
      text(r.name, 0, 0, h * 1.5, h);
      popMatrix();

      // Score
      translate(h*1.7, 0);

      translate(remaining_width*0.5, h*0.5);
      fill(bgcol);
      noStroke();
      rect(0, 2, remaining_width, h*0.5); // bg
      fill(r.col);
      float full = map(status.life, 0, 120*60, 0, remaining_width);
      rect(-(remaining_width-full)/2, 2, full, h*0.5);
      noFill();
      stroke(120);
      rect(0, 2, remaining_width, h*0.5);
      fill(0);
      text(status.life / 60, 0, 0);


      popMatrix();
      j++;
      if (j == rows) {
        j = 0;
        i++;
      }
    }
    popMatrix();
    popStyle();
  }
}
