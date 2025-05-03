// using UnityEngine;
// using System.Collections.Generic;


// public class UIContainer: UIBase{
//     public new List<string> essential_interactions = new() { nameof(UISetTop), nameof(UILogPointerOverUI), nameof(UIDrop) };
//     int container_index;

//     public UIContainer(GameObject parent, UIInfo info): base(parent, info){
//         // ----- get container index
//         int container_index_start = _info.name.LastIndexOf(' ');
//         string numberPart = _info.name[(container_index_start + 1)..];
//         container_index = int.Parse(numberPart) - 1;
//     }

//     public void drop_item(UIBase item){
//         // ----- update as item
//         item._info.item_index = container_index;
//         item._set_parent(_self);

//         item._info.isItem = true;

//         Vector2 newSize = _rt_self.rect.size * 0.8f;
//         Vector2 scale_new = newSize / item._rt_self.rect.size;
//         float maxScale = Mathf.Min(scale_new.x, scale_new.y);
//         item._rt_self.localScale = new Vector3(maxScale, maxScale, 1);
//         item._set_UIPos_MiddleMiddle();
//         item._apply_UIPosition();
//     }

// }
