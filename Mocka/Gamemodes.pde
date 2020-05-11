import java.util.Collections;
import java.util.Comparator;
import java.util.Arrays;

Gamemode gamemode;

void setGamemode(Gamemode newgamemode) {
  if (DEBUG_GAMEMODE) println("client: setting gamemode to "+newgamemode.getClass().getSimpleName());
  gamemode = newgamemode;
}

interface Gamemode {
  void update();
  void respawn();
  void beginContact(Contact cp);
  void endContact(Contact cp);
  void INTERPRET(ByteBuffer data);
  void hud();
  void decoratePre(Rocket r);
  void decoratePost(Rocket r);
}

class CTF implements Gamemode {
  CTF(ByteBuffer data) {
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
    rect(0, 0, 200, 200);
  }
  void decoratePost(Rocket r) {
  }
}

class Disconnected implements Gamemode {
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
    fill(255, 0, 0);
    textAlign(CENTER);
    translate(WIDTH/2, HEIGHT/2);
    text("Disconnected...\nServer is probably offline!", 0, 0);
    popMatrix();
  }
  void decoratePre(Rocket r) {
  }
  void decoratePost(Rocket r) {
  }
}

class Leaderboard implements Gamemode {
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
}

class Freeplay implements Gamemode {
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
    fill(0);
    textAlign(LEFT, TOP);
    text("Freeplay", 0, 0);
  }
  void decoratePre(Rocket r) {
  }
  void decoratePost(Rocket r) {
  }
}

class Crowning implements Gamemode {
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
    fill(0);
    textAlign(LEFT, TOP);
    //text("Winnnnnn", 0, 0);
  }
  int FRAMES = 0;
  void decoratePre(Rocket r) {
  }
  void decoratePost(Rocket r) {
    //pushMatrix();
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
    //popMatrix();
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

  FloatGame(ByteBuffer data) {
    life_goal = data.getInt();
    startgame_countdown = data.getInt();
    int size = data.getInt();
    scores = new HashMap<Integer, PlayerStatus>();
    PlayerStatus prev = null;
    for (int i = 0; i < size; i++) scores.put(data.getInt(), prev = new PlayerStatus(prev, data));
    if (DEBUG_GAMEMODE) println("client: finished setting up Taggame!");
    NOTIFY_TOUCHING_PLATFORMS(TOUCHING_PLATFORMS);
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
    NOTIFY_TOUCHING_PLATFORMS(TOUCHING_PLATFORMS);
  }

  void beginContact(Contact cp) {
    NOTIFY_TOUCHING_PLATFORMS(TOUCHING_PLATFORMS);
  }
  void endContact(Contact cp) {
    NOTIFY_TOUCHING_PLATFORMS(TOUCHING_PLATFORMS);
  }

  void NOTIFY_TOUCHING_PLATFORMS(int count) {
    client.write(new byte[]{(byte)2, (byte)count});
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
      fill(100);
      text(1+(startgame_countdown/60), WIDTH/2, HEIGHT/2);
    }

    pushMatrix();
    rectMode(CORNER);
    textAlign(LEFT, CENTER);
    textSize(18);

    fill(255, 64);
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
      fill(0);
      text(status.place, 3, textvertcenter);
      text(r.name, 20, textvertcenter);
      //if (status.prev != null) text(status.prev.pos, 220, textvertcenter);

      int gap = 2;
      translate(80, 0);
      noStroke();
      fill(r.col);
      float w = map(status.life, 0, life_goal, 0, 100 - 2*gap); 
      rect(gap, gap, w, 24 - 2*gap);
      fill(0);
      text(status.life/60, 6, textvertcenter);
      popMatrix();
    }
    popMatrix();
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

  void decoratePre(Rocket r) {
  }
  void decoratePost(Rocket r) {
    PlayerStatus status = scores.get(r.UUID);
    if (status == null) return;
    if (r.UUID == UUID_it) {
      strokeWeight(15);
      stroke(255, 0, 0);
      fill(255, 0, 0, 50);
      ellipse(0, 0, 320, 320);
      noStroke();
      fill(255, 0, 0, 20);
      ellipse(0, 0, 520, 520);
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
      fill(100);
      text(1+(startgame_countdown/60), WIDTH/2, HEIGHT/2);
    }

    pushMatrix();
    rectMode(CORNER);
    textAlign(LEFT, CENTER);
    textSize(18);

    fill(255, 64);
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
      fill(0);
      text(status.place, 3, textvertcenter);
      text(r.name, 20, textvertcenter);
      //if (status.prev != null) text(status.prev.pos, 220, textvertcenter);

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
