using UnityEngine;
using UnityEngine.EventSystems;
using TMPro;
using Newtonsoft.Json;
using UnityEngine.UI;
using Cysharp.Threading.Tasks;

// public class UIAttributeManagerInfo: UIScrollViewInfo{
    
// }

public class UIAttributeManager: UIScrollView{
    // ---------- Config ---------- //
    public new UIScrollViewInfo _info {get => base._info; set => base._info = value; }


    public UIAttributeManager(GameObject parent, UIInfo info): base(parent, info){
    }

    // public override void _init_begin(){
    //     base._init_begin();
    // }

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
