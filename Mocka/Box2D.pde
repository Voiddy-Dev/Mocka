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

void beginContact(Contact cp) {
  //if (cp.getFixtureA().getBody().getUserData() == null || cp.getFixtureB().getBody().getUserData() == null) return;
  if (myRocket.contactIsWithPlatform(cp)) myRocket.TOUCHING_PLATFORMS++;
  gamemode.beginContact(cp);
}

void endContact(Contact cp) {
  if (myRocket.contactIsWithPlatform(cp)) myRocket.TOUCHING_PLATFORMS = max(0, myRocket.TOUCHING_PLATFORMS-1);
  gamemode.endContact(cp);
}
