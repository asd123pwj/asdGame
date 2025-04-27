using System.Collections.Generic;
using Cysharp.Threading.Tasks;
using UnityEngine;

public class ObjectCommandHandler: CommandHandlerBase{
    public override void register(){
        CommandSystem._add(spawn);
        CommandSystem._add(move);
        CommandSystem._add(rush);
    }

    async UniTask spawn(Dictionary<string, object> args){
        /* spawn
         * --type (string)          the type of object
         * --[useMousePos] (flag)   use the mouse position 
         * --[x] (float)            
         * --[y] (float)            
         * 
         * spawn --x 9.9 --y 9 -type asd
         * spawn --useMousePos -type asd
         */
        Vector2 spawn_pos;
        if (args.ContainsKey("useMousePos")){
            spawn_pos = InputSystem._keyPos.mouse_pos_world;
        }
        else{
            float x = argType.toFloat(args["x"]);
            float y = argType.toFloat(args["y"]);
            spawn_pos = new(x, y);
        }
        _ObjSys._object_spawn._instantiate((string)args["type"], spawn_pos);
    }

    async UniTask move(Dictionary<string, object> args){
        /* move
         */
        KeyPos key_pos = InputSystem._keyPos;
        if (args.ContainsKey("right")) key_pos.x = 1;
        else if (args.ContainsKey("left")) key_pos.x = -1;
        else key_pos.x = 0;
        if (args.ContainsKey("up")) key_pos.y = 1;
        else if (args.ContainsKey("down")) key_pos.y = -1;
        else key_pos.y = 0;
        _CtrlSys._player._Move._walk(key_pos);
    }
    
    async UniTask rush(Dictionary<string, object> args){
        /* move
         */
        KeyPos key_pos = InputSystem._keyPos;
        if (args.ContainsKey("right")) key_pos.x = 1;
        else if (args.ContainsKey("left")) key_pos.x = -1;
        else key_pos.x = 0;
        if (args.ContainsKey("up")) key_pos.y = 1;
        else if (args.ContainsKey("down")) key_pos.y = -1;
        else key_pos.y = 0;
        _CtrlSys._player._Move._rush(key_pos);
    }
}