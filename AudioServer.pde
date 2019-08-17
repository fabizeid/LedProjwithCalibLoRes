import java.net.*;

public class AudioServer implements Runnable
{
    Thread thread;
    DatagramSocket socket;
    int port;
    byte[] buf;
    DatagramPacket packet;
    boolean listen;
    AudioServer(int port){
        this.port = port;
        this.socket = null;
        this.buf = new byte[1];
        listen = true;
        // receive request
        try{
            this.socket = new DatagramSocket(port);
        } catch (SocketException e) {
            println("Socket Error");
            return;
        }
        this.packet = new DatagramPacket(buf, buf.length);
        thread = new Thread(this);
        thread.start();
    }
    void dispose()
    {
        println("disposed socket");
        socket = null;
    }
    public int get(){
        return (int)buf[0] & 0xFF;
    }
    public void stopThread(){
        listen = false;
        socket.close();
    }
    public void run() {
        while(listen){
            try {
                socket.receive(packet);
                //println(buf);
            }  catch (IOException e) {
                dispose();
            }
        }
        if(socket != null)
            socket.close();
    }
}

    
