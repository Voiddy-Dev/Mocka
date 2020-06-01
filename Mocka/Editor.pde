enum EditMode {
  move, radius;
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
    if (!mousePressed) for (Platform p : platforms) if (p.isTouching(MOUSEX, MOUSEY)) platform_hovered = p;

    Platform p = (platform_hovered == null) ? platform_selected : platform_hovered;
    if (p == null) return;

    // Figure out if we should switch to any EditMode
    if (!mousePressed) {
      if (p.isTouching(MOUSEX, MOUSEY)) {
        if (p instanceof Circle) {
          Circle c = (Circle)p;
          float mdist = dist(MOUSEX, MOUSEY, c.lx, c.ly);
          if (mdist > c.lr - 8) mode = EditMode.radius;
          else mode = EditMode.move;
        } else mode = EditMode.move;
      } else mode = EditMode.move;
    }

    strokeWeight(4);

    switch (mode) {
    case move:
      noFill();
      stroke(255, 0, 0);
      p.show();
      break;

    case radius:
      Circle c = (Circle)p;
      stroke(255, 0, 0);
      line(c.lx, c.ly, MOUSEX, MOUSEY);
    }
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
    }
    PMOUSEX = MOUSEX;
    PMOUSEY = MOUSEY;
  }
  void mouseReleased() {
    if (platform_selected != null) {
      madeLocalChange(platform_selected);
      platform_selected.noteUnchanges();
    }
  }
  void madeLocalChange(Platform p) {
    p.noteChanges();
    int plat_id = 0;
    for (; plat_id < platforms.length; plat_id++) if (platforms[plat_id] == p) break;
    if (plat_id == platforms.length) return;
    NOTIFY_MAP_CHANGE_REQUEST(plat_id);
  }

  void decoratePre(Rocket r) {
  }
  void decoratePost(Rocket r) {
  }
  void kill() {
  }
}
