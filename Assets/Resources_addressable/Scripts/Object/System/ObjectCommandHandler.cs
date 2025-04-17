using System.Collections.Generic;
using UnityEngine;

public class ObjectCommandHandler: BaseClass{
    public void register(){
        CommandSystem._add("spawn", spawn);
    }

    void spawn(Dictionary<string, object> args){
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
}