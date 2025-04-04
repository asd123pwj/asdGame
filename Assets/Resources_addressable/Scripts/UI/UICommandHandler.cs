using System.Collections.Generic;
using UnityEngine;

public class UICommandHandler: BaseClass{
    public void register(){
        CommandSystem._add("toggleUI", toggleUI);
    }

    void toggleUI(Dictionary<string, object> args){
        /* toggleUI                 open a closed UI or close an opened UI
         * --type (string)          the UIClass.type of UI
         * --[useMousePos] (flag)   use the mouse position as the UI position
         * --[x] (float)            the x position of the UI, world space
         * --[y] (float)            the y position of the UI, world space
         * --[name] (string)        the name of the UI
         * --[asItsChild] (int)     the UI runtimeID of the parent UI, UIBase._runtimeID
         * 
         * Example:
         *   toggleUI --x 99.9 --y 99 --type UIKeyboardShortcut --name CustomName
         *   toggleUI --type UIKeyboardShortcut
         *   toggleUI --useMousePos --type UIKeyboardShortcut
         *   toggleUI --useMousePos --x 99.9 --type UIKeyboardShortcut
         *
         *   toggleUI --useMousePos --type UIBackpack --asItsChild xxxNoUseInManualxxx
         */
        string type = (string)args["type"];
        Vector2 spawn_pos = (bool)args["useMousePos"] ? _InputSys._keyPos.mouse_pos_world : Vector2.zero;
        spawn_pos.x = args.ContainsKey("x") ? argType.toFloat(args["x"]) : spawn_pos.x;
        spawn_pos.y = args.ContainsKey("y") ? argType.toFloat(args["y"]) : spawn_pos.y;
        string name = args.ContainsKey("name") ? (string)args["name"] : "";
        UIBase ui = _UISys._UIMonitor._get_UI((int)args["asItsChild"]);
        _UISys._UIDraw._toggle(type, name, spawn_pos, ui);
    }
}