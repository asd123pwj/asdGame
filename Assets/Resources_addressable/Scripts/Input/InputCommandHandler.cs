using System.Collections.Generic;
using System.Threading;
using Cysharp.Threading.Tasks;
using UnityEngine;


public class InputCommandHandler: CommandHandlerBase{
    public override void register(){
        CommandSystem._add(FROM_INPUT);
        CommandSystem._add(print_mouse_hover_time);
    }

    async UniTask FROM_INPUT(Dictionary<string, object> args, CancellationToken? ct){
        /* FROM_INPUT               Use command from INPUT system
         * --key (string)           the key name of the command
         * --[write] (string)       new command, replace the command use its value
         * --[read] (string)        messageID, send the command to its value
         * --[trigger] (string)     isDown, isUp, isFirstDown, isFirstUp
         * 
         * Example:
         *   FROM_INPUT --key z     
         *   - run command of key z
         *   FROM_INPUT --key z --write "UIToggle --type UIBackpack"  
         *   - replace command of key z to "UIToggle --type UIBackpack"
         *   FROM_INPUT --key z --read OWNER_25365_COMMAND 
         *   - send command of key z to messageID "OWNER_25365_COMMAND"
         *   FROM_INPUT --key z --trigger isDown
         *   - modify key z to trigger isDown
         */
        string key = (string)args["key"];
        if (args.ContainsKey("write")){
            InputCommandRegister.keyName2Command[key] = (string)args["write"];
        }
        else if (args.ContainsKey("read")){
            await _Msg._send((string)args["read"], InputCommandRegister.keyName2Command[key], ct);
        }
        else if (args.ContainsKey("trigger")){
            _InputSys._register_action(key, null, (string)args["trigger"], true);
        }
        else {
            await _Msg._send2COMMAND(InputCommandRegister.keyName2Command[key], ct);
        }
    }
    
    async UniTask print_mouse_hover_time(Dictionary<string, object> args, CancellationToken? ct){
        await Placeholder.noAsyncWarning();
        /* FROM_INPUT               Use command from INPUT system
         */
        Debug.Log(InputSystem._keyPos.mouse_hover_deltaTime);
    }
    
}