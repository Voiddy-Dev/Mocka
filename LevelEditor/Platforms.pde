import java.nio.ByteBuffer;

abstract class Platform {
  boolean hovered = false;
  float x, y;

  abstract void show();
  abstract void putData(ByteBuffer data);
  abstract int size();
  abstract boolean onTop(float x, float y);
}

class Circle extends Platform {
  float x, y, r;

  // constructor and initialize the platform
  Circle(ByteBuffer data) {
    this(data.getFloat(), data.getFloat(), data.getFloat());
  }
  Circle(float x, float y, float r) {
    this.x = x;
    this.y = y;
    this.r = r;
  }

  void putData(ByteBuffer data) {
    data.put((byte)1);
    data.putFloat(x);
    data.putFloat(y);
    data.putFloat(r);
  }

  int size() {
    return 13;
  }
  // display the platform
  public void show() {
    fill(0);
    noStroke();
    if (this.hovered) {
      fill(0, 128);
      strokeWeight(5);
      stroke(255, 0, 0);
    }
    ellipse(x, y, 2*r, 2*r);
  }

  boolean onTop(float x, float y) {
    return dist(x, y, this.x, this.y) <= this.r;
  }
}


class Rectangle extends Platform {
  float x, y, w, h, angle;

  // constructor and initialize the platform
  Rectangle(ByteBuffer data) {
    this(data.getFloat(), data.getFloat(), data.getFloat(), data.getFloat(), data.getFloat());
  }
  Rectangle(float x, float y, float w, float h) {
    this(x, y, w, h, 0);
  }
  Rectangle(float x, float y, float w, float h, float angle) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.angle = angle;
  }

  void putData(ByteBuffer data) {
    data.put((byte)0);
    data.putFloat(x);
    data.putFloat(y);
    data.putFloat(w);
    data.putFloat(h);
    data.putFloat(angle);
  }
  int size() {
    return 21;
  }

  boolean onTop(float mousX, float mousY) {
    return (mousX >= this.x - this.w/2) && (mousX <= this.x + this.w/2) && (mousY >= this.y - this.h/2) && (mousY <= this.y + this.h/2);
  }

  // display the platform
  public void show() {
    pushMatrix();
    translate(x, y);
    rotate(angle);

    fill(0);
    noStroke();

    if (this.hovered) {
      fill(0, 128);
      strokeWeight(5);
      stroke(255, 0, 0);
    }
    rect(0, 0, w, h);
    popMatrix();
  }
}
