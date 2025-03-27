using System.Collections.Generic;

public delegate void MessageReceiver(string message);


public class MessageNode{
    public string ID;
    public List<MessageReceiver> receivers;
    public string message;
}

public class MessageBus: BaseClass{
    static Dictionary<string, MessageNode> message_nodes = new();

    public static void _init_message_node(string ID){
        if (message_nodes.ContainsKey(ID)) return;
        message_nodes.Add(ID, new(){
            ID = ID,
            receivers = new(),
        });
    }

    public static void _add_receiver(string ID, MessageReceiver receiver){
        if (!message_nodes.ContainsKey(ID)) return;
        message_nodes[ID].receivers.Add(receiver);
    }

    public static void _send(string ID, string message){
        if (!message_nodes.ContainsKey(ID)) return;
        message_nodes[ID].message = message;
        foreach (var receiver in message_nodes[ID].receivers){
            receiver(message_nodes[ID].message);
        }
    }
}
