using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;


public class UIPassPointerDown2Parent: UIInteractBase{
    public UIPassPointerDown2Parent(UIBase Base): base(Base){}

    public override void _PointerDown(BaseEventData eventData, bool isBuildIn=true){
        if (!_isAvailable(eventData)) return;
        passPointerDown2Parent((PointerEventData)eventData);
    }
    void passPointerDown2Parent(PointerEventData eventData){
        ExecuteEvents.ExecuteHierarchy(
            _self.transform.parent.gameObject, 
            eventData,                 
            ExecuteEvents.pointerDownHandler 
        );
    }
}
