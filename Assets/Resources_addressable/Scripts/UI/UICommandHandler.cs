using System.Collections.Generic;
using UnityEngine;

public class UICommandHandler: BaseClass{
    public void register(){
        CommandSystem._add("UIToggle", UIToggle);
        CommandSystem._add("saveUI", saveUI);
        CommandSystem._add("loadUI", loadUI);
    }

    void UIToggle(Dictionary<string, object> args){
        /* UIToggle                 open a closed UI or close an opened UI
         * --type (string)          the UIClass.type of UI
         * --[useMousePos] (flag)   use the mouse position as the UI position
         * --[x] (float)            the x position of the UI, world space
         * --[y] (float)            the y position of the UI, world space
         * --[name] (string)        the name of the UI
         * --[asItsChild] (int)     the UI runtimeID of the parent UI, UIBase._runtimeID
         * 
         * Example:
         *   UIToggle --x 99.9 --y 99 --type UIKeyboardShortcut --name CustomName --asItsChild xxxNoUseInManualxxx
         *   UIToggle --type UIKeyboardShortcut
         *   UIToggle --useMousePos --type UIKeyboardShortcut
         *   UIToggle --useMousePos --x 99.9 --type UIKeyboardShortcut
         *
         *   UIToggle --useMousePos --type UIAttributeManager
         */
        string type = (string)args["type"];
        string name = args.ContainsKey("name") ? (string)args["name"] : "";
        UIBase ui = args.ContainsKey("asItsChild") ? _UISys._UIMonitor._get_UI((int)args["asItsChild"]) : null;
        if (args.ContainsKey("useMousePos") || args.ContainsKey("x") || args.ContainsKey("y")){
            Vector2 spawn_pos = args.ContainsKey("useMousePos") ? _InputSys._keyPos.mouse_pos_world : Camera.main.ScreenToWorldPoint(Vector2.zero);
            spawn_pos.x = args.ContainsKey("x") ? argType.toFloat(args["x"]) : spawn_pos.x;
            spawn_pos.y = args.ContainsKey("y") ? argType.toFloat(args["y"]) : spawn_pos.y;
            _UISys._UIDraw._toggle(type, name, spawn_pos, ui);
        }
        else{
            _UISys._UIDraw._toggle(type, name, parent:ui);
        }
    }

    void saveUI(Dictionary<string, object> args){
        _UISys._UISL._save_UI();
    }

    void loadUI(Dictionary<string, object> args){
        _UISys._UISL._load_UIs();
    }

    
}