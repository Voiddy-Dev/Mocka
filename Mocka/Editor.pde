enum EditMode {
  move, 
    radius, 
    rectLeft, rectRight, rectTop, rectBottom, rectRotate;
}

class Editor implements Gamemode {
  Platform platform_selected;
  Platform platform_hovered;
  EditMode mode;

  Editor(ByteBuffer data) {
  }
  byte GAME_ID() {
    return 6;
  }

  boolean editing = true; 
  void tab() {
    editing = !editing;
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
    textSize(50);
    textAlign(LEFT, TOP);
    text("Editor", 0, 0);


    if (!editing) return;
    platform_hovered = null;
    if (!mousePressed) for (Platform p : platforms.values()) if (p.isTouching(MOUSEX, MOUSEY)) platform_hovered = p;

    Platform p = (platform_hovered == null) ? platform_selected : platform_hovered;
    if (p == null) return;

    Circle c = null;
    Rectangle r = null;
    if (p instanceof Circle) c = (Circle)p;
    if (p instanceof Rectangle) r = (Rectangle)p;
    // Figure out if we should switch to any EditMode
    if (!mousePressed) {
      if (p.isTouching(MOUSEX, MOUSEY)) {
        if (p instanceof Circle) {
          c = (Circle)p;
          float mdist = dist(MOUSEX, MOUSEY, c.lx, c.ly);
          if (mdist > c.lr - 8) mode = EditMode.radius;
          else mode = EditMode.move;
        } else if (p instanceof Rectangle) {
          r = (Rectangle)p;
          PVector mouse = new PVector(MOUSEX - r.lx, MOUSEY - r.ly).rotate(-r.langle);
          if (mouse.x > r.lw/2 - 8) mode = EditMode.rectRight;
          else if (mouse.x < -r.lw/2 + 8) mode = EditMode.rectLeft;
          else if (mouse.y > r.lh/2 - 8) mode = EditMode.rectBottom;
          else if (mouse.y < -r.lh/2 + 8) mode = EditMode.rectTop;
          else {
            float distToRotate = dist(mouse.x, mouse.y, 0, -r.h/4);
            if (distToRotate < 6) mode = EditMode.rectRotate;
            else mode = EditMode.move;
          }
        } else mode = EditMode.move;
      } else mode = EditMode.move;
    }

    strokeWeight(4);

    pushMatrix();
    switch (mode) {
    case move:
      //noFill();
      //stroke(255, 0, 0);
      fill(255, 0, 0, 120);
      noStroke();
      p.show();
      if (p instanceof Rectangle) {
        translate(r.lx, r.ly);
        rotate(r.langle);
        ellipse(0, -r.lh/4, 12, 12);
      }
      break;

    case radius:
      noFill();
      stroke(255, 0, 0, 240);
      line(c.lx, c.ly, MOUSEX, MOUSEY);
      ellipse(c.lx, c.ly, c.lr*2, c.lr*2);
      break;
    case rectRotate:
      noStroke();
      fill(255, 0, 0, 240);
      translate(r.lx, r.ly);
      rotate(r.langle);
      ellipse(0, -r.lh/4, 12, 12);
      break;

    case rectRight:
      stroke(255, 0, 0, 240);
      translate(r.lx, r.ly);
      rotate(r.langle);
      line(r.lw/2, -r.lh/2, r.lw/2, r.lh/2);
      break;
    case rectLeft:
      stroke(255, 0, 0, 240);
      translate(r.lx, r.ly);
      rotate(r.langle);
      line(-r.lw/2, -r.lh/2, -r.lw/2, r.lh/2);
      break;
    case rectTop:
      stroke(255, 0, 0, 240);
      translate(r.lx, r.ly);
      rotate(r.langle);
      line(-r.lw/2, -r.lh/2, r.lw/2, -r.lh/2);
      break;
    case rectBottom:
      stroke(255, 0, 0, 240);
      translate(r.lx, r.ly);
      rotate(r.langle);
      line(-r.lw/2, r.lh/2, r.lw/2, r.lh/2);
      break;
    }
    popMatrix();
  }
  float PMOUSEX, PMOUSEY;
  void mousePressed() {
    PMOUSEX = MOUSEX;
    PMOUSEY = MOUSEY;
    platform_selected = platform_hovered;
  }
  void mouseDragged() {
    if (platform_selected == null) return;
    switch (mode) {
    case move:
      platform_selected.moveBy(MOUSEX - PMOUSEX, MOUSEY - PMOUSEY);
      if (frameCount % 5 == 0) madeLocalChange(platform_selected);
      break;

    case radius:
      Circle c = (Circle)platform_selected;
      float mdist = 3+dist(MOUSEX, MOUSEY, c.lx, c.ly);
      c.lr = mdist;
      if (frameCount % 5 == 0) madeLocalChange(platform_selected);
      break;

    case rectRotate:
      Rectangle r = (Rectangle)platform_selected;
      r.langle = new PVector(MOUSEX - r.lx, MOUSEY - r.ly).heading()+HALF_PI;
      int deg_inc = 5;
      if (keyPressed) r.langle = radians(deg_inc*round(degrees(r.langle)/deg_inc));
      if (frameCount % 5 == 0) madeLocalChange(platform_selected);
      break;

    case rectRight:
      resizeRect(0, 1);
      break;
    case rectLeft:
      resizeRect(0, -1);
      break;
    case rectBottom:
      resizeRect(HALF_PI, 1);
      break;
    case rectTop:
      resizeRect(HALF_PI, -1);
      break;
    }
    PMOUSEX = MOUSEX;
    PMOUSEY = MOUSEY;
  }
  void resizeRect(float angle, int mult) {
    Rectangle r = (Rectangle)platform_selected;
    PVector delta = new PVector(new PVector(MOUSEX - PMOUSEX, MOUSEY - PMOUSEY).rotate(-r.langle - angle).x, 0).rotate(angle).mult(mult);
    r.lw += delta.x;
    r.lh += delta.y;
    PVector translate = delta.rotate(r.langle).mult(mult);
    r.lx += translate.x/2;
    r.ly += translate.y/2;
    if (frameCount % 5 == 0) madeLocalChange(platform_selected);
  }
  void mouseReleased() {
    if (platform_selected != null) {
      madeLocalChange(platform_selected);
      platform_selected.noteUnchanges();
    }
  }
  void madeLocalChange(Platform p) {
    p.noteChanges();
    int plat_id = -1;
    for (Map.Entry<Integer, Platform> e : platforms.entrySet()) if (e.getValue() == p) {
      plat_id = e.getKey();
      break;
    }
    if (plat_id == -1) return;
    NOTIFY_MAP_CHANGE_REQUEST(plat_id);
  }

  void decoratePre(Rocket r) {
  }
  void decoratePost(Rocket r) {
  }
  void kill() {
  }
}
