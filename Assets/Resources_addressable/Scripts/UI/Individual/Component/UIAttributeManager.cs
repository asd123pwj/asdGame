using UnityEngine;
using UnityEngine.EventSystems;
using TMPro;
using Newtonsoft.Json;
using UnityEngine.UI;
using Cysharp.Threading.Tasks;
using System.Collections.Generic;

// public class UIAttributeManagerInfo: UIScrollViewInfo{

// }

public class UIAttributeManager: UIScrollView{
    // ---------- Config ---------- //
    public new UIScrollViewInfo _info {get => base._info; set => base._info = value; }


    public UIAttributeManager(GameObject parent, UIInfo info): base(parent, info){
    }

    public override void _init_done(){
        base._init_done();
        get_editor_info();
    }

    List<UIInfo> get_editor_info(){
        UIBase owner = _UISys._UIMonitor._get_UI(_info.attributes["RIGHT_MENU_OWNER"].get<int>());
        Debug.Log(owner._info.name);
        return null;
    }

    public override void _update_UIMonitor(GameObject parent){
        remove_old_attributeManager();
        base._update_UIMonitor(parent);
    }

    void remove_old_attributeManager(){
        UIBase ui = _UISys._UIMonitor._get_UI_fg(_info.name);
        if (ui == null) return;
        ui._destroy();
    }

}
