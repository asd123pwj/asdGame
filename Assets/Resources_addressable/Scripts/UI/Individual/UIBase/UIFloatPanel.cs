using UnityEngine;
using UnityEngine.UI;
using System.Collections;
using UnityEngine.EventSystems;


public class UIFloatPanel: UIScrollView{
    public UIFloatPanel(GameObject parent, UIInfo info = null): base(parent, info){
    }

    public override void _enable(){
        base._enable();
        if (_UISys._UIMonitor.ui_currentPointerEnter != null){
            Debug.Log(_UISys._UIMonitor.ui_currentPointerEnter._info.name);
        }
        else{
            Debug.Log("null");
        }
    }

    public override void _disable(){
        base._disable();
    }
}
