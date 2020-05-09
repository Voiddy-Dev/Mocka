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

int TOUCHING_PLATFORMS = 0;

void beginContact(Contact cp) {
  if (contactIsWithPlatform(cp)) TOUCHING_PLATFORMS++;
  gamemode.beginContact(cp);
}

void endContact(Contact cp) {
  if (contactIsWithPlatform(cp)) TOUCHING_PLATFORMS = max(0, TOUCHING_PLATFORMS-1);
  gamemode.endContact(cp);
}

boolean contactIsWithPlatform(Contact cp) {
  Object o1 = cp.getFixtureA().getBody().getUserData();
  Object o2 = cp.getFixtureB().getBody().getUserData();
  if (o1 != myRocket && o2 != myRocket) return false; // does not concern us (ie our player-local simulation)
  return o1 instanceof Platform || o2 instanceof Platform;
}
