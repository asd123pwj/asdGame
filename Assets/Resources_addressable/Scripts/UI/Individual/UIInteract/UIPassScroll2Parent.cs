using UnityEngine.UI;
using UnityEngine.EventSystems;


public class UIPassScroll2Parent: UIInteractBase{
    ScrollRect scrollRect;
    public UIPassScroll2Parent(UIBase Base): base(Base){}

    public override void _Scroll(BaseEventData eventData, bool isBuildIn=true){
        if (!_isAvailable(eventData)) return;
        pass2Parent((PointerEventData)eventData);
    }
    
    void pass2Parent(PointerEventData eventData){
        if (scrollRect == null) scrollRect = _self.GetComponentInParent<ScrollRect>();
        if (scrollRect == null) return;
        scrollRect.OnScroll(eventData);
    }
}
