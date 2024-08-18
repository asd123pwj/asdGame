using UnityEngine;
using UnityEngine.UI;
using System.Collections;
using UnityEngine.EventSystems;


public class UIRightMenu: UIBase{
    public UIRightMenu(GameObject parent, UIInfo info = null): base(parent, info){
    }

    public override void _enable(){
        base._enable();
        _UISys._UIMonitor.rightMenu_currentOpen = this;
    }

    public override void _disable(){
        base._disable();
        _UISys._UIMonitor.rightMenu_currentOpen = null;
    }
}
