using System;
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
        keyName2Command.Add("f5", "UISave");
        keyName2Command.Add("f9", "UILoad");
    }
    void init_keyAction(){
        _GCfg._InputSys._register_action("o", create_delegate("o"), "isFirstDown");
        _GCfg._InputSys._register_action("x", create_delegate("x"), "isFirstDown");
        _GCfg._InputSys._register_action("f5", create_delegate("f5"), "isFirstDown");
        _GCfg._InputSys._register_action("f9", create_delegate("f9"), "isFirstDown");
    }

    public _input_action create_delegate(string key){
        return new _input_action((keyPos, keyStatus) => {
            _Msg._send(GameConfigs._sysCfg.Msg_command, keyName2Command[key]);
            return true;
        });
    }
}
