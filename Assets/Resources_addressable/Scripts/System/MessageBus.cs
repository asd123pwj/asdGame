using System.Collections.Generic;
using Cysharp.Threading.Tasks;

public delegate UniTask MessageReceiver(DynamicValue message);


public class MessageNode{
    public string ID;
    public List<MessageReceiver> receivers;
    public DynamicValue message;
}

public class MessageBus: BaseClass{
    Dictionary<string, MessageNode> message_nodes = new();

    public void _init_message_node(string ID){
        // if (message_nodes.ContainsKey(ID)) return;
        message_nodes.Add(ID, new(){
            ID = ID,
            receivers = new(),
        });
    }

    public void _add_receiver(string ID, MessageReceiver receiver){
        if (!message_nodes.ContainsKey(ID)) _init_message_node(ID);
        message_nodes[ID].receivers.Add(receiver);
    }

    public async UniTask _send(string ID, DynamicValue message){
    // public void _send(string ID, DynamicValue message){
        if (!message_nodes.ContainsKey(ID)) _init_message_node(ID);
        message_nodes[ID].message = message;
        foreach (var receiver in message_nodes[ID].receivers){
            await receiver(message_nodes[ID].message);
        }
    }

    public async UniTask _send2COMMAND(DynamicValue message){
        await _send(GameConfigs._sysCfg.Msg_command, message);
    }

    public DynamicValue _get_message(string ID){
        if (!message_nodes.ContainsKey(ID)) return "";
        return message_nodes[ID].message;
    }
}
