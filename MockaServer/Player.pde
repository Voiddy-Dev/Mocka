ArrayList<Player> players;
int UUID_available = 0;

void updatePlayers() {
  for (Player p : players) if (!p.client.active()) {
    //po
    players.remove(p);
  }
}

class Player {
  Client client;
  int UUID;

  Player(Client client_) {
    client = client_;
    UUID = UUID_available;
    UUID_available++;
  }

  void update() {
  }
}
