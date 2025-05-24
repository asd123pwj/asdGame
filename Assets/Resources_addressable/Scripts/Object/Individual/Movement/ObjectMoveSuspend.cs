using UnityEngine;

public class ObjectMoveSuspend: ObjectMoveBase{
    public ObjectMoveSuspend(ObjectBase Base): base(Base){
    }

    protected override void _act_move(KeyPos input) { 
        Bounds bounds = _Base._collider.bounds;
        float bottomY = bounds.min.y;
        float hoverHeight = 0.02f;  // 固定一个非常小的值，比如2厘米
        Vector2 det_pos = new(_Base._self.transform.position.x, bottomY);
        RaycastHit2D hit = Physics2D.Raycast(_Base._self.transform.position, Vector2.down, hoverHeight, LayerMask.GetMask("Default"));
        if (hit.collider != null && hit.collider.gameObject != _Base._self.gameObject){
            Debug.Log(hit.collider.gameObject.name);
            // float targetY = hit.point.y + hoverHeight + (_Base._self.transform.position.y - bottomY); 
            Vector3 pos = _Base._self.transform.position + new Vector3(0, hoverHeight);
            // pos.y = targetY;
            _Base._self.transform.position = pos;
        }

    }
}