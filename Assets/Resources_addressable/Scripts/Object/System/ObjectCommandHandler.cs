using System;
using System.Collections.Generic;
using System.Threading;
using Cysharp.Threading.Tasks;
using Unity.VisualScripting;
using UnityEngine;

public class ObjectCommandHandler: CommandHandlerBase{
    public override void register(){
        CommandSystem._add(spawn);
        CommandSystem._add(move);
        CommandSystem._add(rush);
        CommandSystem._add(ObjTeleport);
        CommandSystem._add(ObjMove);
    }

    async UniTask spawn(Dictionary<string, object> args, CancellationToken? ct){
        await Placeholder.noAsyncWarning();
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

    async UniTask move(Dictionary<string, object> args, CancellationToken? ct){
        await Placeholder.noAsyncWarning();
        /* move
         */
        KeyPos key_pos = InputSystem._keyPos;
        if (args.ContainsKey("right")) key_pos.x = 1;
        else if (args.ContainsKey("left")) key_pos.x = -1;
        else key_pos.x = 0;
        if (args.ContainsKey("up")) key_pos.y = 1;
        else if (args.ContainsKey("down")) key_pos.y = -1;
        else key_pos.y = 0;
        // _CtrlSys._player._Move._walk(key_pos);
        _ObjSys._mon._player._Move._walk(key_pos);
    }
    
    async UniTask rush(Dictionary<string, object> args, CancellationToken? ct){
        await Placeholder.noAsyncWarning();
        /* move
         */
        KeyPos key_pos = InputSystem._keyPos;
        if (args.ContainsKey("right")) key_pos.x = 1;
        else if (args.ContainsKey("left")) key_pos.x = -1;
        else key_pos.x = 0;
        if (args.ContainsKey("up")) key_pos.y = 1;
        else if (args.ContainsKey("down")) key_pos.y = -1;
        else key_pos.y = 0;
        // _CtrlSys._player._Move._rush(key_pos);
        _ObjSys._mon._player._Move._rush(key_pos);
    }

    async UniTask ObjTeleport(Dictionary<string, object> args, CancellationToken? ct){
        await Placeholder.noAsyncWarning();
        /* ObjTeleport
         *  Abandon --[ID] (string)            the runtimeID of object, if not specified, use the player
         * --[useMousePos] (flag)   use the mouse position 
         * --[x] (float)            
         * --[y] (float)            
         * 
         * spawn --x 9.9 --y 9 -type asd
         * spawn --useMousePos -type asd
         */
        Vector2 dest_pos;
        if (args.ContainsKey("useMousePos")){
            dest_pos = InputSystem._keyPos.mouse_pos_world;
        }
        else{
            float x = argType.toFloat(args["x"]);
            float y = argType.toFloat(args["y"]);
            dest_pos = new(x, y);
        }

        KeyPos key_pos = InputSystem._keyPos.Copy();
        key_pos.mouse_pos_world = dest_pos;
        // if (!args.TryGetValue("ID", out object runtimeID)){
        //     runtimeID = _ObjSys._mon._player._runtimeID;
        // }
        // ObjectConfig obj = ObjectConfig._our[(int)runtimeID];
        // obj._self.transform.position = dest_pos;
        _ObjSys._mon._player._Move._teleport(key_pos);
    }
    
    async UniTask ObjMove(Dictionary<string, object> args, CancellationToken? ct){
        await Placeholder.noAsyncWarning();
        /* ObjPull
         * --[ID] (string)            the runtimeID of object, if not specified, use the player          
         * 
         * Example
         *   ObjMove 
         *   - Move the player
         *   ObjMove -ID 10636
         *   - Move the object with runtimeID 10636
         */
        int runtimeID = _ObjSys._mon._player._runtimeID;
        if (args.TryGetValue("ID", out object runtimeID_)){
            runtimeID = (int)runtimeID_;
        }
        _ObjSys._runtimeID2base[runtimeID]._Movement._prepare_to_move(InputSystem._keyPos);
    }
}