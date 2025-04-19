using UnityEngine;


public class UIScrollTextCommand: UIScrollText{
    public UIScrollTextCommand(GameObject parent, UIInfo info): base(parent, info){
    }

    public override void get_text(){
        if (owner._info.attributes[_info.source].get<string>().StartsWith("FROM_INPUT")){
            _Msg._send2COMMAND(
                owner._info.attributes[_info.source].get<string>() + " --read " + _info.messageID
            );
        }
        else{
            base.get_text();
        }
    }

    public override void sync_with_source(DynamicValue value){
        if (_info.source == "") return;
        if (owner._info.attributes[_info.source].get<string>().StartsWith("FROM_INPUT")){
            _Msg._send2COMMAND(
                owner._info.attributes[_info.source].get<string>() + " --write \"" + value.get<string>() + "\""
            );
        }
    }
}
