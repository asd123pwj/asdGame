// using UnityEngine;
// using UnityEngine.UI;
// using System.Collections.Generic;
// using System.Threading.Tasks;
// using UnityEngine.EventSystems;
// using Cysharp.Threading.Tasks;


// public class UIDeselectClose: UIInteractBase{
//     public UIDeselectClose(UIBase Base): base(Base){}

//     // public override void _register_interaction(){
//     //     _Cfg._Event._event_Deselect.Add(interaction_Deselect);
//     // }
    
//     public override void _Deselect(BaseEventData eventData, bool isBuildIn=true){
//         if (!_isAvailable(eventData)) return;
//         close((PointerEventData)eventData);
//     }
    
//     void close(PointerEventData eventData){
//         _Base._self.SetActive(false);
//     }



// }
