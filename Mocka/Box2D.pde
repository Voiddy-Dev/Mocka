import shiffman.box2d.*;
import org.jbox2d.collision.shapes.*;
import org.jbox2d.common.*;
import org.jbox2d.dynamics.*;
import org.jbox2d.dynamics.contacts.*;

// A reference to our box2d world
Box2DProcessing box2d;

void setupBox2D() {
  // Initialize box2d physics and create the world
  box2d = new Box2DProcessing(this);
  box2d.createWorld();
  box2d.setGravity(0, -30);
  box2d.listenForCollisions();
}

boolean TOUCHING_SOMETHING = false;

void beginContact(Contact cp) {
  gamemode.beginContact(cp);

  TOUCHING_SOMETHING = true;
}

void endContact(Contact cp) {
  TOUCHING_SOMETHING = false;
}
