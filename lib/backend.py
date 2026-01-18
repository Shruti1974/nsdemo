import socket
import sqlite3
import json

def init_db():
    conn = sqlite3.connect('staff.db')
    # This line ensures the table exists but does NOT delete old data
    conn.execute("CREATE TABLE IF NOT EXISTS staff (fname TEXT, lname TEXT, phone TEXT, email TEXT)")
    conn.commit()
    conn.close()

def start_server():
    init_db()
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    # Allows the socket to be reused immediately if you restart the server
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(('0.0.0.0', 5555)) 
    server.listen(1)
    print("PYTHON SERVER IS ON. Waiting for phone...")

    while True:
        client, addr = server.accept()
        data = client.recv(1024).decode('utf-8')
        if data:
            try:
                staff = json.loads(data)
                conn = sqlite3.connect('staff.db')
                conn.execute("INSERT INTO staff VALUES (?,?,?,?)", 
                             (staff['fname'], staff['lname'], staff['phone'], staff['email']))
                conn.commit()
                conn.close()
                print(f"Saved to DB: {staff['fname']}")
                client.send("Success: Saved to Laptop Database!".encode('utf-8'))
            except Exception as e:
                print(f"Error processing data: {e}")
        client.close()

if __name__ == "__main__":
    start_server()