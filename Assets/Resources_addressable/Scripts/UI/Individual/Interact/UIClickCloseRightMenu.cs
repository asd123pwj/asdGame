using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;
using System.Threading.Tasks;
using UnityEngine.EventSystems;
using Cysharp.Threading.Tasks;


public class UIClickCloseRightMenu: UIInteractBase{
    public UIClickCloseRightMenu(GameObject self): base(self){
        _set_trigger(0);
    }

    public override void _PointerDown(PointerEventData eventData){
        if (!_isAvailable(eventData)) return;
        close_rightMenu();
    }
    
    void close_rightMenu(){
        _Base._UISys._UIMonitor.rightMenu_currentOpen?._disable();
    }
}
