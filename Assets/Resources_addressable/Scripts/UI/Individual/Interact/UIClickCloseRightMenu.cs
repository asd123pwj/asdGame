// using UnityEngine;
// using UnityEngine.UI;
// using System.Collections.Generic;
// using System.Threading.Tasks;
// using UnityEngine.EventSystems;
// using Cysharp.Threading.Tasks;


// public class UIClickCloseRightMenu: UIInteractBase{
//     public UIClickCloseRightMenu(UIBase Base): base(Base){
//         _set_trigger(0);
//     }

//     public override void _PointerDown(BaseEventData eventData, bool isBuildIn=true){
//         if (!_isAvailable(eventData)) return;
//         close_rightMenu();
//     }
    
//     void close_rightMenu(){
//         _Base._UISys._UIMonitor.rightMenu_currentOpen?._disable();
//     }
// }
