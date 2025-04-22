using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;


public class UIPassEndDrag2Parent: UIInteractBase{
    public UIPassEndDrag2Parent(UIBase Base): base(Base){}

    public override void _EndDrag(BaseEventData eventData, bool isBuildIn=true){
        if (!_isAvailable(eventData)) return;
        passEndDrag2Parent((PointerEventData)eventData);
    }

    void passEndDrag2Parent(PointerEventData eventData){
        ExecuteEvents.ExecuteHierarchy(
            _self.transform.parent.gameObject, 
            eventData,                 
            ExecuteEvents.endDragHandler 
        );
    }
}
