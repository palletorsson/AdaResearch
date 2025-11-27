import socket
import threading
import json
import time
from queue import Queue

# Configuration
HOST = '127.0.0.1'  # Localhost
PORT = 65432        # Arbitrary non-privileged port

class AIBridgeServer:
    def __init__(self):
        self.clients = {}  # {addr: socket}
        self.message_queue = Queue()
        self.running = True
        
        # Shared State (The "Game World")
        self.world_state = {
            "current_sequence": "None",
            "active_agents": [],
            "artifacts_found": [],
            "notes": []
        }

    def start(self):
        print(f"[*] Starting AI Bridge Server on {HOST}:{PORT}...")
        self.server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.server_socket.bind((HOST, PORT))
        self.server_socket.listen()

        # Start broadcast thread
        threading.Thread(target=self.broadcast_loop, daemon=True).start()

        try:
            while self.running:
                client_sock, addr = self.server_socket.accept()
                print(f"[+] New connection from {addr}")
                self.clients[addr] = client_sock
                
                # Send current state immediately
                self.send_to(client_sock, {
                    "type": "STATE_UPDATE",
                    "data": self.world_state
                })

                threading.Thread(target=self.handle_client, args=(client_sock, addr), daemon=True).start()
        except KeyboardInterrupt:
            print("[*] Shutting down server...")
        finally:
            self.server_socket.close()

    def handle_client(self, client_sock, addr):
        while self.running:
            try:
                data = client_sock.recv(4096)
                if not data:
                    break
                
                # Parse Message
                try:
                    message = json.loads(data.decode('utf-8'))
                    print(f"[{addr}] Received: {message}")
                    self.process_message(message, addr)
                except json.JSONDecodeError:
                    print(f"[!] Invalid JSON from {addr}")

            except ConnectionResetError:
                break
        
        print(f"[-] Connection closed {addr}")
        del self.clients[addr]
        client_sock.close()

    def process_message(self, message, sender_addr):
        msg_type = message.get("type")
        
        if msg_type == "CHAT":
            # Relay chat to all
            self.message_queue.put({
                "type": "CHAT",
                "sender": str(sender_addr),
                "content": message.get("content")
            })
            
        elif msg_type == "UPDATE_STATE":
            # Update shared world state
            updates = message.get("data", {})
            self.world_state.update(updates)
            # Broadcast new state
            self.message_queue.put({
                "type": "STATE_UPDATE",
                "data": self.world_state
            })
            
        elif msg_type == "AGENT_HELLO":
            agent_name = message.get("name", "Unknown")
            if agent_name not in self.world_state["active_agents"]:
                self.world_state["active_agents"].append(agent_name)
            self.message_queue.put({
                "type": "SYSTEM",
                "content": f"Agent {agent_name} has joined the session."
            })

    def broadcast_loop(self):
        while self.running:
            if not self.message_queue.empty():
                msg = self.message_queue.get()
                data = json.dumps(msg).encode('utf-8')
                
                # Send to all connected clients
                for addr, sock in list(self.clients.items()):
                    try:
                        sock.sendall(data)
                    except:
                        pass
            time.sleep(0.01)

    def send_to(self, sock, msg):
        try:
            sock.sendall(json.dumps(msg).encode('utf-8'))
        except:
            pass

if __name__ == "__main__":
    server = AIBridgeServer()
    server.start()

