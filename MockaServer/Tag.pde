void newGame() {
  Player best = null;
  for (Map.Entry entry : players.entrySet()) {
    Player p = (Player)entry.getValue();
    if (best == null || best.life_counter < p.life_counter) best = p;
  }
  for (Map.Entry entry : players.entrySet()) {
    Player p = (Player)entry.getValue();
    p.state = (p == best) ? State.it : State.normal;
    p.life_counter = 120*60;
    TCP_SEND_ALL_CLIENTS(NOTIFY_PLAYER_STATE(p));
  }
}
