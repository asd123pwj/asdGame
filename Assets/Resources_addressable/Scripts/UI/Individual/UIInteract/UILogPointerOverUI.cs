using UnityEngine.EventSystems;


public class UILogPointerOverUI: UIInteractBase{
    public UILogPointerOverUI(UIBase Base): base(Base){}

    public override void _PointerEnter(BaseEventData eventData, bool isBuildIn=true){
        if (!_isAvailable(eventData)) return;
        pointerEnter((PointerEventData)eventData);
    }

    public override void _PointerExit(BaseEventData eventData, bool isBuildIn=true){
        if (!_isAvailable(eventData)) return;
        pointerExit((PointerEventData)eventData);
    }
    
    void pointerEnter(PointerEventData eventData){
        _Base._UISys._UIMonitor.ui_currentPointerEnter = _Base;
    }

    void pointerExit(PointerEventData eventData){
        if (_Base._UISys._UIMonitor.ui_currentPointerEnter == _Base){
            _Base._UISys._UIMonitor.ui_currentPointerEnter = null;
        }
    }
}
