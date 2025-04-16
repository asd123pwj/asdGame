using System.Collections.Generic;
using UnityEngine;

public class InputCommandRegister : BaseClass{
    public static Dictionary<string, string> keyName2Command = new();

    public override bool _check_allow_init(){
        return _GCfg._InputSys != null;
    }

    public override void _init(){
        init_key2Command();
        init_keyAction();
    }

    void init_key2Command(){
        keyName2Command.Add("o", "toggleUI --type UIKeyboardShortcut");
        keyName2Command.Add("x", "toggleUI --type UIKeyboardShortcut");
    }
    void init_keyAction(){
        _GCfg._InputSys._register_action("o", _open_o, "isFirstDown");
        _GCfg._InputSys._register_action("x", _open_x, "isFirstDown");
    }

    public bool _open_o(KeyPos keyPos, Dictionary<string, KeyInfo> keyStatus){
        _Msg._send(GameConfigs._sysCfg.Msg_command, keyName2Command["o"]);
        return true;
    }
    public bool _open_x(KeyPos keyPos, Dictionary<string, KeyInfo> keyStatus){
        _Msg._send(GameConfigs._sysCfg.Msg_command, keyName2Command["x"]);
        return true;
    }

}
