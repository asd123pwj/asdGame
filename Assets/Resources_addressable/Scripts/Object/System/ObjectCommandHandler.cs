using System.Collections.Generic;
using UnityEngine;

public class ObjectCommandHandler: BaseClass{
    public void register(){
        CommandSystem._add("spawn", spawn);
    }

    void spawn(Dictionary<string, object> args){
        /*
         * spawn -x 9.9 -y 9 -name asd
         * spawn -auto mouse -name asd
         */
        Vector2 spawn_pos;
        if (args.ContainsKey("auto")){
            spawn_pos = _InputSys._keyPos.mouse_pos_world;
        }
        else{
            float x = argType.toFloat(args["x"]);
            float y = argType.toFloat(args["y"]);
            spawn_pos = new(x, y);
        }
        _ObjSys._object_spawn._instantiate((string)args["name"], spawn_pos);
    }
}