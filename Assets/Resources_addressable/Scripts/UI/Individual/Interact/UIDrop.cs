using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;
using System.Threading.Tasks;
using UnityEngine.EventSystems;
using Cysharp.Threading.Tasks;
using Unity.VisualScripting;


public class UIDrop: UIInteractBase{
    public UIDrop(GameObject self): base(self){}
    
    public override void _Drop(PointerEventData eventData){
        if (!_isAvailable(eventData)) return;
        drop(eventData);
    }

    bool allowDrop(PointerEventData eventData){
        GameObject item = eventData.pointerDrag;
        // ----- Should not drop again
        if (_self == item.transform.parent) return false;
        // ----- Should not drop self
        if (_self == item) return false;
        // ----- Item is not draggable
        bool itemAllowDrag = false;
        UIBase item_cfg = item.GetComponent<UIIndividual>()._Base;
        foreach (var interaction in item_cfg._InteractMgr._interactions){
            if (interaction.GetType().Name == "UIDrag") itemAllowDrag = true;
        }
        if (!itemAllowDrag) return false;
        // ----- All pass
        return true;
    }

    public virtual bool _allowDrop_custom(PointerEventData eventData){
        return true;
    }

    GameObject get_parent_ScrollView(){
        // Container -> Content -> Viewport -> ScrollView
        return _self.transform.parent.parent.parent.gameObject;
    }

    void drop(PointerEventData eventData){
        GameObject item = eventData.pointerDrag;
        if (!allowDrop(eventData)) return;
        if (!_allowDrop_custom(eventData)) return;
        // ----- Drop
        RectTransform item_rt = item.GetComponent<RectTransform>();
        UIBase item_base = item_rt.GetComponent<UIIndividual>()._Base;
        // ----- get container index
        int container_index_start = _Base._name.LastIndexOf(' ');
        string numberPart = _Base._name.Substring(container_index_start + 1);
        int container_index = int.Parse(numberPart) - 1;
        // ----- update as item
        item_base._info.item_index = container_index;
        item_base._set_parent(_self);
        resize_item_to_container(_Base, item_base);
        // ----- log to ScrollView.info
        if (get_parent_ScrollView().GetComponent<UIIndividual>()._Base is UIScrollView SV_base) {
            SV_base._add_item(item_base);
        }
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
