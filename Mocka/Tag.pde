void showTag() {
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
  textSize(20);
  strokeWeight(5);
  translate(0, height-100);
  while (it.hasNext()) {
    Rocket r = it.next();
    color bgcol = r.state == STATE_IS_IT ? color(255, 222, 222) : color(255);
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
    float full = map(r.life_counter, 0, 120*60, 0, remaining_width);
    rect(-(remaining_width-full)/2, 2, full, h*0.5);
    noFill();
    stroke(120);
    rect(0, 2, remaining_width, h*0.5);
    fill(0);
    text(r.life_counter / 60, 0, 0);


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
