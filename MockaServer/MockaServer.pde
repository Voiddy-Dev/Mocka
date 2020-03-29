import processing.net.*;

void setup() {
  size(1200, 800); 
  
  myServer = new Server(this, 25567);
  println("Starting server");
  players = new ArrayList<Player>(0);
}

void draw() {
  background(255);
  if (!myServer.active()) {
    println("Trouble! Server is no longer processing-active. Stopping.");
    myServer.stop();
    stop();
  }
  updatePlayers();
}

Server myServer;

void serverEvent(Server serv, Client myClient) {
  Player myPlayer = new Player(myClient);
  players.add(myPlayer);

  println("New Client with IP: " + myClient.ip() + " - UUID: " + myPlayer.UUID);
}

// ClientEvent message is generated when a client disconnects.
void disconnectEvent(Client someClient) {
  for (int i = players.size()-1; i >= 0; i--) {
    Player p = players.get(i);

    if (p.client.equals(someClient)) {
      players.remove(i);
      println("Client with UUID " + p.UUID + " disconnected");
    }
  }
}
