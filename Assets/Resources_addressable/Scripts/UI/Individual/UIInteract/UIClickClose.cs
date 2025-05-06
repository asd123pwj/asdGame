using UnityEngine.EventSystems;


public class UIClickClose: UIInteractBase{
    public UIClickClose(UIBase Base): base(Base){
        _set_trigger(0);
    }

    public override void _PointerDown(BaseEventData eventData, bool isBuildIn=true){
        if (!_isAvailable(eventData)) return;
        close((PointerEventData)eventData);
    }
    
    void close(PointerEventData eventData){
        _Base._parent.SetActive(false);
    }



}
