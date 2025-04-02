using System.Collections.Generic;
using UnityEngine;

public class UICommandHandler: BaseClass{
    public void register(){
        CommandSystem._add("toggleUI", toggleUI);
    }

    void toggleUI(Dictionary<string, object> args){
        /*
         * toggleUI -x 99.9 -y 99 -type UIKeyboardShortcut -name CustomName
         * toggleUI -type UIKeyboardShortcut
         * toggleUI -auto mouse -type UIKeyboardShortcut
         * toggleUI -auto mouse -x 99.9 -type UIKeyboardShortcut
         
         * toggleUI -auto mouse -type UIBackpack
         */
        Vector2 spawn_pos = Vector2.zero;
        if (args.ContainsKey("auto")){
            spawn_pos = _InputSys._keyPos.mouse_pos_world;
        }
        if (args.ContainsKey("x")){
            spawn_pos.x = argType.toFloat(args["x"]);
        }
        if (args.ContainsKey("y")){
            spawn_pos.y = argType.toFloat(args["y"]);
        }
        string type = (string)args["type"];
        string name = "";
        if (args.ContainsKey("name")){
            name = (string)args["name"];
        }
        _UISys._UIDraw._toggle(type, name, spawn_pos);
    }
}