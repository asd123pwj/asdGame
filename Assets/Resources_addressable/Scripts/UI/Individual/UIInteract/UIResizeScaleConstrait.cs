using UnityEngine;
using UnityEngine.EventSystems;

public class UIResizeScaleConstrait : UIResizeScale {
    public UIResizeScaleConstrait(UIBase Base): base(Base){ }

    public override Vector2 _constrait_scale(PointerEventData eventData, Vector2 scale){
        float scale_max = Mathf.Max(scale.x, scale.y);
        Vector2 scale_final = new(scale_max, scale_max);
        return scale_final;
    }
}