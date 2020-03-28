Client client;

// ClientEvent message is generated when the server 
// sends data to an existing client.
void clientEvent(Client someClient) {
  print("Server Says:  ");

  println(client.readString());
}
