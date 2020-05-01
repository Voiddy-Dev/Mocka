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
  if (myRocket.state != STATE_IS_IT) return;
  // Get both fixtures
  Fixture f1 = cp.getFixtureA();
  Fixture f2 = cp.getFixtureB();
  // Get both bodies
  Body b1 = f1.getBody();
  Body b2 = f2.getBody();

  // Get our objects that reference these bodies
  Object o1 = b1.getUserData();
  Object o2 = b2.getUserData();
  if (o1 instanceof Rocket && o2 instanceof Rocket) {
    Rocket r1 = (Rocket) o1;
    Rocket r2 = (Rocket) o2;
    Rocket other = (r1 == myRocket) ? r2 : r1;
    println("touched : "+other.UUID);
    NOTIFY_TAGGED_OTHER(other.UUID);
  }
}
