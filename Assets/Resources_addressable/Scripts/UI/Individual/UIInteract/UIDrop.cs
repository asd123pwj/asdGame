using UnityEngine;
using UnityEngine.EventSystems;


public class UIDrop: UIInteractBase{
    int container_index;
    public UIDrop(UIBase Base): base(Base){
        get_container_index();
    }

    void get_container_index(){
        int container_index_start = _Base._info.name.LastIndexOf(' ');
        string numberPart = _Base._info.name[(container_index_start + 1)..];
        container_index = int.Parse(numberPart) - 1;
    }
    
    public override void _Drop(BaseEventData eventData, bool isBuildIn=true){
        if (!_isAvailable(eventData)) return;
        drop((PointerEventData)eventData);
    }

    bool allowDrop(PointerEventData eventData){
        GameObject item = eventData.pointerDrag;
        // ----- Should not drop again
        if (_self == item.transform.parent) return false;
        // ----- Should not drop self
        if (_self == item) return false;
        // ----- Item is not draggable
        bool itemAllowDrag = false;
        UIBase item_cfg = _Base._UISys._UIMonitor._UIObj2base[item];
        if (item_cfg._InteractMgr._interactions.ContainsKey("UIDrag")) { itemAllowDrag = true; }
        if (!itemAllowDrag) return false;
        // ----- All pass
        return true;
    }

    public virtual bool _allowDrop_custom(PointerEventData eventData){
        return true;
    }

    void drop(PointerEventData eventData){
        GameObject item = eventData.pointerDrag;
        if (!allowDrop(eventData)) return;
        if (!_allowDrop_custom(eventData)) return;
        UIBase item_base = _Base._UISys._UIMonitor._UIObj2base[item];
        drop(item_base);
    }

    public void drop(UIBase item_base){
        // // ----- update as item
        item_base._info.item_index = container_index;
        item_base._set_parent(_self);
        resize_item_to_container(_Base, item_base);
    }

    void resize_item_to_container(UIBase container_base, UIBase item_base){
        item_base._info.isItem = true;

        Vector2 newSize = container_base._rt_self.rect.size * 0.8f;
        Vector2 scale_new = newSize / item_base._rt_self.rect.size;
        float maxScale = Mathf.Min(scale_new.x, scale_new.y);
        item_base._rt_self.localScale = new Vector3(maxScale, maxScale, 1);
        item_base._set_UIPos_MiddleMiddle();
        item_base._apply_UIPosition();
    }
}
