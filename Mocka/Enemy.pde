HashMap<Integer, EnemyRocket> enemies = new HashMap();

void showEnemies() {
  for (Map.Entry entry : enemies.entrySet()) {
    EnemyRocket enemy = (EnemyRocket)entry.getValue();
    enemy.show();
  }
}

void updateEnemies() {
  for (Map.Entry entry : enemies.entrySet()) {
    EnemyRocket enemy = (EnemyRocket)entry.getValue();
    enemy.updatePosition();

    enemy.interactions();
  }
}

void removeEnemy(int ded_UUID) {
  EnemyRocket ded = enemies.get(ded_UUID);
  if (ded == null) return;
  ded.kill();
  enemies.remove(ded_UUID);
}

byte packet_send_count;
byte[] packet_send_data = new byte[26];
void informEnemies() {
  ByteBuffer buf = ByteBuffer.wrap(packet_send_data);
  buf.put(packet_send_count++);
  Vec2 pos = box2d.getBodyPixelCoord(myRocket.body);
  buf.putFloat(pos.x);
  buf.putFloat(pos.y);
  float angle = myRocket.body.getAngle();
  buf.putFloat(angle);
  Vec2 vel = myRocket.body.getLinearVelocity();
  buf.putFloat(vel.x);
  buf.putFloat(vel.y);
  float angular_velocity = myRocket.body.getAngularVelocity();
  buf.putFloat(angular_velocity);

  if (myRocket.INPUT_up) buf.put((byte)1);
  else buf.put((byte)0);

  for (Map.Entry entry : enemies.entrySet()) {
    EnemyRocket enemy = (EnemyRocket)entry.getValue();
    enemy.notify(packet_send_data);
  }
}

class EnemyRocket extends Rocket {
  DatagramSocket socket;
  SocketListenThread p;

  EnemyRocket(int UUID) {
    super(0, 0);
    this.UUID = UUID;
  }

  void kill() {
    if (socket != null) socket.close();
    if (p != null) p.interrupt();
    killBody();
  }

  void updatePosition() {
    if (latest_packet == null)return;
    ByteBuffer data = ByteBuffer.wrap(latest_packet.getData());
    byte old_time = latest_time;
    latest_time = data.get();
    if (latest_time - old_time < 0) return;

    Vec2 new_pos = box2d.coordPixelsToWorld(new PVector(data.getFloat(), data.getFloat()));
    this.body.setTransform(new_pos, data.getFloat());
    Vec2 new_vel = new Vec2(data.getFloat(), data.getFloat());
    this.body.setLinearVelocity(new_vel);
    this.body.setAngularVelocity(data.getFloat());

    if (data.get() == 1) {
      this.INPUT_up = true;
    } else {
      this.INPUT_up = false;
    }

    latest_packet = null;
  }

  void setSocket(DatagramSocket socket) {
    this.socket = socket;
    println("Client: listening to "+UUID);
    println(socket);
    p = new SocketListenThread();
    p.start();
  }

  void notify(byte[] packet_data) {
    if (socket != null) {
      try {
        DatagramPacket packet = new DatagramPacket(packet_data, packet_data.length);
        socket.send(packet);
      }
      catch(Exception e) {
        println("Could not notify enemy "+this.UUID+" of my position! "+e);
      }
    }
  }

  byte latest_time;
  DatagramPacket latest_packet;

  class SocketListenThread extends Thread {
    long minPrime;
    SocketListenThread() {
    }

    void run() {
      while (!socket.isClosed()) {
        try {
          DatagramPacket receive = new DatagramPacket(new byte[26], 26);
          socket.receive(receive);
          latest_packet = receive;
        }
        catch (Exception e) {
          println(latest_time+" "+e);
          try {
            Thread.sleep(1);
          } 
          catch(Exception e1) {
          }
        }
      }
    }
  }
}
