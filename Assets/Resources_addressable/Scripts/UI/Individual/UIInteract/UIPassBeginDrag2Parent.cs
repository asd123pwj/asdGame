using UnityEngine.EventSystems;


public class UIPassBeginDrag2Parent: UIInteractBase{
    public UIPassBeginDrag2Parent(UIBase Base): base(Base){}

    public override void _BeginDrag(BaseEventData eventData, bool isBuildIn=true){
        if (!_isAvailable(eventData)) return;
        passBeginDrag2Parent((PointerEventData)eventData);
    }
    void passBeginDrag2Parent(PointerEventData eventData){
        ExecuteEvents.ExecuteHierarchy(
            _self.transform.parent.gameObject, 
            eventData,                 
            ExecuteEvents.beginDragHandler 
        );
    }
}
