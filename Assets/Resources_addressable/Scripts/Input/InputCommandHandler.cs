using System.Collections.Generic;


public class InputCommandHandler: BaseClass{
    public void register(){
        CommandSystem._add("FROM_INPUT", FROM_INPUT);
    }

    void FROM_INPUT(Dictionary<string, object> args){
        /* FROM_INPUT               Use command from INPUT system
         * --key (string)           the key name of the command
         * --[write] (string)       new command, replace the command use its value
         * --[read] (string)        messageID, send the command to its value
         * 
         * Example:
         *   FROM_INPUT --key z     
         *     run command of key z
         *   FROM_INPUT --key z --write "toggleUI --type UIBackpack"  
         *     replace command of key z to "toggleUI --type UIBackpack"
         *   FROM_INPUT --key z --read OWNER_25365_COMMAND 
         *     send command of key z to messageID "OWNER_25365_COMMAND"
         */
        string key = (string)args["key"];
        if (args.ContainsKey("write")){
            InputCommandRegister.keyName2Command[key] = (string)args["write"];
        }
        else if (args.ContainsKey("read")){
            _Msg._send((string)args["read"], InputCommandRegister.keyName2Command[key]);
        }
        else {
            _Msg._send(GameConfigs._sysCfg.Msg_command, InputCommandRegister.keyName2Command[key]);
        }
    }
}