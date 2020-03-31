import processing.net.*;

void setup() {
  size(10, 10); 
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
  println("New client on ip "+myClient.ip());
  Player myPlayer = new Player(myClient);
  players.add(myPlayer);
}
