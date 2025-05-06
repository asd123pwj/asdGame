using UnityEngine.EventSystems;


public class UIPassDrag2Parent: UIInteractBase{
    public UIPassDrag2Parent(UIBase Base): base(Base){}
    
    public override void _Drag(BaseEventData eventData, bool isBuildIn=true){
        if (!_isAvailable(eventData)) return;
        passDrag2Parent((PointerEventData)eventData);
    }

    void passDrag2Parent(PointerEventData eventData){
        ExecuteEvents.ExecuteHierarchy(
            _self.transform.parent.gameObject, 
            eventData,                 
            ExecuteEvents.dragHandler 
        );
    }
}
